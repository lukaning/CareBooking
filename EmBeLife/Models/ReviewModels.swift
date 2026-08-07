import Foundation
import SwiftUI

struct ProviderReview: Identifiable, Hashable {
    let id: UUID
    let providerID: String
    let authorName: String
    /// Avatar fill (semantic RGB 0…1).
    let avatarRed: Double
    let avatarGreen: Double
    let avatarBlue: Double
    var rating: Int
    var body: String
    var relativeTime: String
    var liked: Bool

    init(
        id: UUID = UUID(),
        providerID: String,
        authorName: String,
        avatarRed: Double,
        avatarGreen: Double,
        avatarBlue: Double,
        rating: Int,
        body: String,
        relativeTime: String,
        liked: Bool = false
    ) {
        self.id = id
        self.providerID = providerID
        self.authorName = authorName
        self.avatarRed = avatarRed
        self.avatarGreen = avatarGreen
        self.avatarBlue = avatarBlue
        self.rating = rating
        self.body = body
        self.relativeTime = relativeTime
        self.liked = liked
    }

    var avatarColor: Color {
        Color(red: avatarRed, green: avatarGreen, blue: avatarBlue)
    }

    static func samples(for providerID: String) -> [ProviderReview] {
        switch providerID {
        case "eric":
            return [
                ProviderReview(
                    providerID: providerID,
                    authorName: "Mike B",
                    avatarRed: 0.95,
                    avatarGreen: 0.78,
                    avatarBlue: 0.15,
                    rating: 5,
                    body: "I booked Eric’s service 3 weeks ago and now come back just to say ‘Awesome’. I really appreciated his patience.",
                    relativeTime: "about 1 hour ago"
                ),
                ProviderReview(
                    providerID: providerID,
                    authorName: "Tania W",
                    avatarRed: 0.95,
                    avatarGreen: 0.45,
                    avatarBlue: 0.20,
                    rating: 5,
                    body: "Great service, super helpful!",
                    relativeTime: "about 1 hour ago"
                )
            ]
        case "maya":
            return [
                ProviderReview(
                    providerID: providerID,
                    authorName: "Sara L",
                    avatarRed: 0.45,
                    avatarGreen: 0.55,
                    avatarBlue: 0.90,
                    rating: 5,
                    body: "Maya was thoughtful and calm during our first weeks home. Highly recommend.",
                    relativeTime: "2 days ago"
                )
            ]
        default:
            return [
                ProviderReview(
                    providerID: providerID,
                    authorName: "Alex P",
                    avatarRed: 0.40,
                    avatarGreen: 0.70,
                    avatarBlue: 0.55,
                    rating: 5,
                    body: "Warm, reliable companion care. Made a real difference.",
                    relativeTime: "1 week ago"
                )
            ]
        }
    }
}
