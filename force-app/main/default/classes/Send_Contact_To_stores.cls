public class Send_Contact_To_stores {
    
    static String className = 'Send_Conatcts_To_store';
    static String methodName;  
    /* 

* @methodname: SendMemberDetailsToStores
* @description: This method is send deatils to Store by doing API call to external system and updates contacts/Member
*               based on response
* @param: #inputs- It's the flowinputs which will have ConatctID  and MembershipId
* @return: Returns the response based on API Response
*/
   @InvocableMethod
    public static List<String> SendMemberDetailsToStores(List<FlowInputs> inputs){
        
        methodName = 'SendMemberDetailsToStores';
        List<String> result = new List<String>();  
        system.debug('outside try inputs[0].recordId****'+inputs[0].recordId);
        try{            
            if(inputs != null && inputs.size() > 0){
                system.debug('inputs[0].recordId****'+inputs[0].recordId);
                Send_Contact_To_stores_FutreCallout.SendMemberDetailsToStores( inputs[0].recordId);
            }
        }
        catch(Exception e){ //GlobalUtil.createErrorLogRec(e,className + ' ' + methodName, 'Error While Validating MembershipId and updating Lead',JSON.serialize(inputs)); 
        System.debug('An exception was encountered');
            
        }
        result.add('Processed');
        return result;
    }
    
    public class FlowInputs{
        @InvocableVariable
        public String recordId;
        
        @InvocableVariable
        public String memberId;
    }
}