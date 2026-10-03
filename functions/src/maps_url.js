function validateMapsUrl(value) {
  const url = new URL(value);
  const hosts = new Set(['maps.app.goo.gl', 'goo.gl', 'maps.google.com', 'www.google.com', 'google.com']);
  if (url.protocol !== 'https:' || !hosts.has(url.hostname) || url.username || url.password || url.port) {
    throw new Error('Only HTTPS Google Maps links are supported.');
  }
  return url;
}

async function fetchMapsUrl(value, options = {}) {
  let url = validateMapsUrl(value);
  for (let redirects = 0; redirects <= 5; redirects++) {
    const response = await fetch(url, { ...options, redirect: 'manual', signal: AbortSignal.timeout(10000) });
    if (![301, 302, 303, 307, 308].includes(response.status)) {
      if (!response.ok) throw new Error('Could not load this Maps link.');
      return response;
    }
    const location = response.headers.get('location');
    if (!location) throw new Error('Invalid Maps redirect.');
    await response.body?.cancel();
    url = validateMapsUrl(new URL(location, url).href);
  }
  throw new Error('Too many Maps redirects.');
}
module.exports = { validateMapsUrl, fetchMapsUrl };
