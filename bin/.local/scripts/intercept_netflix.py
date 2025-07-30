from mitmproxy import http
import json

TARGET_OPERATIONS = [
    "CLCSInterstitialLolomo",
    "CLCSInterstitialPlaybackAndPostPlayback",
]

def response(flow: http.HTTPFlow):
    # Only intercept Netflix GraphQL API requests
    if not flow.request.pretty_url.startswith("https://web.prod.cloud.netflix.com/graphql"):
        return

    try:
        # Try to parse the request body as JSON
        request_data = json.loads(flow.request.get_text())
    except Exception:
        return  # Skip if parsing fails

    # Check if the operationName matches the target, if so, return 500 Internal Server Error to bypass the check
    if request_data.get("operationName") in TARGET_OPERATIONS:
        flow.response = http.Response.make(
            500,
            b"Internal Server Error",
            {"Content-Type": "text/plain"}
        )