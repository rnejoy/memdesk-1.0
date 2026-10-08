@isTest
global class send_Contacts_To_Stores_Mock_Failure implements HttpCalloutMock {
   
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
       
        response.setHeader('Content-Type', 'application/json;charset=UTF-8');
        response.setBody('{"ErrCode":0,"ErrMsg":"Success","time":"2022-07-08T10:21:03.187Z"};');
       
        response.setStatusCode(500);
        return response; 
    
}

}