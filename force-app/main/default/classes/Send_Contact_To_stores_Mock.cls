@isTest
global class Send_Contact_To_stores_Mock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
       
        response.setHeader('Content-Type', 'application/json;charset=UTF-8');
        response.setBody('{"ErrCode":0,"ErrMsg":"Success","time":"2022-07-08T10:21:03.187Z"};');
       
        response.setStatusCode(200);
        return response; 
    }
}