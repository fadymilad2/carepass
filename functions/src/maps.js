const { validateMapsUrl, fetchMapsUrl } = require('./maps_url');
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

// ✅ New — official Google Geocoding API key, used as the final,
// authoritative fallback when a Maps link resolves to a business
// listing whose page genuinely doesn't expose raw coordinates
// anywhere scrapeable (Google matched it to a known place/feature ID
// instead of a raw dropped pin). No amount of pattern-matching on
// the HTML can find a number that was never sent to the browser in
// the first place — this calls Google's own database directly
// instead of guessing.
const googleMapsApiKey = defineSecret("GOOGLE_MAPS_API_KEY");

// ── Helper — is this coordinate plausibly inside Ghana? ─────────────────
function isInGhanaBounds(lat, lng) {
  return lat >= 4 && lat <= 12 && lng >= -4 && lng <= 2;
}

// ── Helper — extracts coordinates from text (URL or HTML) ───────────────
function extractPinCoordinates(text) {
  if (!text) return null;

  let decodedText = text;
  try { decodedText = decodeURIComponent(text); } catch (e) { }

  const searchSpace = text + "\n" + decodedText;

  const atMatch = searchSpace.match(/(?:@|%40)(-?\d+\.\d+)(?:,|%2C)(-?\d+\.\d+)/);
  if (atMatch) {
    const lat = parseFloat(atMatch[1]);
    const lng = parseFloat(atMatch[2]);
    if (isInGhanaBounds(lat, lng)) return { lat, lng };
  }

  const lat3d = searchSpace.match(/(?:!|%21)3d(-?\d+(?:\.\d+)?)/);
  const lng4d = searchSpace.match(/(?:!|%21)4d(-?\d+(?:\.\d+)?)/);
  if (lat3d && lng4d) {
    const lat = parseFloat(lat3d[1]);
    const lng = parseFloat(lng4d[1]);
    if (isInGhanaBounds(lat, lng)) return { lat, lng };
  }

  const paramMatch = searchSpace.match(/(?:q|ll|markers|center)=(?:%22)?(-?\d+(?:\.\d+)?)(?:%2C|,)(-?\d+(?:\.\d+)?)/i);
  if (paramMatch) {
    const lat = parseFloat(paramMatch[1]);
    const lng = parseFloat(paramMatch[2]);
    if (isInGhanaBounds(lat, lng)) return { lat, lng };
  }

  const aggressiveRegex = /(-?\d{1,2}\.\d{4,15})[^\d\w]{1,15}(-?\d{1,3}\.\d{4,15})/g;
  let match;
  while ((match = aggressiveRegex.exec(searchSpace)) !== null) {
    const lat = parseFloat(match[1]);
    const lng = parseFloat(match[2]);
    if (isInGhanaBounds(lat, lng)) return { lat, lng };
    if (isInGhanaBounds(lng, lat)) return { lat: lng, lng: lat };
  }

  return null;
}

// ✅ New — pulls the human-readable place name/address out of a
// resolved Maps "place" URL, e.g. from
// ".../maps/place/Wellbridge+Medical+Solutions+Ltd,+33A+Senchi+St,+Accra,+Ghana/data=..."
// this returns "Wellbridge Medical Solutions Ltd, 33A Senchi St, Accra, Ghana"
// — this is what gets geocoded when no coordinates could be scraped
// directly from the page.
function extractPlaceNameFromUrl(url) {
  const match = url.match(/\/maps\/place\/([^/]+)/);
  if (!match) return null;
  try {
    return decodeURIComponent(match[1].replace(/\+/g, " "));
  } catch (e) {
    return match[1].replace(/\+/g, " ");
  }
}

// ✅ New — official, authoritative last resort. Calls Google's own
// Geocoding API with the place's name/address text and returns
// whatever coordinates Google itself has on file for it — this is
// the same lookup Google Maps performs internally, so it's reliable
// for exactly the cases where scraping the page turns up nothing
// (business listings matched by feature ID rather than a raw pin).
async function geocodeAddress(address, apiKey) {
  const encoded = encodeURIComponent(address);
  const response = await fetch(
    `https://maps.googleapis.com/maps/api/geocode/json?address=${encoded}&key=${apiKey}`
  );
  const data = await response.json();

  if (data.status !== "OK" || !data.results || data.results.length === 0) {
    console.warn("Geocoding API returned no results:", data.status);
    return null;
  }

  const location = data.results[0].geometry.location;
  const lat = location.lat;
  const lng = location.lng;

  if (isInGhanaBounds(lat, lng)) {
    return { lat, lng };
  }
  return null;
}

// ── Resolve Google Maps Link ────────────────────────────────────────────
exports.resolveGoogleMapsLink = onCall(
  {
    enforceAppCheck: false,
    cors: true,
    timeoutSeconds: 30,
    secrets: [googleMapsApiKey], // ✅ New
  },
  async (request) => {
    const { url } = request.data || {};
    if (!url) {
      throw new HttpsError("invalid-argument", "Missing url.");
    }

    try {
      validateMapsUrl(url);
      // Step 1 — check the original link itself.
      let coords = extractPinCoordinates(url);
      if (coords) {
        return { success: true, latitude: coords.lat, longitude: coords.lng, resolvedUrl: url };
      }

      // Step 2 — follow redirects like a real browser.
      const response = await fetchMapsUrl(url, {
        redirect: "follow",
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
          "Accept-Language": "en-US,en;q=0.9",
          "Cookie": "CONSENT=YES+cb.20230531-04-p0.en+FX+884; SOCS=CAESHAgBEhJnd3NfMjAyMzA4MTAtMF9SQzIaAmVuIAEaBgiA_LyaBg"
        }
      });

      const finalUrl = response.url;

      // Step 3 — check the resolved URL.
      coords = extractPinCoordinates(finalUrl);
      if (coords) {
        return { success: true, latitude: coords.lat, longitude: coords.lng, resolvedUrl: finalUrl };
      }

      // Step 4 — check the page's HTML content.
      const html = await response.text();
      coords = extractPinCoordinates(html);
      if (coords) {
        return { success: true, latitude: coords.lat, longitude: coords.lng, resolvedUrl: finalUrl };
      }

      // ✅ Step 5 — NEW, final authoritative fallback. Nothing was
      // scrapeable (this is the "business listing with no raw pin
      // in the URL" case) — pull the place's name/address out of the
      // URL and ask Google's official Geocoding API for its real
      // coordinates directly.
      const placeName = extractPlaceNameFromUrl(finalUrl) || extractPlaceNameFromUrl(url);
      const apiKey = googleMapsApiKey.value();

      if (placeName && apiKey) {
        console.log("Falling back to Geocoding API for:", placeName);
        coords = await geocodeAddress(placeName, apiKey);
        if (coords) {
          return {
            success: true,
            latitude: coords.lat,
            longitude: coords.lng,
            resolvedUrl: finalUrl,
          };
        }
      }

      let debugUrl = finalUrl.length > 200 ? finalUrl.substring(0, 200) + "..." : finalUrl;
      throw new Error(
        `Could not determine coordinates for this location` +
        (placeName ? ` ("${placeName}")` : "") +
        `. Final URL: ${debugUrl}`
      );

    } catch (error) {
      console.error("resolveGoogleMapsLink error:", error);
      throw new HttpsError("internal", error.message);
    }
  }
);

