//
//  main.swift
//  SwiftGenie
//
//  Created by Emil Karimov on 13.03.2025.
//  Copyright © 2025 Emil Karimov. All rights reserved.
//

import ArgumentParser
import Foundation
import Yams

struct SwiftGenie: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "SwiftGenie - A CLI tool for generating Swift code based on templates.",
        subcommands: [Generate.self, InstallTemplates.self]
    )
}

struct Config: Codable {
    let company: String
    let projectName: String
    let xcodeprojPath: String
    let projectTarget: String
    let projectFilePath: String
    let projectGroupPath: String
    let testTarget: String
    let testFilePath: String
    let testGroupPath: String
    let catalogs: [String]
    let templates: [[String: String]]

    enum CodingKeys: String, CodingKey {
        case company
        case projectName = "project_name"
        case xcodeprojPath = "xcodeproj_path"
        case projectTarget = "project_target"
        case projectFilePath = "project_file_path"
        case projectGroupPath = "project_group_path"
        case testTarget = "test_target"
        case testFilePath = "test_file_path"
        case testGroupPath = "test_group_path"
        case catalogs
        case templates
    }

    static func load() throws -> Config {
        let path = FileManager.default.currentDirectoryPath + "/SwiftGenie.yml"
        let content = try String(contentsOfFile: path, encoding: .utf8)

        do {
            return try YAMLDecoder().decode(Config.self, from: content)
        } catch let DecodingError.keyNotFound(key, context) {
            throw ValidationError("Missing key '\(key.stringValue)' in SwiftGenie.yml. \(context.debugDescription)")
        } catch {
            throw ValidationError("Failed to load SwiftGenie.yml: \(error.localizedDescription)")
        }
    }
}

struct Generate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gen",
        abstract: "Generates a module from a template."
    )

    @Argument(help: "The name of the module to generate.")
    var moduleName: String

    func run() throws {
        let fileManager = FileManager.default
        let config = try Config.load()

        let templatePath = FileManager.default.currentDirectoryPath + "/Templates"
        let destinationPath = FileManager.default.currentDirectoryPath + "/\(config.projectFilePath)/\(moduleName)"

        // Check if the template directory exists
        guard fileManager.fileExists(atPath: templatePath) else {
            throw ValidationError("Templates directory not found. Run `SwiftGenie install templates` first.")
        }

        // Create a directory for the new module
        try fileManager.createDirectory(atPath: destinationPath, withIntermediateDirectories: true)

        // Copy and process template files
        let templateFiles = try fileManager.contentsOfDirectory(atPath: templatePath)

        for file in templateFiles {
            let templateFilePath = "\(templatePath)/\(file)"
            let destinationFilePath = "\(destinationPath)/\(file.replacingOccurrences(of: "Template", with: moduleName))"

            let content = try String(contentsOfFile: templateFilePath, encoding: .utf8)
            var processedContent = content.replacingOccurrences(of: "{{moduleName}}", with: moduleName)
            processedContent = processedContent.replacingOccurrences(of: "{{company}}", with: config.company)

            try processedContent.write(toFile: destinationFilePath, atomically: true, encoding: .utf8)
        }

        print("Module \(moduleName) successfully created in \(destinationPath)")
    }
}

struct InstallTemplates: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install-templates",
        abstract: "Installs templates from the repository specified in SwiftGenie.yml."
    )

    func run() throws {
        let fileManager = FileManager.default
        let config = try Config.load()
        let templatesPath = FileManager.default.currentDirectoryPath + "/Templates"

        // Create Templates directory if it does not exist
        if !fileManager.fileExists(atPath: templatesPath) {
            try fileManager.createDirectory(atPath: templatesPath, withIntermediateDirectories: true)
        }

        for catalog in config.catalogs {
            print("Cloning templates from \(catalog)...")
            let cloneCommand = "git clone \(catalog) \(templatesPath)/tempRepo"
            _ = try shell(command: cloneCommand)

            for template in config.templates {
                if let templateName = template["name"] {
                    let templateSourcePath = "\(templatesPath)/tempRepo/\(templateName)"
                    let templateDestinationPath = "\(templatesPath)/\(templateName)"

                    if fileManager.fileExists(atPath: templateSourcePath) {
                        try fileManager.copyItem(atPath: templateSourcePath, toPath: templateDestinationPath)
                        print("Installed template: \(templateName)")
                    } else {
                        print("Template \(templateName) not found in repository.")
                    }
                }
            }

            // Clean up temporary repository
            try fileManager.removeItem(atPath: "\(templatesPath)/tempRepo")
        }

        print("Templates installed successfully.")
    }

    func shell(command: String) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", command]
        process.launchPath = "/bin/zsh"
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return String(decoding: data, as: UTF8.self)
    }
}

SwiftGenie.main()
