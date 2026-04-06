import SwiftUI

struct ADAReportView: View {
    @State private var report: ADAComplianceReport?
    @State private var reportPulse = false

    var body: some View {
        CameraCaptureScreen(
            title: "Report ADA Issue",
            prompt: "Point the camera at an obstacle, unexpected curb, blocked ramp, or other accessibility barrier, then press capture to prepare a report.",
            guidanceNote: "A submitted report includes the photo and a fixed campus coordinate for university review.",
            introSpeech: "Report ADA Issue. Point the camera at the accessibility barrier and press capture to prepare a university report.",
            mode: .adaCompliance,
            resultAccessory: { _, hasPhoto in
                AnyView(reportCard(report: report, hasPhoto: hasPhoto))
            },
            onResult: { result, hasPhoto in
                withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                    report = ADAComplianceReport(summary: result.spokenMessage, hasPhoto: hasPhoto)
                    reportPulse = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        reportPulse = false
                    }
                }
            }
        )
        .accessibilityIdentifier("adaReport.screen")
    }

    @ViewBuilder
    private func reportCard(report: ADAComplianceReport?, hasPhoto: Bool) -> some View {
        if let report {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.16))
                            .frame(width: 48, height: 48)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Submitted to University")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Photo and campus coordinate attached")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }

                Text("Report \(report.shortIdentifier)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.84))

                Text("Photo attached: \(report.hasPhoto || hasPhoto ? "Yes" : "No")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))

                Text("Campus coordinate: \(report.coordinateText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))

                Text(report.summary)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(reportPulse ? 0.78 : 0.22), lineWidth: reportPulse ? 2 : 1)
            )
            .scaleEffect(reportPulse ? 1.04 : 1)
            .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("adaReport.card")
        }
    }
}
