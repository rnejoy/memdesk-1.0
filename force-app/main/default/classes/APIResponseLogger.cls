public class APIResponseLogger {
    public static void ApiLoggerBulk(String calloutBody , String calloutResponse , String calloutStatus , String Interfacename , DateTime execTime ,string calltype){
        API_log__c apilog = new API_log__c();
                apilog.request_body__c = calloutBody;
                apilog.response_body__c = calloutResponse;
                apilog.response_codes__c = calloutStatus;
                apilog.execution_time__c = execTime;
                apilog.interface__c = Interfacename;
                apilog.Trigger_Type__c = calltype;
                insert apilog;
                System.debug('Api log is created');
    }
    
     public static void ApiLoggerMember(String calloutBody , String calloutResponse , String calloutStatus , String Interfacename , DateTime execTime , Id memId , String callType){
        API_log__c apilog = new API_log__c();
                apilog.request_body__c = calloutBody;
                apilog.response_body__c = calloutResponse;
                apilog.response_codes__c = calloutStatus;
                apilog.execution_time__c = execTime;
                apilog.interface__c = Interfacename;
                apilog.associated_member__c = memId;
                apilog.Trigger_Type__c = calltype;
                insert apilog;
                System.debug('Api log is created');
    }

}