//
//  ContentView.swift
//  Mac Saver Builder
//
//  Created by Hüseyin Usta
//  Copyright © 2024 GetInfo. Licensed under MIT License.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import AVKit

struct ContentView: View {
    @State private var videoURL: URL?
    @State private var thumbnailURL: URL?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 28) {
            HStack(spacing: 20) {
                DropArea(
                    title: "Select Video",
                    subtitle: "Drag and drop video file or click\n(.mp4 or .mov)",
                    selectedURL: $videoURL,
                    allowedTypes: ["mp4", "mov"]
                )
                .frame(width: 233, height: 150)
                
                DropArea(
                    title: "Select Thumbnail",
                    subtitle: "Drag and drop image file or click\n(.png or .jpg)",
                    selectedURL: $thumbnailURL,
                    allowedTypes: ["png", "jpg", "jpeg"]
                )
                .frame(width: 233, height: 150)
            }
            
            Button("Save .saver") {
                exportSaverFile()
            }
            .disabled(videoURL == nil || thumbnailURL == nil)
            .buttonStyle(.borderedProminent)
            .tint(videoURL != nil && thumbnailURL != nil ? .accentColor : .gray)
            .animation(.easeInOut, value: videoURL != nil && thumbnailURL != nil)
        }
        .padding(24)
        .background {
            if #available(macOS 15.0, *) {
                // macOS 26+ Liquid Glass effect
                Rectangle()
                    .fill(.ultraThinMaterial)
            } else {
                // macOS 14 fallback - transparent (system handles background)
                Color.clear
            }
        }
        .alert("Mac Saver Builder", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportSaverFile() {
        guard let videoURL = videoURL,
              let thumbnailURL = thumbnailURL else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "saver")!]
        panel.nameFieldStringValue = "MyScreenSaver.saver"
        
        if panel.runModal() == .OK {
            guard let saveURL = panel.url else { return }
            
            do {
                let fileManager = FileManager.default
                
                if let saverTemplate = Bundle.main.url(forResource: "ScreenSaverViewer", withExtension: "saver") {
                    try fileManager.copyItem(at: saverTemplate, to: saveURL)
                    
                    let resourcesPath = saveURL.appendingPathComponent("Contents/Resources")
                    try fileManager.createDirectory(at: resourcesPath, withIntermediateDirectories: true)
                    
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let uniqueVideoName = "video_\(timestamp).mp4"
                    
                    try fileManager.copyItem(at: videoURL, to: resourcesPath.appendingPathComponent(uniqueVideoName))
                    if let pngURL = convertToPNG(from: thumbnailURL) {
                        try fileManager.copyItem(at: pngURL, to: resourcesPath.appendingPathComponent("thumbnail.png"))
                    }
                    
                    let infoPlistURL = saveURL.appendingPathComponent("Contents/Info.plist")
                    if var infoPlist = NSDictionary(contentsOf: infoPlistURL) as? [String: Any] {
                        let executableName = "ScreenSaverViewer_\(timestamp)"
                        let saverName = panel.nameFieldStringValue.replacingOccurrences(of: ".saver", with: "")
                        
                        infoPlist["CFBundleExecutable"] = executableName
                        infoPlist["NSPrincipalClass"] = executableName
                        infoPlist["CFBundleIdentifier"] = "com.GetInfo.MacSaverBuilder.Viewer.\(timestamp)"
                        infoPlist["CFBundleName"] = saverName
                        
                        try (infoPlist as NSDictionary).write(to: infoPlistURL)
                    }
                    
                    let macOSPath = saveURL.appendingPathComponent("Contents/MacOS")
                    let originalExecutableURL = macOSPath.appendingPathComponent("ScreenSaverViewer")
                    let newExecutableURL = macOSPath.appendingPathComponent("ScreenSaverViewer_\(timestamp)")
                    try fileManager.moveItem(at: originalExecutableURL, to: newExecutableURL)
                    
                    do {
                        let dirChmodTask = Process()
                        dirChmodTask.executableURL = URL(fileURLWithPath: "/bin/chmod")
                        dirChmodTask.arguments = ["755", saveURL.path]
                        try dirChmodTask.run()
                        dirChmodTask.waitUntilExit()
                        
                        let resourcesPath = saveURL.appendingPathComponent("Contents/Resources")
                        let filesChmodTask = Process()
                        filesChmodTask.executableURL = URL(fileURLWithPath: "/bin/chmod")
                        filesChmodTask.arguments = ["644", resourcesPath.appendingPathComponent("video_\(timestamp).mp4").path,
                                                  resourcesPath.appendingPathComponent("thumbnail.png").path]
                        try filesChmodTask.run()
                        filesChmodTask.waitUntilExit()
                    } catch {
                        print("Permission setting failed: \(error.localizedDescription)")
                    }
                    
                    stripAndAdHocSignSaver(at: saveURL)
                    
                    alertMessage = """
Screen saver created successfully!

Location: \(saveURL.path)
"""
                }
            } catch {
                alertMessage = "Save failed: \(error.localizedDescription)"
            }
            showAlert = true
        }
    }
    
    private func convertToPNG(from imageURL: URL) -> URL? {
        if let image = NSImage(contentsOf: imageURL) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("thumbnail_temp.png")
            
            if let tiffData = image.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                try? pngData.write(to: tempURL)
                return tempURL
            }
        }
        return nil
    }
    
    /// Remove any (broken) signature, then ad-hoc re-sign so the .saver runs without
    /// "invalid Info.plist" / "damaged" / Gatekeeper block. Matches user-reported fix.
    private func stripAndAdHocSignSaver(at saverURL: URL) {
        let macOSPath = saverURL.appendingPathComponent("Contents/MacOS")
        let fileManager = FileManager.default
        let codesign = "/usr/bin/codesign"
        
        // 1) Remove existing (broken) signatures
        if let executables = try? fileManager.contentsOfDirectory(at: macOSPath, includingPropertiesForKeys: nil) {
            for execURL in executables {
                runCodesign(codesign, ["--remove-signature", execURL.path])
            }
        }
        runCodesign(codesign, ["--remove-signature", saverURL.path])
        
        // 2) Ad-hoc re-sign (executables first, then bundle)
        if let executables = try? fileManager.contentsOfDirectory(at: macOSPath, includingPropertiesForKeys: nil) {
            for execURL in executables {
                runCodesign(codesign, ["--force", "--sign", "-", execURL.path])
            }
        }
        runCodesign(codesign, ["--force", "--deep", "--sign", "-", saverURL.path])
    }
    
    private func runCodesign(_ path: String, _ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        try? p.run()
        p.waitUntilExit()
    }
}

