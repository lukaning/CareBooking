import Charts
import SwiftUI

struct DashboardView: View {
    @Environment(AppModel.self) private var appModel

    private let pageBG = Color(red: 0.97, green: 0.97, blue: 0.98)
    private let muted = Color(red: 0.45, green: 0.48, blue: 0.55)

    private var bookedCount: Int {
        appModel.bookings.filter { $0.status == .booked }.count
    }

    private var completedCount: Int {
        appModel.bookings.filter { $0.status == .completed }.count
    }

    private var requestedCount: Int {
        appModel.bookings.filter { $0.status == .requested }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryStrip

                careHoursCard
                serviceMixCard
                bookingStatusCard
                satisfactionCard
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .background(pageBG)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appModel.seedBookingsIfNeeded()
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            summaryTile(title: "Active", value: "\(bookedCount)", caption: "booked", tint: Theme.brandOrange)
            summaryTile(title: "Requests", value: "\(requestedCount)", caption: "pending", tint: Color(red: 0.35, green: 0.55, blue: 0.95))
            summaryTile(title: "Done", value: "\(max(completedCount, 3))", caption: "visits", tint: Color(red: 0.30, green: 0.68, blue: 0.50))
        }
    }

    private func summaryTile(title: String, value: String, caption: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(muted)
            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.darkText)
            Text(caption)
                .font(.caption2.weight(.medium))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var careHoursCard: some View {
        dashboardCard(title: "Care hours this week", subtitle: "Hours of support booked across the last 7 days") {
            Chart(CareHoursPoint.week) { point in
                BarMark(
                    x: .value("Day", point.day),
                    y: .value("Hours", point.hours)
                )
                .foregroundStyle(Theme.brandOrange.gradient)
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
    }

    private var serviceMixCard: some View {
        dashboardCard(title: "Service mix", subtitle: "Where your EmBeLife care budget is going") {
            Chart(ServiceMixPoint.samples) { point in
                SectorMark(
                    angle: .value("Share", point.share),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Service", point.name))
                .cornerRadius(4)
            }
            .chartLegend(position: .bottom, spacing: 12)
            .frame(height: 220)
        }
    }

    private var bookingStatusCard: some View {
        let points = [
            StatusPoint(status: "Requested", count: max(requestedCount, 1)),
            StatusPoint(status: "Booked", count: max(bookedCount, 1)),
            StatusPoint(status: "Completed", count: max(completedCount, 3))
        ]

        return dashboardCard(title: "Booking pipeline", subtitle: "Snapshot of appointment status") {
            Chart(points) { point in
                BarMark(
                    x: .value("Count", point.count),
                    y: .value("Status", point.status)
                )
                .foregroundStyle(statusColor(for: point.status).gradient)
                .cornerRadius(6)
            }
            .frame(height: 160)
        }
    }

    private var satisfactionCard: some View {
        dashboardCard(title: "Provider match quality", subtitle: "Average rating of providers you engaged") {
            Chart(MatchQualityPoint.months) { point in
                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Rating", point.rating)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Theme.brandOrange)
                .lineStyle(StrokeStyle(lineWidth: 3))

                AreaMark(
                    x: .value("Month", point.month),
                    y: .value("Rating", point.rating)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.brandOrange.opacity(0.28), Theme.brandOrange.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                PointMark(
                    x: .value("Month", point.month),
                    y: .value("Rating", point.rating)
                )
                .foregroundStyle(Theme.brandOrange)
            }
            .chartYScale(domain: 3.5...5.0)
            .frame(height: 180)
        }
    }

    private func dashboardCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.darkText)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(muted)
            content()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "Requested": Color(red: 0.35, green: 0.55, blue: 0.95)
        case "Booked": Theme.brandOrange
        default: Color(red: 0.30, green: 0.68, blue: 0.50)
        }
    }
}

private struct CareHoursPoint: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double

    static let week: [CareHoursPoint] = [
        CareHoursPoint(day: "Mon", hours: 2),
        CareHoursPoint(day: "Tue", hours: 4),
        CareHoursPoint(day: "Wed", hours: 3),
        CareHoursPoint(day: "Thu", hours: 5),
        CareHoursPoint(day: "Fri", hours: 2.5),
        CareHoursPoint(day: "Sat", hours: 6),
        CareHoursPoint(day: "Sun", hours: 1.5)
    ]
}

private struct ServiceMixPoint: Identifiable {
    let id = UUID()
    let name: String
    let share: Double

    static let samples: [ServiceMixPoint] = [
        ServiceMixPoint(name: "Personal Care", share: 35),
        ServiceMixPoint(name: "Postpartum", share: 25),
        ServiceMixPoint(name: "Companionship", share: 20),
        ServiceMixPoint(name: "Therapy", share: 12),
        ServiceMixPoint(name: "Other", share: 8)
    ]
}

private struct StatusPoint: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
}

private struct MatchQualityPoint: Identifiable {
    let id = UUID()
    let month: String
    let rating: Double

    static let months: [MatchQualityPoint] = [
        MatchQualityPoint(month: "Jan", rating: 4.2),
        MatchQualityPoint(month: "Feb", rating: 4.4),
        MatchQualityPoint(month: "Mar", rating: 4.3),
        MatchQualityPoint(month: "Apr", rating: 4.6),
        MatchQualityPoint(month: "May", rating: 4.5),
        MatchQualityPoint(month: "Jun", rating: 4.7)
    ]
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(AppModel())
}
