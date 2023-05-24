#!/usr/bin/env xcrun swift

import Foundation

let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath
let projectUrls = URL(fileURLWithPath: currentPath).appendingPathComponent("projectUrls.txt")
let localizationsUrl = URL(fileURLWithPath: currentPath).appendingPathComponent("localizableUrl.txt")
let affirmationType = ["yes", "true"]
let excludePaths = ["Pods"]

if CommandLine.arguments.contains("search_strings") {
    do {
        let localizationUrlStr = try String(contentsOf: localizationsUrl).replacingOccurrences(of: " ", with: "")
        var arguments: [String] = []
        arguments.append(localizationUrlStr)
        arguments.append("-name")
        arguments.append("*Localizable.strings")
        
        if let pathFromUrl = readFromFile(arguments: arguments).first {
            print(pathFromUrl)
            let localizations = searchStrings(stringsFileUrl: pathFromUrl)
            print("do you want to delete unused localizations?")
            let delete = readLine(strippingNewline: true)
            if let delete = delete, affirmationType.contains(delete.lowercased()) {
                deleteLocalizations(localizations: localizations, localizationUrl: localizationUrlStr)
                runSwiftGen()
            }
        }
    } catch {
        print("Invalid url")
    }
}


func searchStrings(stringsFileUrl: String) -> [String] {
    var stringsData: [String] = []
    var contents: String = ""
    do {
        contents = try String(contentsOf: projectUrls)
    }
    catch {
        print("URL is not valid")
    }
    let projectPaths = contents.components(separatedBy: .newlines)
    if projectPaths.isEmpty {
        print("Please add project urls in the urls.txt file")
        exit(1)
    }
    let localizationStrArr = localizationFilConverter(url: stringsFileUrl)
    
    var arguments: [String] = []
    for path in projectPaths {
        arguments.append(path)
    }
    arguments.append("-name")
    arguments.append("*.swift")
    
    let pathFromUrls = readFromFile(arguments: arguments)
    
    let pathStrings = pathFromUrls
        .filter {!$0.splitArray(with: "/").contains("Strings.swift")}
        .filter({ path in
            excludePaths.allSatisfy { exclude in
                !path.contains(exclude)
            }
        })
    
    for (index, loclization) in localizationStrArr.enumerated() {
        updateProgress(totalFiles: localizationStrArr.count, currentCount: index, unusedKeys: stringsData.count)
        var localizationExists: Bool = false
        var usableLocalization = loclization
        if usableLocalization.contains("_") {
            usableLocalization = usableLocalization.replacingOccurrences(of: "_", with: "")
        }
        for path in pathStrings {
            let contentFile = path.getFileString()
            if contentFile.contains(usableLocalization) {
                localizationExists = true
                break
            }
        }
        if !localizationExists && !String(loclization).isEmpty {
            stringsData.append(loclization)
        }
    }
    return stringsData
}

private func runSwiftGen() {
    var contents: String = ""
    do {
        contents = try String(contentsOf: projectUrls)
    }
    catch {
        print("URL is not valid")
    }
    let projectPaths = contents.components(separatedBy: .newlines)
    if projectPaths.isEmpty {
        print("Please add project urls in the urls.txt file")
        exit(1)
    }
    var arguments: [String] = []
    for path in projectPaths {
        let swiftGenPath = "\(path)/swiftgen.yml"
        if fileManager.fileExists(atPath: swiftGenPath) {
            let task = Process()
            task.launchPath = "/usr/bin/env"
            task.arguments = ["swiftgen", "config", "run", "--config", swiftGenPath]
            task.currentDirectoryPath = path
            task.launch()
            task.waitUntilExit()
        }
    }
}

private func deleteLocalizations(localizations: [String], localizationUrl: String) {
    var arguments: [String] = []
    arguments.append(localizationUrl)
    arguments.append("-name")
    arguments.append("*.strings")
    
    let pathFromUrls = readFromFile(arguments: arguments)
    let pathStrings = pathFromUrls
    for path in pathStrings {
        let content = path.getFileString()
        var splited = content.splitArray(with: ";")
        for locStr in localizations {
            guard let index = splited.firstIndex(where: { $0.contains(locStr)}) else { continue }
            splited.remove(at: index)
        }
        splited = splited.filter{ !$0.isEmpty }
        let joinedStr = splited.joined(separator: ";")
        do {
            let emptyString = ""
            try emptyString.write(toFile: path, atomically: true, encoding: .utf8)
            try joinedStr.write(toFile: path, atomically: true, encoding: .utf8)
        }
        catch {
            print("Write to file failed")
        }
    }
    runSwiftGen()
}

private func readFromFile(arguments: [String]) -> [String] {
    let process = Process()
    process.launchPath = "/usr/bin/find"
    process.arguments = arguments
    
    let pipe = Pipe()
    process.standardOutput = pipe
    let fileHandle = pipe.fileHandleForReading
    
    process.launch()
    
    let data = fileHandle.readDataToEndOfFile()
    let string = String(data: data, encoding: .utf8)
    let pathStrings = string?
        .split(separator: "\n")
        .map{ String($0) } ?? []
    process.waitUntilExit()
    return pathStrings
}

private func localizationFilConverter(url : String) -> [String] {
    let localizationFileString = url.getFileString()
    let localizationStrArr = localizationFileString
        .split(separator: ";").map { String($0) }
        .map { str in
            if let r1 = str.range(of: "\""),
               let r2 = str.range(of: "\" =", range: r1.upperBound..<str.endIndex) {
                
                let stringBetweenQuotes = String(str[r1.upperBound..<r2.lowerBound])
                return stringBetweenQuotes
            }
            return ""
        }
        .filter { !$0.isEmpty }
    return localizationStrArr
}

private func updateProgress(totalFiles: Int, currentCount: Int, unusedKeys: Int) {
    let progress = Double(currentCount) / Double(totalFiles)
    let progressString = String(format: "%.0f%%", progress * 100)
    let output = "Found \(unusedKeys) unused localization keys - Progess \(progressString)"
    print(output)
    fflush(stdout)
}

extension String {
    func getFileString() -> String {
        do {
            let contentString = try String(contentsOfFile: self)
            return contentString
        }
        catch {
            print("File not found")
        }
        return ""
    }
    
    func splitArray(with string: String) -> [String] {
        self.components(separatedBy: string)
    }
}
