public class apiErrorHandler {
    public static void deleteSuccessLogs(){
         List<api_log__c> apiLogList = [select 	Response_Codes__c, execution_time__c , id , isSuccess__c from api_log__c];
         
         List<api_log__c> delList = new List<api_log__c>();
        for(api_log__c delApi : apiLogList){
            if(delApi.response_codes__c == '200' && delApi.isSuccess__c){
                delList.add(delApi);
            }
        }
            if(delList.size() > 0){
                database.delete(delList);
            }
        }
    
    public static void updateContactsPostCalloutSingle(){
        List<contact> contactsUpdate = new List<contact>();
        Set<contact> updateSet = new Set<contact>();
        List<api_log__c> listLogs = [select id,response_codes__c,contact_list__c,associated_member__c,execution_time__c, response_body__c , last_execution_response__c,store_name__c , isSuccess__c from api_log__c];
        List<Id> contactIds = new List<Id>();
        for(api_log__c apl : listLogs){
           
                if(apl.Associated_Member__c != null){
                   contactIds.add(apl.Associated_Member__c);
                    }
        
            
            
        
        List<contact> contactUpdate =  [select id,name,response__c,response_codes__c from contact where id IN : contactIds];
        for(contact c : contactUpdate){
            c.Response__c = '';
            if(apl.isSuccess__c == true){
            c.response__c += 'Response from store : '+Apl.store_name__c+' was successful';
        }
            else
            {
                c.response__c += 'Response from store : '+Apl.store_name__c+'  on '+DateTime.now()+' was failure';
            }
  
        } 
           Set<contact> intermediateContactSet = new Set<contact>(contactUpdate);
           updateSet.addAll(intermediateContactSet);            
        
    }
    List<contact> finalUpdateList = new List<contact>(updateSet);
    if(finalUpdateList.size() > 0){
        database.update(finalUpdateList);
    }
    }
    
    
    
    
    public static void updateContactsPostCalloutBulk(){
        List<api_log__c> listLogs = [select id,response_codes__c,contact_list__c,associated_member__c,execution_time__c, response_body__c , last_execution_response__c,store_name__c , isSuccess__c from api_log__c];
        map<id,list<api_log__c>> apiContactMap = new map<id,list<api_log__c>>();
 
        
        string contactListSuccess;
        string contactListfailure;
        List<contact> updateBulkContacts = new List<contact>();
         List<string> conList = new List<string>();
         List<contact> contactUpdate =  [select id,name,response__c,response_codes__c from contact where id IN :conList];
        Map<id,contact> contactUpdateMap = new Map<id,Contact>();
            
        for(api_log__c apl : listLogs){
           
                if(apl.contact_list__c != null){
                    contactListSuccess+=apl.contact_list__c;
                }
            
            if(contactListSuccess != null){
        conList = contactListSuccess.split(',');
                
                
       
        for(contact c : contactUpdate){
            c.response__c = '';
               if(apl.isSuccess__c == true){
            c.response__c += 'Response from store : '+Apl.store_name__c+' was successful';
        }
            else
            {
                c.response__c += 'Response from store : '+Apl.store_name__c+'  on '+DateTime.now()+' was failure';
            }
        }
            
            
        updateBulkContacts.addAll(contactUpdate);
        
            }
    }
       if(updateBulkContacts.size() > 0){
        database.update(updateBulkContacts);
       }
    }
    
        
     
                
    @future(callout=true)
    public static void retriggerFailed(){
        
         List<api_log__c> apiLogList = [select 	Response_Codes__c, request_body__c, execution_time__c , id , store_name__c , associated_member__c , contact_list__c , last_execution_response__c , isSuccess__c from api_log__c where isSuccess__c = false LIMIT 75];
         System.debug('log-list to process'+apiLogList);
         List<api_log__c> delList = new List<api_log__c>();
         List<contact> contactsToUpdate = new List<contact>();
         Set<string> metaDataStoreNames = new set <String>(); 
          List<api_log__c> updateApiLogs = new List<api_log__c>();
          
         
        for(api_log__c apl : apiLogList){
            metaDataStoreNames.add(apl.store_name__c);
        }
        System.debug('md-s-name'+metaDataStoreNames);
         List<Store_API_Integration_Details__mdt> storeAPIdetails = [SELECT Id,MasterLabel,Access_Token_URL__c , Authentication_Grant_Type__c,Base_URL__c , 
                                                                        Cache_Name__c, Client_Id__c ,Client_Secret__c ,Is_SandBox__c ,Static_Access_Token__c, 
                                                                        Password__c ,UserName__c , isActiveAPI__c from Store_API_Integration_Details__mdt
                                                                        where MasterLabel IN :metaDataStoreNames];   
        System.debug('metadata fetched :'+storeAPIdetails);
        
        
        
        
         
        for(api_log__c delApi : apiLogList){
            
             for(Store_API_Integration_Details__mdt Store : storeAPIdetails){
           if(Store != null && store.isActiveAPI__c && store.masterLabel == delApi.store_name__c && delApi.isSuccess__c == false){ 
               System.debug('store fetched : '+Store);
               try{
                    Http http = new Http();
                    HttpRequest request = new HttpRequest();
                    request.setBody(delApi.Request_Body__c);
                    request.setEndpoint(store.Base_URL__c);
                    request.setMethod('POST');
                    request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                    request.setTimeout(20000);
                    HttpResponse response = http.send(request);
                    delApi.Response_Codes__c = String.valueof(response.getStatusCode());
               if(response.getStatusCode() == 200){
                   delApi.last_execution_response__c = '/n Callout was successful. Data sent to store : ' +Store.MasterLabel+' on '+dateTime.now();
                   delApi.isSuccess__c = true;
                   delApi.Response_Body__c = '\n'+DateTime.now()+':'+response.getBody();
               }
               else {
                   delApi.last_execution_response__c = '/n Callout failed. Data was not send to store : ' +Store.MasterLabel+' on '+dateTime.now();
               }
            }

            catch(calloutException e){
                System.debug('An exception occured');
                delApi.last_execution_response__c = '/n Callout failed. Data was not send to store : ' +Store.MasterLabel+' on '+dateTime.now();

            }
              
              
                    delApi.execution_time__c = dateTime.now();
                    
                    updateApiLogs.add(delApi);


                     
                     
               
        
       
}
}
        } database.update(updateApiLogs);
         
          updateContactsPostCalloutSingle1();
          updateContactsPostCalloutBulk();
         deleteSuccessLogs();
       
        
        
        
    }

