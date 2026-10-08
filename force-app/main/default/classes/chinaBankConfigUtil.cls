public with sharing class chinaBankConfigUtil {
    public class Config {
        public String clientId;
        public String clientSecret;
        public String scope;
        public String tokenUrl;
        public String pushUrl;
        public String getResultUrl;
    }

    public static Config getConfig() {
        List<Chinabank_API_Setting__mdt> mdList = [
            SELECT Client_Id__c, Client_Secret__c, Scope__c,
                   Token_Url__c, Push_Url__c, GetResult_Url__c
            FROM Chinabank_API_Setting__mdt
            LIMIT 1
        ];
        if (mdList.isEmpty()) {
            throw new AuraHandledException('ChinaBank config not found in Custom Metadata.');
        }

        Chinabank_API_Setting__mdt md = mdList[0];
        Config cfg = new Config();
        cfg.clientId = md.Client_Id__c;
        cfg.clientSecret = md.Client_Secret__c;
        cfg.scope = md.Scope__c;
        cfg.tokenUrl = md.Token_Url__c;
        cfg.pushUrl = md.Push_Url__c;
        cfg.getResultUrl = md.GetResult_Url__c;
        return cfg;
    }
}