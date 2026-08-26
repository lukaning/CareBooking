import SwiftUI

/// Confirmation screen shown after the user taps Cancel on a booking.
struct CancelBookingConfirmationSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let booking: Booking
    var onFinished: (() -> Void)? = nil

    private enum Step {
        case confirm
        case cancelled
    }

    @State private var step: Step = .confirm

    private let pageBG = Color(red: 0.96, green: 0.96, blue: 0.97)
    private let bodyDark = Color(red: 0.12, green: 0.14, blue: 0.18)
    private let labelMuted = Color(red: 0.45, green: 0.48, blue: 0.56)
    private let keepFill = Color(red: 0.91, green: 0.92, blue: 0.94)

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .confirm:
                    confirmStep
                case .cancelled:
                    cancelledStep
                }
            }
            .background(pageBG.ignoresSafeArea())
            .navigationTitle(step == .confirm ? "Cancel booking" : "Cancelled")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(bodyDark)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Back")
                }
            }
            .navigationBarBackButtonHidden()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private var confirmStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Are you sure you want to cancel this visit?")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(bodyDark)

                    Text("This removes the booking from your list. You can book \(booking.provider.name) again later.")
                        .font(.subheadline)
                        .foregroundStyle(labelMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            Image(booking.provider.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(booking.provider.name)
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(bodyDark)
                                Text(booking.provider.title)
                                    .font(.caption)
                                    .foregroundStyle(labelMuted)
                            }
                            Spacer(minLength: 0)
                        }

                        Divider()

                        detailRow(
                            icon: "calendar",
                            label: "Date",
                            value: booking.date.formatted(date: .abbreviated, time: .omitted)
                        )
                        detailRow(
                            icon: "clock",
                            label: "Time",
                            value: booking.timeRangeLabel
                        )
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
                }
                .padding(20)
            }

            VStack(spacing: 10) {
                Button {
                    appModel.cancelBooking(id: booking.id)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        step = .cancelled
                    }
                } label: {
                    Text("Yes, cancel booking")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.errorCoral)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text("Keep booking")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(bodyDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(keepFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 8)
            .background(Color.white.shadow(color: .black.opacity(0.05), radius: 8, y: -2))
        }
    }

    private var cancelledStep: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 24)
            Image(systemName: "checkmark.circle")
                .font(.scaledSystem(size: 56, weight: .light))
                .foregroundStyle(Theme.brandOrange)
            Text("Booking cancelled")
                .font(.title2.weight(.bold))
                .foregroundStyle(bodyDark)
            Text("This visit with \(booking.provider.name) has been removed from your list.")
                .font(.subheadline)
                .foregroundStyle(labelMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer(minLength: 24)
            Button("Done") {
                onFinished?()
                dismiss()
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(labelMuted)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(labelMuted)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(bodyDark)
            }
            Spacer(minLength: 0)
        }
    }
}
