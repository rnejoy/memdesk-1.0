@IsTest
global class ChinabankHttpMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        String endpoint = req.getEndpoint();

        /* ================= TOKEN ================= */
        if (endpoint.contains('/GetToken')) {
            res.setStatusCode(200);
            res.setBody('{"access_token":"mockToken123","expires_in":3600}');
            return res;
        }

        /* ================= PUSH ================= */
        if (endpoint.contains('/landerspushappdtl')) {
            res.setStatusCode(200);

            // 🔹 fake encrypted payload (base64 of plain JSON)
            String fakeEncrypted =
                EncodingUtil.base64Encode(
                    Blob.valueOf(
                        '{"responseHeader":{"responseContext":{"providerReferenceNumber":"APP123"}}}'
                    )
                );

            res.setBody(
                '{ "body": { "responseData": "' + fakeEncrypted + '" }}'
            );
            return res;
        }

        /* ================= GET RESULT ================= */
        if (endpoint.contains('/landersgetresult')) {
            res.setStatusCode(200);

            String fakeEncrypted =
                EncodingUtil.base64Encode(
                    Blob.valueOf(
                        '{"responseBody":{"result":"APPROVED"}}'
                    )
                );

            res.setBody(
                '{ "body": { "responseData": "' + fakeEncrypted + '" }}'
            );
            return res;
        }

        /* ================= SAFETY NET ================= */
        res.setStatusCode(500);
        res.setBody('{"error":"Unhandled endpoint: ' + endpoint + '"}');
        return res;
    }
}