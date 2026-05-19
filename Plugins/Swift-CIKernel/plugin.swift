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
        let activeSDK = resolveActiveSDK()

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
            let compiledIOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-iphoneos.air")
            let linkedIOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-iphoneos.metallib")
            let compiledTVOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-tvos.air")
            let linkedTVOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-tvos.metallib")
            let compiledVisionOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-visionos.air")
            let linkedVisionOS = context.pluginWorkDirectoryURL.appending(path: "\(stem)-visionos.metallib")

            return .buildCommand(displayName: "Build CI Kernel \(stem)", executable: executable, arguments: [
                sourceURL.path(),
                context.pluginWorkDirectoryURL.path()
            ], environment: [
                "SWIFT_CIKERNEL_ACTIVE_SDK": activeSDK
            ], inputFiles: [
                sourceURL
            ], outputFiles: [
                output,
                compiledMacOS,
                linkedMacOS,
                compiledIOS,
                linkedIOS,
                compiledTVOS,
                linkedTVOS,
                compiledVisionOS,
                linkedVisionOS
            ])
        }
    }

    private func resolveActiveSDK() -> String {
        let environment = ProcessInfo.processInfo.environment

        if let sdkName = environment["SDK_NAME"] {
            let normalized = normalizedSDK(from: sdkName)
            if normalized != "all" { return normalized }
        }

        if let sdkRoot = environment["SDKROOT"] {
            let normalized = normalizedSDK(from: sdkRoot)
            if normalized != "all" { return normalized }
        }

        return "all"
    }

    private func normalizedSDK(from rawValue: String) -> String {
        let value = rawValue.lowercased()
        if value.contains("macosx") { return "macosx" }
        if value.contains("iphoneos") { return "iphoneos" }
        if value.contains("appletvos") { return "appletvos" }
        if value.contains("xros") || value.contains("visionos") { return "xros" }
        return "all"
    }
}
