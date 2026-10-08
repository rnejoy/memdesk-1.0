public class SMS_SendTestMessage {
    public String mbId;
    public String messageType {get; set;}
    public String messageBody;
    public String sendResult  {get; set;}

    public String custom1 {get; set;}
    public String custom2 {get; set;}
    public String custom3 {get; set;}
    public String custom4 {get; set;}
    public String custom5 {get; set;}
    public String moblstr {get; set;}

    public SMS_SendTestMessage() {
        mbId = ApexPages.currentPage().getParameters().get('id');
        System.Debug('mbId :>> ' + mbId);
        SMS_Template__c temp = [SELECT Message_Body__c, Message_Type__c FROM SMS_Template__c WHERE Id =: mbId];
        messageType = temp.Message_Type__c;
        messageBody = temp.Message_Body__c;
        sendResult  = '';
    }

    public void sendSMS() {
        System.Debug('messageType :>> ' + messageType);
        System.Debug('custom1 :>> ' + custom1);
        System.Debug('moblstr :>> ' + moblstr);

        String url = 'https://messagingsuite.smart.com.ph/cgphttp/servlet/sendmsg';
        String messageText = messageBody;
        sendResult = '';

        if (messageType == 'P')
            messageText = messageText.replace('<custom1>', custom1).replace('<custom2>', custom2).replace('<custom3>', custom3).replace('<custom4>', custom4).replace('<custom5>', custom5);

        List<String> arrMob = moblstr.split(',');
        for (Integer i=0; i<arrMob.size(); i++) {
            System.Debug('mobileno :>> ' + arrMob[i]);
            String mobileno = (arrMob[i]).trim();
            if (mobileno != '') {
                String params = '&destination=' + mobileno +
                                '&text=' + EncodingUtil.urlEncode(messageText, 'UTF-8');
                String res = httpReq(url, params);
                sendResult += (res.replace('\r\n', ' ') + '; ');
                System.Debug('sendResult :>> ' + sendResult);
            }
        }

        SMS_Template__c temp = [SELECT Id FROM SMS_Template__c WHERE Id =: mbId];
        temp.Is_Tested__c = true;
        update temp;
    }

    private static String httpReq(String url, String params) {
        Blob headerValue = Blob.valueOf('lndsysad@landers.ph:0T!sLNdr');
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', authorizationHeader);
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setBody(params);
        HttpResponse res = h.send(req);

        return res.getBody();
    }
}