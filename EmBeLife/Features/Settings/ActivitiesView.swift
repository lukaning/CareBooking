import SwiftUI

struct ActivitiesView: View {
    @State private var activities = ActivityItem.samples
    @State private var filter: ActivityFilter = .all

    private let muted = Color(red: 0.55, green: 0.58, blue: 0.65)
    private let timelineGray = Color(red: 0.86, green: 0.87, blue: 0.90)
    private let pageBG = Color.white

    private var filtered: [ActivityItem] {
        switch filter {
        case .all: activities
        case .today: activities.filter(\.isToday)
        case .bookings: activities.filter { $0.kind == .booking }
        case .payments: activities.filter { $0.kind == .payment }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerControls
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
                        timelineRow(item, isFirst: index == 0, isLast: index == filtered.count - 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .background(pageBG)
        .navigationTitle("Activities")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerControls: some View {
        HStack {
            Menu {
                ForEach(ActivityFilter.allCases) { option in
                    Button {
                        filter = option
                    } label: {
                        if filter == option {
                            Label(option.title, systemImage: "checkmark")
                        } else {
                            Text(option.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Activities")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                }
            }

            Spacer()

            Image(systemName: "slider.horizontal.3")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.darkText)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)
        }
    }

    private func timelineRow(_ item: ActivityItem, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(isFirst ? Theme.brandOrange : timelineGray)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: (isFirst ? Theme.brandOrange : timelineGray).opacity(0.35), radius: 3, y: 1)
                .padding(.top, 18)

            activityCard(item, isHighlighted: isFirst)
                .padding(.bottom, isLast ? 0 : 16)
        }
        .overlay(alignment: .leading) {
            if !isLast {
                Rectangle()
                    .fill(timelineGray)
                    .frame(width: 2)
                    .padding(.leading, 5)
                    .padding(.top, 32)
                    .padding(.bottom, 0)
            }
        }
    }

    private func activityCard(_ item: ActivityItem, isHighlighted: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Theme.brandOrange)
                    .frame(width: 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.body.weight(.bold))
                        .foregroundStyle(Theme.darkText)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(item.timeLabel)
                        .font(.caption)
                        .foregroundStyle(muted)
                }

                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(muted)
                    .lineLimit(3)
            }
            .padding(14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.92, green: 0.93, blue: 0.95), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

private enum ActivityFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case bookings
    case payments

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All activities"
        case .today: "Today"
        case .bookings: "Bookings"
        case .payments: "Payments"
        }
    }
}

private enum ActivityKind {
    case booking
    case payment
    case message
    case system
}

private struct ActivityItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let timeLabel: String
    let isToday: Bool
    let kind: ActivityKind

    static let samples: [ActivityItem] = [
        ActivityItem(
            id: "1",
            title: "Booking confirmed with Eric Acmen",
            detail: "Personal Care Aide · In-person appointment scheduled for tomorrow at 3:00 PM.",
            timeLabel: "today",
            isToday: true,
            kind: .booking
        ),
        ActivityItem(
            id: "2",
            title: "Gift balance received",
            detail: "You received a $50 gift toward care services. Funds are ready to use at checkout.",
            timeLabel: "today",
            isToday: true,
            kind: .payment
        ),
        ActivityItem(
            id: "3",
            title: "New message from Lesya Borodina",
            detail: "Provider followed up about care plan preferences and availability for weekends.",
            timeLabel: "19 Feb 2021",
            isToday: false,
            kind: .message
        ),
        ActivityItem(
            id: "4",
            title: "Visit completed — Katie's parent",
            detail: "Postpartum support session marked complete. Checklist and notes are available in Booked.",
            timeLabel: "19 Feb 2021",
            isToday: false,
            kind: .booking
        ),
        ActivityItem(
            id: "5",
            title: "Payment processed",
            detail: "Stripe charged $75 for 3 hours of companionship care with Marvin McKinney.",
            timeLabel: "18 Feb 2021",
            isToday: false,
            kind: .payment
        ),
        ActivityItem(
            id: "6",
            title: "Profile reminder",
            detail: "Add family members and preferred languages so providers can match your care needs faster.",
            timeLabel: "17 Feb 2021",
            isToday: false,
            kind: .system
        )
    ]
}

#Preview {
    NavigationStack {
        ActivitiesView()
    }
}