struct DropArea: View {
    let title: String
    let subtitle: String
    @Binding var selectedURL: URL?
    let allowedTypes: [String]
    @State private var isTargeted = false
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
                .background {
                    if #available(macOS 15.0, *) {
                        // macOS 26+ Material effect overlay
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.thinMaterial)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: isTargeted ? [10, 5] : [],
                                dashPhase: 0
                            )
                        )
                        .foregroundColor(isTargeted ? .primary.opacity(0.8) : .secondary.opacity(0.5))
                )
                .overlay(
                    Group {
                        if let url = selectedURL {
                            if allowedTypes.contains("png") {
                                Image(nsImage: NSImage(contentsOf: url) ?? NSImage())
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(10)
                            } else {
                                VideoThumbnailView(videoURL: url)
                                    .padding(10)
                            }
                        } else {
                            VStack {
                                Text(title)
                                    .font(.headline)
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                )
        }
        .onTapGesture {
            selectFile()
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers -> Bool in
            guard let provider = providers.first else { return false }
            
            let _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url,
                      allowedTypes.contains(url.pathExtension.lowercased()) else { return }
                
                DispatchQueue.main.async {
                    self.selectedURL = url
                }
            }
            return true
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedTypes.map { UTType(filenameExtension: $0)! }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedURL = url
            }
        }
    }
}

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoView(player: player)
            .onAppear {
                player = AVPlayer(url: videoURL)
                player?.isMuted = true
                player?.play()
                
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player?.currentItem,
                    queue: .main) { _ in
                        player?.seek(to: .zero)
                        player?.play()
                    }
            }
            .onDisappear {
                player?.pause()
            }
            .onChange(of: videoURL) { oldValue, newValue in
                player = AVPlayer(url: newValue)
                player?.isMuted = true
                player?.play()
            }
    }
}

struct VideoView: NSViewRepresentable {
    let player: AVPlayer?
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.showsFullScreenToggleButton = false
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}

#Preview {
    ContentView()
        .frame(width: 540, height: 254)
}
