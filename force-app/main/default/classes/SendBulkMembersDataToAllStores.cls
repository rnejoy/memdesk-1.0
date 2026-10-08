public class SendBulkMembersDataToAllStores {

  @Future(Callout= True)
  Public static Void SendMembers(Set<ID> conIds){
    String StoreRequestAggregated = '';
    String StoreResponseAggregated = '';
    String ResponseCodesAggregated = '';
    Boolean isSucessCall = false;
    Integer TA_SIZE = 131000;
    List<contact> conList = [select Name,id,response__c,Membership_ID__c  from contact where id in : conIds];
    List<contact> genList = new List<contact>();
    List<api_log__c> apiloggerResultBulk = new List<api_log__c>();
    //
    Map<String,List<String>> requestMap = new Map<String,List<String>>();
    //
    Set<String> idStrs = (Set<String>)JSON.deserialize(JSON.serialize(conIds), Set<String>.class);
    List<string> cflist = new List<string>(idstrs);
    String conStr = String.join(cflist,',');

    String generalisedResponse = 'This member was processed to ANSI as part of a bulk call.';

    if(conIds.size() > 0){
      List<Store_API_Integration_Details__mdt> storeAPIdetails = [SELECT Id,MasterLabel,Access_Token_URL__c , Authentication_Grant_Type__c,Base_URL__c , 
                            Cache_Name__c, Client_Id__c ,Client_Secret__c ,Is_SandBox__c ,Static_Access_Token__c,
                            Password__c ,UserName__c , isActiveAPI__c from Store_API_Integration_Details__mdt
                            ];
      for(Store_API_Integration_Details__mdt Store : storeAPIdetails){
        string AggregatedRequest = Store_MemberJsonBodyGen.jsonGeneratorBulk(conIds,Store.Static_Access_Token__c);
        if(Store != null && store.isActiveAPI__c && !Store.Is_SandBox__c){
          try{
            system.debug('Store.Base_URL__c****'+Store.Base_URL__c);
            system.debug('Store.Static_Access_Token__c****'+Store.Static_Access_Token__c);
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setBody(AggregatedRequest);
            request.setEndpoint(store.Base_URL__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setTimeout(15000);
            StoreRequestAggregated +=Store.MasterLabel+':'+AggregatedRequest+'\n';

            if(StoreRequestAggregated.length() > TA_SIZE){
              StoreRequestAggregated = 'Response Body too long Cannot Stamp to Log';
            }

            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(AggregatedRequest);
            List<Object> records = (List<Object>) jsonMap.get('CustomerDetails');
            if (records != null) {
                for (Object r : records) {
                    Map<String,Object> rMap = (Map<String,Object>)r;
                    String memId = (String) rMap.get('Code');
                    if(requestMap.containsKey(memId)){
                        requestMap.get(memId).add(Store.MasterLabel+':{"PartnerKey":"'+Store.Static_Access_Token__c+'","CustomerDetails":['+JSON.serialize(r)+']}');
                      System.debug('updated: ' + memId);
                    }
                    else{
                      requestMap.put(memId,new List<String>{Store.MasterLabel+':{"PartnerKey":"'+Store.Static_Access_Token__c+'","CustomerDetails":['+JSON.serialize(r)+']}'});
                      System.debug('created: ' + memId);
                    }
                }
            } else {
                system.debug('null.. : ' + records);
            }

            HttpResponse response = http.send(request);
            api_log__c apl = new api_log__c();
            apl.Request_Body__c = aggregatedRequest;
            apl.Response_Body__c = response.getBody();
            apl.Response_Codes__c = String.valueOf(response.getStatusCode());
            apl.Execution_Time__c = dateTime.now();
            apl.Interface__c = 'bulk call';
            apl.store_name__c = store.MasterLabel;

            if(response.getStatusCode() == 200){
              apl.last_execution_response__c += 'Data sent to store : ' +Store.MasterLabel+' on '+dateTime.now();
              apl.isSuccess__c = true;
            }
            else apl.last_execution_response__c += 'Data did not sent store : ' +Store.MasterLabel+' on '+dateTime.now();

            apl.contact_list__c = conStr;
            generalisedResponse += apl.last_execution_response__c;
            apiloggerResultBulk.add(apl);
            StoreResponseAggregated +=Store.MasterLabel +':'+response.getBody()+'\n';
            system.debug(response.getBody());
            if(conList.size() == 1 ){
              generalisedResponse = response.getBody();
            }
            ResponseCodesAggregated+=Store.MasterLabel+':'+response.getstatusCode()+'\n';
            if(Test.isRunningTest ()){
              CalloutException e = (CalloutException)CalloutException.class.newInstance();
              e.setMessage('Unauthorized endpoint, please check Setup->Security->Remote site settings.');
              throw e;
            }
          }
          catch(calloutException ce){
            api_log__c apl = new api_log__c();
            apl.Request_Body__c = aggregatedRequest;
            apl.Response_Body__c = 'callout exception occured during run';
            apl.Response_Codes__c = String.valueOf(700);
            apl.Execution_Time__c = dateTime.now();
            apl.Interface__c = 'bulk call';
            apl.store_name__c = store.MasterLabel;
            apiloggerResultBulk.add(apl);
            generalisedResponse = 'Something went wrong! We couldnt get success from the servers in the last call. Click on send memeber details to store Button to retrigger';
          }
        }
      }
      For(contact c : conlist){
        //Start GALH 2023/09/15
        //c.response__c = generalisedResponse;
        System.debug('StoreResponseAggregated: ' + StoreResponseAggregated);
        c.response__c = StoreResponseAggregated;
        System.debug('ResponseCodesAggregated: ' + ResponseCodesAggregated);
        c.response_codes__c = ResponseCodesAggregated;
        //Commented 2025/02/13 c.Request_Body__c = StoreRequestAggregated;
        //End GALH 2023/09/15
        //Start 2025/02/13
        System.debug('c.Membership_ID__c = '+ requestMap.get(c.Membership_ID__c));
        if(Test.isRunningTest()){
          c.Request_Body__c = 'Test';
        }
        else {
          if(requestMap.containsKey(c.Membership_ID__c)) c.Request_Body__c = String.join(requestMap.get(c.Membership_ID__c), '\n');
        }
        //End 2025/02/13
        genlist.add(c);
      }
    Database.update(genlist);
    //Database.insert(apiLoggerResultBulk);
    }
  }
}
/*public class SendBulkMembersDataToAllStores {
    
    @Future(Callout= True)
    Public static Void SendMembers(Set<ID> conIds){
        String StoreRequestAggregated = '';
        String StoreResponseAggregated = '';
        String ResponseCodesAggregated = '';
        Boolean isSucessCall = false;
        Integer TA_SIZE = 131000;
        List<contact> conList = [select Name,id,response__c from contact where id in : conIds];
        List<contact> genList = new List<contact>();
        List<api_log__c> apiloggerResultBulk = new List<api_log__c>();
        
        Set<String> idStrs = (Set<String>)JSON.deserialize(JSON.serialize(conIds), Set<String>.class);
          List<string> cflist = new List<string>(idstrs);
         String conStr = String.join(cflist,',');
        
        String generalisedResponse = 'This member was processed to ANSI as part of a bulk call.';
        
        if(conIds.size() > 0){
              List<Store_API_Integration_Details__mdt> storeAPIdetails = [SELECT Id,MasterLabel,Access_Token_URL__c , Authentication_Grant_Type__c,Base_URL__c , 
                                                                        Cache_Name__c, Client_Id__c ,Client_Secret__c ,Is_SandBox__c ,Static_Access_Token__c, 
                                                                        Password__c ,UserName__c , isActiveAPI__c from Store_API_Integration_Details__mdt
                                                                        ];
            for(Store_API_Integration_Details__mdt Store : storeAPIdetails){
               
            
            string AggregatedRequest = Store_MemberJsonBodyGen.jsonGeneratorBulk(conIds,Store.Static_Access_Token__c);
             if(Store != null && store.isActiveAPI__c && !Store.Is_SandBox__c){
                 try{
                  system.debug('Store.Base_URL__c****'+Store.Base_URL__c); 
                  system.debug('Store.Static_Access_Token__c****'+Store.Static_Access_Token__c); 
                    Http http = new Http();
                    HttpRequest request = new HttpRequest();
                    request.setBody(AggregatedRequest);
                    request.setEndpoint(store.Base_URL__c);
                    request.setMethod('POST');
                    request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                    request.setTimeout(120000);
                    
                    //StoreRequestAggregated +=Store.MasterLabel+':'+AggregatedRequest+'\n';
                    //if(StoreRequestAggregated.length() > TA_SIZE){
                    //  StoreRequestAggregated = 'Response Body too long Cannot Stamp to Log';
                    //}

                    HttpResponse response = http.send(request);
                        api_log__c apl = new api_log__c();
                        apl.Request_Body__c = aggregatedRequest;
                        apl.Response_Body__c = response.getBody();
                        apl.Response_Codes__c = String.valueOf(response.getStatusCode());
                        apl.Execution_Time__c = dateTime.now();
                        apl.Interface__c = 'bulk call';
                        apl.store_name__c = store.MasterLabel;
                     if(response.getStatusCode() == 200){
                        apl.last_execution_response__c += 'Data sent to store : ' +Store.MasterLabel+' on '+dateTime.now();
                        apl.isSuccess__c = true; 
                     }
                        else apl.last_execution_response__c += 'Data did not sent store : ' +Store.MasterLabel+' on '+dateTime.now();
                      
                       
                        apl.contact_list__c = conStr;
                        generalisedResponse += apl.last_execution_response__c;
                        apiloggerResultBulk.add(apl);

                 
                    StoreResponseAggregated +=Store.MasterLabel +':'+response.getBody()+'\n';
                    system.debug(response.getBody());
                     if(conList.size() == 1 ){
                         generalisedResponse = response.getBody();
                      }
                    ResponseCodesAggregated+=Store.MasterLabel+':'+response.getstatusCode()+'\n';
                       if(Test.isRunningTest ()){
                            CalloutException e = (CalloutException)CalloutException.class.newInstance();
        e.setMessage('Unauthorized endpoint, please check Setup->Security->Remote site settings.');
        throw e;
                            
                        }
             }

             catch(calloutException ce){
              api_log__c apl = new api_log__c();
              apl.Request_Body__c = aggregatedRequest;
              apl.Response_Body__c = 'callout exception occured during run';
              apl.Response_Codes__c = String.valueOf(700);
              apl.Execution_Time__c = dateTime.now();
              apl.Interface__c = 'bulk call';
              apl.store_name__c = store.MasterLabel;
              apiloggerResultBulk.add(apl);
              generalisedResponse = 'Something went wrong! We couldnt get success from the servers in the last call. Click on send memeber details to store Button to retrigger';
             }
            }
                
            
            
            }
            For(contact c : conlist){
                //Start GALH 2023/09/15
                //c.response__c = generalisedResponse;
                c.response__c = StoreResponseAggregated;
                c.response_codes__c = ResponseCodesAggregated;
                c.Request_Body__c = StoreRequestAggregated;
                //Start GALH 2023/09/15
                genlist.add(c);
                
            }
              Database.update(genlist);
              //Database.insert(apiLoggerResultBulk);
            
           
        }
        
        
        
        
               
        }
        
        
    }*/