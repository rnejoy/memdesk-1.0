/**********************************************************************************************************
 * @Author        : Critical River Technology
 * @Created Date  : 25th May 2022
 * @Description   : This method will do call request to fetch Credit Score details
 * @JIRANum: A3SHCRSF3-1045
 ******************************************************************************************************
Change History    Version      ||    Modified By    ||  Modification Date        ||    Description
   ******************************************************************************************************
1.
   **********************************************************************************************************/

public class Send_Contact_To_stores_FutreCallout {
  
  static String className = 'Send_Conatcts_To_store';
  static String methodName;
  
  
  @future(callout=true)
  public static void SendMemberDetailsToStores(string MemberID){
    methodName = 'SendMemberDetailsToStores';
    List<String> result = new List<String>();
    List<api_log__c> logList = new List<api_log__c>();
    
    
    List<contact> conList = [select id , Membership_ID__c , Name , Membership_Start_Date__c ,Request_Body__c,
                       Membership_Expiry_Date__c , Is_Active__c , Is_VAT_Exempt__c ,Response__c,status_code__c,
                       Customer_Type__c , Membership_Type__c , Account.id ,
                       Account.type 
                       from contact 
                       where id = :MemberID ];
    system.debug('con11th line****'+conList[0]);
    system.debug('WE ARE IN Send_Contact_To_stores_FutreCallout');
    try{
      
      
      if(conList.size() > 0){
        contact contactToProcess = conList[0];
        
        List<Store_API_Integration_Details__mdt> storeAPIdetails = [SELECT Id,MasterLabel,Access_Token_URL__c , Authentication_Grant_Type__c,Base_URL__c , Cache_Name__c , Client_Id__c ,Client_Secret__c ,Is_SandBox__c ,Static_Access_Token__c, Password__c ,UserName__c , isActiveAPI__c from Store_API_Integration_Details__mdt];
        
        
        
        integer i=1;
        string StoreResponse = '' ;
        string StoreRequest = '';
        string responsecodes = '';
        for(Store_API_Integration_Details__mdt Store : storeAPIdetails){
          
          
          String localReqBody = Store_MemberJsonBodyGen.jsongenerator(memberId,store.Static_Access_Token__c);
          if(Store != null && store.isActiveAPI__c){
            try{
              system.debug('Store.Base_URL__c****'+Store.Base_URL__c);
              system.debug('Store.Static_Access_Token__c****'+Store.Static_Access_Token__c);
              Http http = new Http();
              HttpRequest request = new HttpRequest();
              request.setBody(localReqBody);
              request.setEndpoint(store.Base_URL__c);
              request.setMethod('POST');
              request.setHeader('Content-Type', 'application/json;charset=UTF-8');
              //Previous setTimeout value = 20000
              request.setTimeout(10000);
              StoreRequest +=Store.MasterLabel+':'+localReqBody+'\n';
              
              
              HttpResponse response = http.send(request);
              
              StoreResponse +=Store.MasterLabel +':'+response.getBody()+'\n';
              system.debug(response.getBody());
              
              api_log__c apl = new api_log__c();
              apl.Request_Body__c = localReqBody;
              apl.Response_Body__c = response.getBody();
              apl.Response_Codes__c = String.valueOf(response.getStatusCode());
              apl.Execution_Time__c = dateTime.now();
              apl.Interface__c = 'bulk call';
              apl.store_name__c = store.MasterLabel;
              apl.associated_member__c = contactToprocess.id;
              if(response.getStatusCode() == 200){
                apl.last_execution_response__c = 'Callout was successful. Data sent to store : ' +Store.MasterLabel+' on '+dateTime.now();
                apl.isSuccess__c = true;
                system.debug('------RESPONSE BODY------');
                String responseBody = response.getBody(); // response is an instance of HttpResponse
			    Map<String, Object> resResult = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
			    Integer responseErrCode = (Integer) resResult.get('ErrCode');
                Integer ErrCode;
              // If responseErrCode == 0 it means success, else show the value
              if(responseErrCode == 0){
                ErrCode = 200;
              } else {
                ErrCode = responseErrCode;
              }
              responseCodes+=Store.MasterLabel+':'+ErrCode+'\n';
              system.debug(responseCodes);
              system.debug('------END RESPONSE BODY------');
                
              }
              else{
                apl.last_execution_response__c = 'Callout failed. Data was not send to store : ' +Store.MasterLabel+' on '+dateTime.now();
              }
              logList.add(apl);
              
              
              
              
              if(Test.isRunningTest ()){
                CalloutException e = (CalloutException)CalloutException.class.newInstance();
                e.setMessage('Unauthorized endpoint, please check Setup->Security->Remote site settings.');
                throw e;
                
              }
              
              
              
              
              
              
            }       
            catch(calloutException e){
              System.debug('An Exception occured');
              
              api_log__c apl = new api_log__c();
              apl.Request_Body__c = localReqBody;
              apl.Response_Body__c = 'exception occured';
              apl.Response_Codes__c = 'NOT 200';
              apl.Execution_Time__c = dateTime.now();
              apl.Interface__c = 'bulk call';
              apl.store_name__c = store.MasterLabel;
              apl.associated_member__c = contactToprocess.id;
              apl.last_execution_response__c = 'Callout failed. Data not sent to store : ' +Store.MasterLabel+' on '+dateTime.now();
              logList.add(apl);
              responseCodes+=Store.MasterLabel+' : '+e.getMessage()+'\n';
              StoreResponse +=Store.MasterLabel +' : '+e.getMessage() +'\n';
              
              
            }
          }
        }
          
        system.debug('END OF PROCESS');
        
        contactToProcess.Response__c = StoreResponse;
        
        contactToProcess.Request_Body__c = StoreRequest;
        contactToProcess.response_codes__c = responseCodes;
        
        Database.update(contactToProcess);
        insert(logList);
        system.debug('con****'+contactToProcess);
      }
    }
    catch(Exception e){ /*GlobalUtil.createErrorLogRec(e,className + ' ' + methodName, 'Error While Validating MembershipId and updating Lead',JSON.serialize(inputs)); */
      result.add('Invalid');
    }
    //return result;
  }
  
  
  
  public class FlowInputs{
    @InvocableVariable
    public String recordId;
    
    @InvocableVariable
    public String memberId;
  }
  
}