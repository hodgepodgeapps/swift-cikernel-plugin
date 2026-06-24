//
//  plugin.swift
//  Swift-CIKernel
//
//  Created by Michal Tomlein on 13/06/2022.
//

import Foundation
import PackagePlugin

@main
struct BuildCIKernel: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let executable = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Scripts/buildci.sh")

        let targetDir = target.directoryURL.path()

        let allMetalSources = try FileManager.default.subpathsOfDirectory(atPath: targetDir)
            .filter { $0.hasSuffix(".metal") }
        let entryFiles = allMetalSources.filter { $0.hasSuffix("Filter.metal") }
        let sharedSources = allMetalSources
            .filter { !$0.hasSuffix("Filter.metal") }
        let sharedInputs = sharedSources.map { target.directoryURL.appending(path: $0) }

        return entryFiles.map { source in
            let sourceURL = target.directoryURL.appending(path: source)
            let stem = sourceURL.deletingPathExtension().lastPathComponent
            let output = context.pluginWorkDirectoryURL.appending(path: "\(stem)Data.swift")
            let compiledMacOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-macosx.air")
            let linkedMacOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-macosx.metallib")

            let isSwiftUI = stem.hasSuffix("SwiftUIFilter")
            let displayName = isSwiftUI ? "Build SwiftUI Shader \(stem)" : "Build CI Kernel \(stem)"

            return .buildCommand(displayName: displayName, executable: executable, arguments: [
                sourceURL.path(),
                context.pluginWorkDirectoryURL.path()
            ], environment: [:], inputFiles: [
                sourceURL
            ] + sharedInputs, outputFiles: [
                output,
                compiledMacOS,
                linkedMacOS
            ])
        }
    }
}
