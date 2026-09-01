package com.embelife.app.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.LocationManager
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * Android counterpart to `EmBeLife/Models/LocationManager.swift`. CoreLocation's
 * authorization + reverse geocoding is covered by the platform `LocationManager` and
 * `Geocoder`; the sample fallbacks keep the panel matching the design when permission
 * is denied or no fix is available, exactly as iOS does.
 */
object LocationHelper {

    const val SAMPLE_ADDRESS = "102 Centre Boulevard / Suite B, San Francisco"
    const val SAMPLE_LATITUDE = 37.7749
    const val SAMPLE_LONGITUDE = -122.4194

    val permissions = arrayOf(
        Manifest.permission.ACCESS_COARSE_LOCATION,
        Manifest.permission.ACCESS_FINE_LOCATION,
    )

    fun hasPermission(context: Context): Boolean = permissions.any {
        ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Returns the last known coordinate, or the sample coordinate when permission is
     * missing or no provider has a cached fix.
     */
    fun lastKnownCoordinate(context: Context): Pair<Double, Double> {
        if (!hasPermission(context)) return SAMPLE_LATITUDE to SAMPLE_LONGITUDE

        val manager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            ?: return SAMPLE_LATITUDE to SAMPLE_LONGITUDE

        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        for (provider in providers) {
            val location = runCatching { manager.getLastKnownLocation(provider) }.getOrNull()
            if (location != null) return location.latitude to location.longitude
        }
        return SAMPLE_LATITUDE to SAMPLE_LONGITUDE
    }

    /**
     * Reverse geocodes to a single address line. The blocking `getFromLocation` overload is
     * deprecated on API 33+, so callers should treat this as off-main-thread work.
     */
    @Suppress("DEPRECATION")
    fun addressLine(context: Context, latitude: Double, longitude: Double): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // The async Geocoder API needs a callback; the MVP only needs a best-effort
            // line, so fall through to the sample when it isn't immediately available.
            return runCatching {
                Geocoder(context)
                    .getFromLocation(latitude, longitude, 1)
                    ?.firstOrNull()
                    ?.let(::formatAddress)
            }.getOrNull().orEmpty().ifEmpty { SAMPLE_ADDRESS }
        }

        return runCatching {
            Geocoder(context)
                .getFromLocation(latitude, longitude, 1)
                ?.firstOrNull()
                ?.let(::formatAddress)
        }.getOrNull().orEmpty().ifEmpty { SAMPLE_ADDRESS }
    }

    private fun formatAddress(address: android.location.Address): String =
        listOfNotNull(
            listOfNotNull(address.subThoroughfare, address.thoroughfare)
                .joinToString(" ")
                .ifBlank { null },
            address.locality,
            address.adminArea,
        ).joinToString(", ")
}
