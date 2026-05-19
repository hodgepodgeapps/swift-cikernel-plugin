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

        return try FileManager.default.subpathsOfDirectory(atPath: target.directoryURL.path()).filter {
            $0.hasSuffix("Filter.metal")
        }.map { source in
            let sourceURL = target.directoryURL.appending(path: source)
            let stem = sourceURL.deletingPathExtension().lastPathComponent
            let output = context.pluginWorkDirectoryURL.appending(path: "\(stem)Data.swift")
            let compiledMacOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-macosx.air")
            let linkedMacOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-macosx.metallib")

            return .buildCommand(displayName: "Build CI Kernel \(stem)", executable: executable, arguments: [
                sourceURL.path(),
                context.pluginWorkDirectoryURL.path()
            ], environment: [:], inputFiles: [
                sourceURL
            ], outputFiles: [
                output,
                compiledMacOS,
                linkedMacOS
            ])
        }
    }
}
