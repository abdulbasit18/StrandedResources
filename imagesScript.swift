#!/usr/bin/env xcrun swift
import Foundation

let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath
let projectUrls = URL(fileURLWithPath: currentPath).appendingPathComponent("projectUrls.txt")
let assetsUrl = URL(fileURLWithPath: currentPath).appendingPathComponent("assetsUrl.txt")
let affirmationType = ["yes", "true"]
let excludePaths = ["Pods"]

if CommandLine.arguments.contains("search_images") {
    do {
        let imagesUrlStr = try String(contentsOf: assetsUrl).replacingOccurrences(of: " ", with: "")
        var arguments: [String] = []
        arguments.append(imagesUrlStr)
        arguments.append("-name")
        arguments.append("*Images.swift")

        if let pathFromUrl = readFromFile(arguments: arguments).first {
            let unuseImages = searchImages(imagesURl: pathFromUrl, imagesUrlStr: imagesUrlStr)
            print("do you want to delete unused Images?")
            let delete = readLine(strippingNewline: true)
            if let delete = delete, affirmationType.contains(delete.lowercased()) {
                deleteImages(unusedImages: unuseImages, imageUrl: imagesUrlStr)
                runSwiftGen()
            }
        }
    } catch {
        print("Invalid url")
    }
}

private func searchImages(imagesURl: String, imagesUrlStr: String) -> [String]{
    var strData: [String] = []
    var strandedImagesCount: Int = 0
    let imagesArr = imagesURl.getFileString().splitArray(with: "\n").filter { $0.contains("public static let")}
    let sortedArr = imagesArr.map { str in
        if let range = str.range(of: "\"([^\"]*)\"", options: .regularExpression) {
            let textWithinQuotes = String(str[range].dropFirst().dropLast())
            return textWithinQuotes
        }
        return ""
    }
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
        arguments.append(path)
    }
    arguments.append("-name")
    arguments.append("*.swift")

    let pathFromUrls = readFromFile(arguments: arguments)

    let pathStrings = pathFromUrls
        .filter{ !(URL(string: $0)?.lastPathComponent.contains("Images") ?? false) }
        .filter({ path in
            excludePaths.allSatisfy { exclude in
                !path.contains(exclude)
            }
        })
        
    for (index,image) in sortedArr.enumerated() {
        updateProgress(totalFiles: sortedArr.count, currentCount: index, unusedKeys: strandedImagesCount)
        var imageExits: Bool = false
        for path in pathStrings {
            let content = path.getFileString()
            if content.contains(image) {
                imageExits = true
            }
        }

        if !imageExits {
            strData.append(image)
            strandedImagesCount = strData.count
        }
    }
    print("unsused images are : \(strData)")
    return strData
}

private func deleteImages(unusedImages: [String], imageUrl: String) {
    var arguments: [String] = []
    arguments.append(imageUrl)
    arguments.append("-name")
    arguments.append("*.imageset")

    let pathStrings = readFromFile(arguments: arguments)
    let sorteData = unusedImages.map { $0.replacingOccurrences(of: "Images.", with: "") }
    for path in pathStrings {
        let url = URL(fileURLWithPath: path)
        let lastCComponent = url.lastPathComponent.replacingOccurrences(of: ".imageset", with: "")
        if sorteData.contains(lastCComponent) {
            print("image removed \(String(describing: lastCComponent))")
            do {
                if fileManager.fileExists(atPath: path) {
                    try fileManager.removeItem(atPath: path)
                }
                else {
                    print("File does not exits")
                }
            }
            catch {
                print("unable to delete the file \(String(describing: lastCComponent))")
            }
        }
    }
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

private func readFromFile(arguments: [String]) -> [String] {
    print("read from file started")
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

private func imagesFilConverter(url : String) -> [String] {
    let imagesFileString = url.getFileString()
    let imagesStrArr = imagesFileString
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
    return imagesStrArr
}

private func updateProgress(totalFiles: Int, currentCount: Int, unusedKeys: Int) {
    let progress = Double(currentCount) / Double(totalFiles)
    let progressString = String(format: "%.0f%%", progress * 100)
    let output = "Found \(unusedKeys) unused Iamges - Progess \(progressString)"
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
