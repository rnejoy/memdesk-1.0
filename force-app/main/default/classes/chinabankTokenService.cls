public with sharing class chinabankTokenService {

    @TestVisible
	private static Boolean bypassTestToken = false;
    
    public static API_Access_Token__c getTokenRecord() {
        
        if (Test.isRunningTest() && !bypassTestToken) {
            return new API_Access_Token__c(
                Access_Token__c = 'TEST_TOKEN',
                Token_Expiry__c = Decimal.valueOf(
                    DateTime.now().addHours(1).getTime() / 1000
                )
            );
        }
        
        return [
            SELECT Id, Access_Token__c, Token_Expiry__c 
            FROM API_Access_Token__c 
            WHERE Service_Name__c = 'Chinabank' 
            LIMIT 1
        ];
    }
    
    public static String getAccessToken() {
        
       if (Test.isRunningTest() && !bypassTestToken) {
            return 'TEST_TOKEN';
       }
        
        API_Access_Token__c token = getTokenRecord();
        Long nowTs = DateTime.now().getTime() / 1000;
        if (token.Token_Expiry__c == null || token.Token_Expiry__c <= nowTs) {
            return null; 
        }
        return token.Access_Token__c;
    }
}