@isTest
public class ChinabankAPIMock implements HttpCalloutMock {
    
    public static final String SUCCESS_ENCRYPTED = '{"body": {"responseData": "SUCCESS_ENCRYPTED_DATA_HERE"}}';
    public static final String TOKEN_RESPONSE_BODY = '{"access_token": "NEW_MOCKED_TOKEN", "expires_in": 3600}';
    
    private Integer statusCode;
    private String status;
    private String responseBody;
    
    public ChinabankAPIMock(Integer status, String body) {
        this.statusCode = status;
        this.status = 'Status ' + status;
        this.responseBody = body;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        
        if (req.getEndpoint().contains('token') || req.getEndpoint().contains('oauth')) {
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody(TOKEN_RESPONSE_BODY);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }

        res.setStatusCode(this.statusCode);
        res.setStatus(this.status);
        res.setBody(this.responseBody);
        res.setHeader('Content-Type', 'application/json');
        return res;
    }
}