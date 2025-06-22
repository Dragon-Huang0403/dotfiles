from mitmproxy import http

# 想攔的文字，只要 response body 包含其中一個就觸發
TARGET_TEXTS = [
    "您的裝置尚未設為此帳戶的同戶裝置。",
    # 可以在這裡繼續加其他關鍵字
]

def response(flow: http.HTTPFlow):
    # 只處理 Netflix GraphQL API
    if not flow.request.pretty_url.startswith("https://web.prod.cloud.netflix.com/graphql"):
        return

    # 把 response 當作純文字看
    body = flow.response.get_text(strict=False)

    # 檢查是否有包含 target text
    for target_text in TARGET_TEXTS:
        if target_text in body:
            print(f"[MITM] Found target text: {target_text}")

            # 修改成 HTTP 500 Internal Server Error
            flow.response = http.Response.make(
                500,  # status code
                b"Internal Server Error",  # response body (byte string)
                {"Content-Type": "text/plain"}  # headers
            )
            return