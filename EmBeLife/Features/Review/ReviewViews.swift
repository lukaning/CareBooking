import SwiftUI

// MARK: - Shared rating control

struct StarRatingControl: View {
    @Binding var rating: Int
    var maxStars: Int = 5
    var size: CGFloat = 28
    var interactive: Bool = true
    var fillColor: Color = Color(red: 1.0, green: 0.78, blue: 0.12)
    var emptyColor: Color = Color(red: 0.78, green: 0.80, blue: 0.84)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxStars, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.scaledSystem(size: size))
                    .foregroundStyle(index <= rating ? fillColor : emptyColor)
                    .onTapGesture {
                        guard interactive else { return }
                        withAnimation(.easeInOut(duration: 0.12)) {
                            rating = index
                        }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(rating) of \(maxStars) stars")
        .accessibilityAdjustableAction { direction in
            guard interactive else { return }
            switch direction {
            case .increment: rating = min(maxStars, rating + 1)
            case .decrement: rating = max(0, rating - 1)
            @unknown default: break
            }
        }
    }
}

struct ProviderRatingLabel: View {
    let rating: Double
    let reviewCount: Int
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(compact ? .caption : .subheadline.weight(.semibold))
                .foregroundStyle(Theme.brandOrange)
            Text(String(format: "%.1f", rating))
                .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                .foregroundStyle(Theme.darkText)
            Text("(\(reviewCount) reviews)")
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(Theme.mutedText)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(format: "%.1f", rating)) stars, \(reviewCount) reviews")
        .accessibilityHint("View reviews")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Rate & Review (Review_04)

struct RateAndReviewView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let provider: Provider

    @State private var draftRating = 0
    @State private var showSubmitBanner = false

    private var reviews: [ProviderReview] {
        appModel.reviews(for: provider.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rate your Provider, \(provider.name)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.darkText)

                    Text(reviews.isEmpty ? "Be the first to review" : "Share your experience with \(provider.name)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)

                    StarRatingControl(rating: $draftRating, size: 34)
                        .padding(.top, 4)

                    if draftRating > 0 {
                        Button {
                            submitInlineRating()
                        } label: {
                            Text("Submit \(draftRating)-star rating")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.brandOrange)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !reviews.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(reviews.enumerated()), id: \.element.id) { index, review in
                            reviewRow(review)
                            if index < reviews.count - 1 {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 28)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Rate & Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                        .frame(width: 36, height: 36)
                        .background(Color(red: 0.94, green: 0.95, blue: 0.97))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Thanks!", isPresented: $showSubmitBanner) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your rating for \(provider.name) was submitted.")
        }
    }

    private func reviewRow(_ review: ProviderReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(review.avatarColor)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(review.authorName)
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)

                    StarRatingControl(
                        rating: .constant(review.rating),
                        size: 12,
                        interactive: false,
                        fillColor: Color(red: 1.0, green: 0.78, blue: 0.12)
                    )

                    Text(review.body)
                        .font(.subheadline)
                        .foregroundStyle(Theme.darkText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(review.relativeTime)
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                        .padding(.top, 2)

                    HStack(spacing: 18) {
                        Button(review.liked ? "Liked" : "Like") {
                            appModel.toggleReviewLike(id: review.id)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.darkText)

                        Button("Reply") {
                            // MVP: visual affordance only
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.darkText)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 14)
        }
    }

    private func submitInlineRating() {
        guard draftRating > 0 else { return }
        appModel.addProviderReview(
            providerID: provider.id,
            rating: draftRating,
            body: "Rated \(draftRating) stars from Rate & Review.",
            authorName: appModel.userName.isEmpty ? "You" : appModel.userName
        )
        draftRating = 0
        showSubmitBanner = true
    }
}

// MARK: - Inline composer (completed booking)

struct InlineBookingReviewComposer: View {
    @Binding var rating: Int
    @Binding var text: String
    var onSubmit: () -> Void

    @FocusState private var focused: Bool

    private let fieldBorder = Color(red: 0.88, green: 0.89, blue: 0.91)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StarRatingControl(rating: $rating, size: 30)

            ZStack(alignment: .bottomTrailing) {
                TextField("Share your thoughts", text: $text, axis: .vertical)
                    .font(.body)
                    .lineLimit(3...6)
                    .focused($focused)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 48)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(fieldBorder, lineWidth: 1)
                    )

                HStack(spacing: 10) {
                    Image(systemName: "face.smiling")
                        .font(.title3)
                        .foregroundStyle(Theme.mutedText)

                    Button {
                        focused = false
                        onSubmit()
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Theme.brandOrange.opacity(canSubmit ? 1 : 0.4))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit)
                    .accessibilityLabel("Submit review")
                }
                .padding(12)
            }
        }
    }

    private var canSubmit: Bool {
        rating > 0 && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
