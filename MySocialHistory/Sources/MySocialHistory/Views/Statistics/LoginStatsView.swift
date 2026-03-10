import SwiftUI
import Charts
import MapKit
import CoreLocation

// MARK: - Main Login Stats View

struct StatsLoginsView: View {
    var viewModel: StatisticsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading statistics…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.loadError {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        LoginSummaryCard(totalSessions: viewModel.loginCount,
                                         devices: viewModel.loginDevices)
                        LoginActivityChart(data: viewModel.loginsPerMonth)
                        LoginByHourChart(data: viewModel.loginByHour)
                        DeviceBreakdownChart(data: viewModel.loginDevices)
                        TopCitiesView(cities: viewModel.loginCities)
                    }
                    .padding()
                }
            }
        }
        .onAppear { viewModel.loadIfNeeded() }
        .navigationTitle("Login Activity")
    }
}

// MARK: - Summary Card

private struct LoginSummaryCard: View {
    let totalSessions: Int
    let devices: [DeviceCount]

    var body: some View {
        GroupBox("Login Activity") {
            HStack(spacing: 0) {
                statCell("Total Sessions", value: "\(totalSessions.formatted(.number))",
                         icon: "lock.shield.fill", color: .blue)
                Divider().frame(height: 50)
                statCell("Devices Used", value: "\(devices.count)",
                         icon: "desktopcomputer", color: .purple)
                Divider().frame(height: 50)
                statCell("Top Device",
                         value: devices.first?.device ?? "—",
                         icon: deviceIcon(devices.first?.device ?? ""),
                         color: .green)
            }
        }
    }

    private func statCell(_ label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Activity Over Time

private struct LoginActivityChart: View {
    let data: [MonthCount]

    var body: some View {
        GroupBox("Sessions Over Time") {
            if data.isEmpty {
                Text("No login data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("Sessions", item.count)
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
                                Text(v.formatted(.number))
                            }
                        }
                    }
                }
                .frame(height: 220)
            }
        }
    }
}

// MARK: - Login by Hour

private struct LoginByHourChart: View {
    let data: [HourCount]

    var body: some View {
        GroupBox("Sessions by Hour of Day") {
            if data.isEmpty {
                Text("No login data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Hour", "\(item.hour):00"),
                        y: .value("Sessions", item.count)
                    )
                    .foregroundStyle(Color.indigo.gradient)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(v.formatted(.number))
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }
}

// MARK: - Device Breakdown (Donut)

private struct DeviceBreakdownChart: View {
    let data: [DeviceCount]

    private var total: Int { data.map(\.count).reduce(0, +) }

    var body: some View {
        GroupBox("Device Breakdown") {
            if data.isEmpty {
                Text("No login data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                HStack(spacing: 24) {
                    Chart(data) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Device", item.device))
                    }
                    .chartLegend(.hidden)
                    .frame(width: 180, height: 180)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data) { item in
                            HStack(spacing: 8) {
                                Image(systemName: deviceIcon(item.device))
                                    .frame(width: 20)
                                    .foregroundStyle(.secondary)
                                Text(item.device)
                                    .font(.headline)
                                Spacer()
                                Text(item.count.formatted(.number))
                                    .font(.body.bold())
                                    .monospacedDigit()
                                Text("(\(percentage(item.count))%)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func percentage(_ count: Int) -> String {
        guard total > 0 else { return "0" }
        let pct = Double(count) / Double(total) * 100
        return String(format: "%.0f", pct)
    }
}

// MARK: - Login Locations Map + List

private struct LoginLocationPin: Identifiable {
    let id: String
    let city: String
    let count: Int
    let coordinate: CLLocationCoordinate2D
}

private struct TopCitiesView: View {
    let cities: [CityCount]
    @State private var pins: [LoginLocationPin] = []
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var isGeocoding = false

    private var maxCount: Int { cities.first?.count ?? 1 }

    var body: some View {
        GroupBox("Login Locations") {
            if cities.isEmpty {
                Text("No location data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 12) {
                    // Map
                    ZStack(alignment: .topTrailing) {
                        Map(position: $mapPosition) {
                            ForEach(pins) { pin in
                                Annotation(pin.city, coordinate: pin.coordinate) {
                                    pinView(count: pin.count)
                                }
                            }
                        }
                        .mapStyle(.standard(elevation: .flat))
                        .frame(height: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        if isGeocoding {
                            ProgressView()
                                .padding(8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                                .padding(8)
                        }
                    }

                    // List below map
                    VStack(spacing: 0) {
                        ForEach(Array(cities.enumerated()), id: \.element.id) { idx, city in
                            HStack(spacing: 12) {
                                Text(city.city)
                                    .font(.headline)
                                    .lineLimit(1)
                                    .frame(width: 160, alignment: .leading)

                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.teal.gradient)
                                        .frame(width: geo.size.width * CGFloat(city.count) / CGFloat(maxCount))
                                }
                                .frame(height: 16)

                                Text(city.count.formatted(.number))
                                    .font(.callout.bold())
                                    .monospacedDigit()
                                    .frame(width: 50, alignment: .trailing)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)

                            if idx < cities.count - 1 {
                                Divider().padding(.leading, 8)
                            }
                        }
                    }
                }
            }
        }
        .task(id: cities.map(\.id)) {
            await geocodeCities()
        }
    }

    private func pinView(count: Int) -> some View {
        let size = pinSize(for: count)
        return ZStack {
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: size, height: size)
            Circle()
                .fill(Color.red.opacity(0.7))
                .frame(width: size * 0.5, height: size * 0.5)
            Text("\(count)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func pinSize(for count: Int) -> CGFloat {
        guard maxCount > 0 else { return 20 }
        let ratio = Double(count) / Double(maxCount)
        return 20 + 30 * ratio
    }

    private func geocodeCities() async {
        isGeocoding = true
        let geocoder = CLGeocoder()
        var results: [LoginLocationPin] = []

        for city in cities {
            let query = "\(city.city), \(city.country)"
            do {
                let placemarks = try await geocoder.geocodeAddressString(query)
                if let location = placemarks.first?.location {
                    results.append(LoginLocationPin(
                        id: city.id,
                        city: city.city,
                        count: city.count,
                        coordinate: location.coordinate
                    ))
                }
            } catch {
                // Skip cities that can't be geocoded
            }
            // Small delay to avoid geocoder rate limits
            try? await Task.sleep(for: .milliseconds(200))
        }

        pins = results
        isGeocoding = false
    }
}

// MARK: - Helpers

private func deviceIcon(_ device: String) -> String {
    switch device {
    case "iPhone":  return "iphone"
    case "iPad":    return "ipad"
    case "Mac":     return "laptopcomputer"
    case "Windows": return "desktopcomputer"
    case "Android": return "candybarphone"
    case "Linux":   return "terminal"
    default:        return "globe"
    }
}
