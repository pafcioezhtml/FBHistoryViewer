import SwiftUI
import Charts

struct MessagesOverTimeChart: View {
    let data: [MonthCount]
    var overlay: [MonthCount] = []
    @Binding var hoveredMonth: String?   // "YYYY-MM", nil = not hovering

    private var maxCount: Int { max(data.map(\.count).max() ?? 1, 1) }

    var body: some View {
        GroupBox("Messages Over Time") {
            if data.isEmpty {
                emptyState
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("Messages", item.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .year)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.year())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(v, format: .number.notation(.compactName))
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...maxCount)
                .frame(height: 220)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        let pf = geo[proxy.plotFrame!]
                        let bw = barWidth(proxy: proxy, plotFrame: pf)

                        // 1. Hover highlight — drawn first, sits behind overlay bars
                        if let month = hoveredMonth,
                           let monthDate = parseMonth(month),
                           let xPos = proxy.position(forX: monthDate) {
                            Rectangle()
                                .fill(Color.primary.opacity(0.08))
                                .frame(width: bw + 4, height: pf.height)
                                .position(x: pf.origin.x + xPos,
                                          y: pf.origin.y + pf.height / 2)
                        }

                        // 2. Overlay bars — on top of highlight
                        overlayBars(proxy: proxy, geo: geo)

                        // 3. Transparent hit-test layer — on top for mouse events
                        Color.clear
                            .contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let loc):
                                    let xInPlot = loc.x - pf.origin.x
                                    if xInPlot >= 0, xInPlot <= pf.width,
                                       let date = proxy.value(atX: xInPlot, as: Date.self) {
                                        let comps = Calendar.current.dateComponents(
                                            [.year, .month], from: date)
                                        if let ms = Calendar.current.date(from: comps) {
                                            hoveredMonth = monthKey(ms)
                                        }
                                    } else {
                                        hoveredMonth = nil
                                    }
                                case .ended:
                                    hoveredMonth = nil
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: - Overlay bars (same as before)

    @ViewBuilder
    private func overlayBars(proxy: ChartProxy, geo: GeometryProxy) -> some View {
        if !overlay.isEmpty {
            let pf  = geo[proxy.plotFrame!]
            let bw  = barWidth(proxy: proxy, plotFrame: pf)
            ForEach(overlay) { item in
                overlayBar(item: item, proxy: proxy, plotFrame: pf, barWidth: bw)
            }
        }
    }

    @ViewBuilder
    private func overlayBar(item: MonthCount,
                            proxy: ChartProxy,
                            plotFrame: CGRect,
                            barWidth: CGFloat) -> some View {
        if let x     = proxy.position(forX: item.date),
           let y     = proxy.position(forY: item.count),
           let yZero = proxy.position(forY: 0) {
            let h = max(0, yZero - y)
            Rectangle()
                .fill(Color(hue: 0.62, saturation: 0.9, brightness: 0.38))
                .frame(width: barWidth, height: h)
                .position(x: plotFrame.origin.x + x,
                          y: plotFrame.origin.y + y + h / 2)
        }
    }

    // MARK: - Helpers

    private func barWidth(proxy: ChartProxy, plotFrame: CGRect) -> CGFloat {
        guard let first = data.first?.date,
              let next  = Calendar.current.date(byAdding: .month, value: 1, to: first),
              let x0    = proxy.position(forX: first),
              let x1    = proxy.position(forX: next)
        else {
            return max(1, plotFrame.width / CGFloat(max(1, data.count)) * 0.85)
        }
        return max(1, abs(x1 - x0) * 0.85)
    }

    private func parseMonth(_ key: String) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        return fmt.date(from: key)
    }

    private func monthKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        return fmt.string(from: date)
    }

    private var emptyState: some View {
        Text("No message data")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 100)
    }
}
