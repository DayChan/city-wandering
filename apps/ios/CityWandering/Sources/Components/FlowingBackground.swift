import SwiftUI

struct FlowingBackground: View {
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate * 0.18
            Canvas { ctx, size in
                let w = size.width
                let h = size.height

                // 5 个彩色光斑，各自按不同频率和轨迹移动
                let blobs: [(color: Color, ox: Double, oy: Double, fx: Double, fy: Double, r: Double)] = [
                    (.purple,  0.25, 0.20,  0.9, 0.7, 0.55),
                    (.blue,    0.75, 0.15,  0.8, 1.1, 0.50),
                    (.pink,    0.55, 0.70,  1.1, 0.9, 0.60),
                    (.orange,  0.15, 0.65,  0.7, 1.3, 0.45),
                    (.teal,    0.80, 0.80,  1.3, 0.8, 0.50),
                ]

                for blob in blobs {
                    let x = (blob.ox + sin(t * blob.fx) * 0.28) * w
                    let y = (blob.oy + cos(t * blob.fy) * 0.28) * h
                    let r  = blob.r * max(w, h)

                    let gradient = Gradient(colors: [blob.color.opacity(0.55), blob.color.opacity(0)])
                    let radial   = GraphicsContext.Shading.radialGradient(
                        gradient,
                        center: CGPoint(x: x, y: y),
                        startRadius: 0,
                        endRadius: r
                    )
                    ctx.blendMode = .plusLighter
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: radial)
                }
            }
            .blur(radius: 60)
            .opacity(0.28)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