    public static void updateContactsPostCalloutSingle1(){
        List<contact> contactsUpdate = new List<contact>();
        Set<contact> updateSet = new Set<contact>();
        List<api_log__c> listLogs = [select id,response_codes__c,contact_list__c,associated_member__c,execution_time__c, response_body__c , last_execution_response__c,store_name__c , isSuccess__c from api_log__c];
        List<Id> contactIds = new List<Id>();
        map<id,contact> contactMap = new map<id,contact>();
        for(api_log__c apl : listLogs){
           
                if(apl.Associated_Member__c != null){
                   contactIds.add(apl.Associated_Member__c);
                    }
        
                }

                List<contact> contactUpdate =  [select id,name,response__c,response_codes__c from contact where id IN : contactIds];

        //generate map
               for(contact c : contactUpdate){
                contactMap.put(c.id,c);
               }
 

          for(api_log__c apl : listLogs){

            if(apl.associated_member__c != null){

            contact c = contactMap.get(apl.associated_member__c);

             if(apl.isSuccess__c == true){
            c.response__c += 'Response from store : '+Apl.store_name__c+' was successful';
        }
            else
            {
                c.response__c += 'Response from store : '+Apl.store_name__c+'  on '+DateTime.now()+' was failure';
            }

            contactMap.put(apl.associated_member__c,c);
         
        }
    }

        //update database with new values 
        List<contact> dbCommitList = new List<contact>();
        dbCommitList = contactMap.values();
        if(dbCommitList.size() > 0){
           database.update(dbCommitList);
        }



       




}
        
    
    

}