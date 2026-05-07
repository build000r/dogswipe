const HOP_BY_HOP_HEADERS = [
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
];

const BODYLESS_METHODS = new Set(["GET", "HEAD"]);

export default {
  async fetch(request, env) {
    const incomingUrl = new URL(request.url);
    const originBaseUrl = env.DOGSWIPE_ORIGIN_URL || "https://api.sweetpotato.dev/__dogswipe_edge_origin";
    const targetUrl = toOriginUrl(originBaseUrl, incomingUrl);
    const requestHeaders = toOriginHeaders(request, incomingUrl);

    const originResponse = await fetch(targetUrl, {
      body: BODYLESS_METHODS.has(request.method) ? undefined : request.body,
      headers: requestHeaders,
      method: request.method,
      redirect: "manual",
      signal: AbortSignal.timeout(15000),
    });

    const responseHeaders = new Headers(originResponse.headers);
    responseHeaders.set("strict-transport-security", "max-age=63072000; includeSubDomains; preload");
    responseHeaders.set("x-dogswipe-edge", "cloudflare-worker");

    return new Response(originResponse.body, {
      headers: responseHeaders,
      status: originResponse.status,
      statusText: originResponse.statusText,
    });
  },
};

function toOriginUrl(originBaseUrl, incomingUrl) {
  const originUrl = new URL(originBaseUrl);
  const prefix = originUrl.pathname.replace(/\/$/, "");
  const incomingPath = incomingUrl.pathname === "/" ? "/" : incomingUrl.pathname;
  originUrl.pathname = `${prefix}${incomingPath}`.replace(/\/{2,}/g, "/");
  originUrl.search = incomingUrl.search;
  return originUrl.toString();
}

function toOriginHeaders(request, incomingUrl) {
  const headers = new Headers(request.headers);
  for (const headerName of HOP_BY_HOP_HEADERS) {
    headers.delete(headerName);
  }
  headers.delete("host");

  headers.set("x-forwarded-host", incomingUrl.host);
  headers.set("x-forwarded-proto", "https");
  headers.set("x-original-url", incomingUrl.toString());
  headers.set("x-dogswipe-edge", "cloudflare-worker");
  return headers;
}
