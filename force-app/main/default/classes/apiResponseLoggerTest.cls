@isTest
public class apiResponseLoggerTest {
     static testMethod void testLogger(){
    APIResponseLogger.ApiLoggerBulk('test','test','200','bulk',dateTime.now(),'bulk Job');
    APIResponseLogger.ApiLoggerMember('test','test','200','bulk', dateTime.now(),'0035h00000mePMiAAM','bulk Job');
     }
    

}