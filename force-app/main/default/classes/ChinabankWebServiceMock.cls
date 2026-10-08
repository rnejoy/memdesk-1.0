@IsTest
global class ChinabankWebServiceMock implements WebServiceMock {
    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseName,
        String responseNamespace,
        String requestNamespace
    ) {
        response.put('result', 'SUCCESS');
    }
}