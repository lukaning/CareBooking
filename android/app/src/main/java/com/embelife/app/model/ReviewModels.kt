package com.embelife.app.model

import androidx.compose.ui.graphics.Color
import java.util.UUID

data class ProviderReview(
    val id: UUID = UUID.randomUUID(),
    val providerID: String,
    val authorName: String,
    val avatarColor: Color,
    var rating: Int,
    var body: String,
    var relativeTime: String,
    var liked: Boolean = false,
) {
    companion object {
        fun samples(forProviderID: String): List<ProviderReview> = when (forProviderID) {
            "eric" -> listOf(
                ProviderReview(
                    providerID = forProviderID,
                    authorName = "Mike B",
                    avatarColor = Color(0xFFF2C726),
                    rating = 5,
                    body = "I booked Eric’s service 3 weeks ago and now come back just to say ‘Awesome’. I really appreciated his patience.",
                    relativeTime = "about 1 hour ago",
                ),
                ProviderReview(
                    providerID = forProviderID,
                    authorName = "Tania W",
                    avatarColor = Color(0xFFF27333),
                    rating = 5,
                    body = "Great service, super helpful!",
                    relativeTime = "about 1 hour ago",
                ),
            )
            "maya" -> listOf(
                ProviderReview(
                    providerID = forProviderID,
                    authorName = "Sara L",
                    avatarColor = Color(0xFF738CE6),
                    rating = 5,
                    body = "Maya was thoughtful and calm during our first weeks home. Highly recommend.",
                    relativeTime = "2 days ago",
                ),
            )
            else -> listOf(
                ProviderReview(
                    providerID = forProviderID,
                    authorName = "Alex P",
                    avatarColor = Color(0xFF66B38C),
                    rating = 5,
                    body = "Warm, reliable companion care. Made a real difference.",
                    relativeTime = "1 week ago",
                ),
            )
        }
    }
}
