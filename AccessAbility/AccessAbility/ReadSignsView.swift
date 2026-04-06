//
//  ReadSignsView.swift
//  AccessAbility
//
//  Created by Assistant on 4/6/26.
//

import SwiftUI

struct ReadSignsView: View {
    @State private var showCamera = false
    @State private var isLoading = false
    @State private var resultText: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Read Signs")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)

                if isLoading {
                    ProgressView().tint(.white)
                        .scaleEffect(1.5)
                        .accessibilityLabel("Processing")
                }

                if !resultText.isEmpty {
                    Text(resultText)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .accessibilityLabel(resultText)
                } else {
                    Text("Double tap to scan for signs like stop, slippery surface, or ramp ahead.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()

                Button {
                    showCamera = true
                } label: {
                    Text("Scan Sign")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.black)
                        .cornerRadius(16)
                        .accessibilityLabel("Scan Sign")
                        .accessibilityHint("Opens camera")
                }
            }
            .padding()
        }
        .onAppear {
            SpeechManager.shared.speak("Read Signs. Double tap to scan.", interrupt: true)
        }
        .onTapGesture(count: 2) {
            showCamera = true
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(isPresented: $showCamera) { image in
                Task { await process(image: image) }
            }
            .ignoresSafeArea()
        }
        .toolbarTitleDisplayMode(.inline)
    }

    private func process(image: UIImage) async {
        isLoading = true
        resultText = ""
        do {
            // Reuse GoogleVisionService with TEXT_DETECTION specifically for traffic/notice signs.
            let text = try await SignDetectionService.detectSign(in: image)
            await MainActor.run {
                resultText = text
                SpeechManager.shared.speak(text, interrupt: true)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                resultText = error.localizedDescription
                SpeechManager.shared.speak("Error: \(error.localizedDescription)", interrupt: true)
                isLoading = false
            }
        }
    }
}

#Preview { ReadSignsView() }
