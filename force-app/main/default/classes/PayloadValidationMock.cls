@isTest
global class PayloadValidationMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        
        // Deserialize the request body to get the parameters
        Map<String, Object> requestParams = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
        String membershipId = (String) requestParams.get('membershipId');
        String lastName = (String) requestParams.get('lastName');
        String dobString = (String) requestParams.get('dobString');
        
        // Log the incoming parameters
        System.debug('Mock request params: ' + requestParams);

        // Mock different responses based on the input parameters
        if (membershipId == '12345678901234' && lastName == 'Smith' && dobString == '1990-01-01') {
            res.setStatusCode(404);
            res.setBody('{"error":{"code":"404","description":"Record not found"}}');
        } else if (membershipId == '123' || membershipId == null) {
            res.setStatusCode(400);
            res.setBody('{"error":{"code":"400","description":"Invalid membership ID"}}');
        } else if (dobString == '1990-31-01') {
            res.setStatusCode(400);
            res.setBody('{"error":{"code":"400","description":"Invalid date format"}}');
        } else {
            res.setStatusCode(200);
            res.setBody('{"status":"Success"}');
        }
        
        return res;
    }
}