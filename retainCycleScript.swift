#!/usr/bin/env swift

import Foundation

let projectPath = "/path/to/project"
let searchPattern = #"(\bself\.[^\s]+)\s*=\s*(\w+)"#
let excludePaths = ["Pods"]

func findRetainCycles(inFile file: URL) -> [String] {
    do {
        let contents = try String(contentsOf: file)
        let regex = try NSRegularExpression(pattern: searchPattern, options: [])
        let range = NSRange(location: 0, length: contents.utf16.count)
        let matches = regex.matches(in: contents, options: [], range: range)
        return matches.compactMap { match in
            let selfRange = match.range(at: 1)
            let variableRange = match.range(at: 2)
            let selfString = (contents as NSString).substring(with: selfRange)
            let variableString = (contents as NSString).substring(with: variableRange)
            if !variableString.contains("weak") && !variableString.contains("unowned") {
                return "\(file.path):\(match.range.location): Possible retain cycle with '\(selfString)' and '\(variableString)'"
            }
            return nil
        }
    } catch {
        print("Error reading file: \(error)")
        return []
    }
}

func searchFiles(inDirectory directory: URL) -> [String] {
    var results: [String] = []
    do {
        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
        for file in contents {
            if excludePaths.contains(file.lastPathComponent) {
                continue
            }
            if file.pathExtension == "swift" {
                results.append(contentsOf: findRetainCycles(inFile: file))
            } else if file.hasDirectoryPath {
                results.append(contentsOf: searchFiles(inDirectory: file))
            }
        }
    } catch {
        print("Error searching directory: \(error)")
    }
    return results
}

let projectURL = URL(fileURLWithPath: projectPath)
let results = searchFiles(inDirectory: projectURL)
if results.isEmpty {
    print("No retain cycles found.")
} else {
    print("Potential retain cycles found:")
    for result in results {
        print(result)
    }
}

