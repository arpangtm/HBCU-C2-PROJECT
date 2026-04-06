//
//  IdentifyObjectView.swift
//  AccessAbility
//
//  Created by Assistant on 4/6/26.
//

import SwiftUI

struct IdentifyObjectView: View {
    @State private var showCamera = false
    @State private var isLoading = false
    @State private var resultText: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Identify Object")
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
                    Text("Double tap the screen to take a photo and identify objects.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()

                Button {
                    showCamera = true
                } label: {
                    Text("Take Photo")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.black)
                        .cornerRadius(16)
                        .accessibilityLabel("Take Photo")
                        .accessibilityHint("Opens camera")
                }
            }
            .padding()
        }
        .onAppear {
            SpeechManager.shared.speak("Identify Object. Double tap to take a photo.", interrupt: true)
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
            let text = try await GoogleVisionService.classify(image: image)
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

#Preview { IdentifyObjectView() }
