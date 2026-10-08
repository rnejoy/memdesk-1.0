/**
 * @author : Anoori Muhammed / Satish Lokinindi
 * @date : 15-01-2022
 * @description : Helper For CaseTrigger
 * @last modified on  : 01-02-2022
 * @last modified by  : Anoori Muhammed / Satish Lokinindi
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0  15-01-2022   Anoori Muhammed   Initial Version
**/
public with sharing class CaseTriggerHelper {


/***********************************************************************************************
  @author : Satish Lokinindi
 * @description : Method to send email notification on escalation.
 **********************************************************************************************/
   //Commenting code as client doesnt require this feature.
   /* public static void sendEscalationEmail(List<Case> newCaseList,Map<Id,Case> oldCaseMap){
        list<case> caseList = new list<case>();
        for(case cs :newCaseList){
        if(cs.Escalated__c !=oldCaseMap.get(cs.Id).Escalated__c && cs.Escalated__c){
            if(cs.Escalate_To__c!=oldCaseMap.get(cs.Id).Escalate_To__c ){
            caseList.add(cs);
            }
        }
        }
        if(caseList.size()>0){
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Escalation'];
                for(case cs : caseList){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    
                    Fulfillment_Team__c mc = Fulfillment_Team__c.getValues(cs.Escalate_To__c);
                    sendTo.add(mc.Email__c );
                    mail.setToAddresses(sendTo);
                    mail.setReplyTo('no-reply@landers.com');
                    mail.setSenderDisplayName('TeamLanders');
                    mail.setTargetObjectId(cs.ContactId);
                    mail.setTemplateID(emailTemplate.Id); 
                    mail.setWhatId(cs.Id);
                    mail.setUseSignature(false); 
                    mail.setBccSender(false); 
                    mail.setSaveAsActivity(false); 
                    mails.add(mail);
                }
            
            Messaging.sendEmail(mails);
        }
    }*/

/***********************************************************************************************
  @author : Anoori Muhammed
 * @description : Method to change the case status to active.
 **********************************************************************************************/
/*
 public static void changeCaseStatus(List<Case> newCaseList,Map<Id,Case> oldCaseMap){

    Id tcktManagerQueue = [SELECT Id,
                                    Name,
                                    DeveloperName
                                    FROM Group where Type = 'Queue'
                                    AND DeveloperName='Ticket_manager'].Id;
    
    Set<Id> ownerIdSet = new Set<Id>();
    for(Case cs : newCaseList){
        ownerIdSet.add(cs.OwnerId);
    }
    Map<Id,User> userMap = new Map<Id,User>([SELECT Id,
                                                    UserRole.DeveloperName
                                                FROM User WHERE Id = :ownerIdSet]);
    
    for(Case cs : newCaseList){
         if(cs.Status == 'New' && oldCaseMap.get(cs.Id).OwnerId != cs.OwnerId){
            if(((userMap != null 
                    && userMap.get(cs.OwnerId)!=null 
                    && userMap.get(cs.OwnerId).UserRole != null 
                    && userMap.get(cs.OwnerId).UserRole.DeveloperName != 'Ticket_Manager'))){ 
                    cs.Status = 'Active';
            }
            else if( userMap == null && cs.OwnerId != tcktManagerQueue){
                cs.Status = 'Active';
            }
        }
    }
 }
*/
 /***********************************************************************************************
  @author : Anoori Muhammed
 * @description : Method to change the case priority based on case reason
 **********************************************************************************************/

 public static void updateCasePriority(List<Case> newCaseList){
    
    // Added Reason for Critical 19/07/2022
    Set<String> criticalPrioLevel1Reasons = new Set<String>();
    Set<String> criticalPrioLevel2Reasons = new Set<String>();
    Set<String> criticalPrioLevel3Reasons = new Set<String>();
    // end
    Set<String> highPrioLevel1Reasons = new Set<String>();
    Set<String> highPrioLevel2Reasons = new Set<String>();
    Set<String> highPrioLevel3Reasons = new Set<String>();
    Set<String> lowPrioLevel1Reasons = new Set<String>();
    Set<String> lowPrioLevel2Reasons = new Set<String>();
    Set<String> lowPrioLevel3Reasons = new Set<String>();
    Set<String> mediumPrioLevel1Reasons =  new Set<String>();
    Set<String> mediumPrioLevel2Reasons =  new Set<String>();
    Set<String> mediumPrioLevel3Reasons =  new Set<String>();

    // Added Reason for Critical 19/07/2022
    List<Case_Critical_Priority_Level_1_Reasons__c> criticalPrioLevel1ValuesList =  Case_Critical_Priority_Level_1_Reasons__c.getall().values();
    List<Case_Critical_Priority_Level_2_Reasons__c> criticalPrioLevel2ValuesList =  Case_Critical_Priority_Level_2_Reasons__c.getall().values();
    List<Case_Critical_Priority_Level_3_Reasons__c> criticalPrioLevel3ValuesList =  Case_Critical_Priority_Level_3_Reasons__c.getall().values();
    // End
    List<Case_High_Priority_Level1_Reasons__c> highPrioLevel1ValuesList =  Case_High_Priority_Level1_Reasons__c.getall().values();
    List<Case_High_Priority_Level2_Reasons__c> highPrioLevel2ValuesList = Case_High_Priority_Level2_Reasons__c.getall().values();
    List<Case_High_Priority_Level3_Reasons__c> highPrioLevel3ValuesList =  Case_High_Priority_Level3_Reasons__c.getall().values();
    List<Case_Low_Priority_Level1_Reasons__c> lowPrioLevel1ValuesList =  Case_Low_Priority_Level1_Reasons__c.getall().values();
    List<Case_Low_Priority_Level2_Reasons__c> lowPrioLevel2ValuesList =  Case_Low_Priority_Level2_Reasons__c.getall().values();
    List<Case_Low_Priority_Level3_Reasons__c> lowPrioLevel3ValuesList =  Case_Low_Priority_Level3_Reasons__c.getall().values();
    List<Case_Medium_Priority_Level1_Reasons__c> mediumPrioLevel1ValuesList =  Case_Medium_Priority_Level1_Reasons__c.getall().values();
    List<Case_Medium_Priority_Level2_Reasons__c> mediumPrioLevel2ValuesList =  Case_Medium_Priority_Level2_Reasons__c.getall().values();
    List<Case_Medium_Priority_Level3_Reasons__c> mediumPrioLevel3ValuesList =  Case_Medium_Priority_Level3_Reasons__c.getall().values();

    // Added Reason for Critical 19/07/2022
    for(Case_Critical_Priority_Level_1_Reasons__c eachRecord : criticalPrioLevel1ValuesList){
        criticalPrioLevel1Reasons.add(eachRecord.Level_1_Value__c);
    }
    for(Case_Critical_Priority_Level_2_Reasons__c eachRecord : criticalPrioLevel2ValuesList){
        criticalPrioLevel2Reasons.add(eachRecord.Level_2_Value__c);
    }
    for(Case_Critical_Priority_Level_3_Reasons__c eachRecord : criticalPrioLevel3ValuesList){
        criticalPrioLevel3Reasons.add(eachRecord.Level_3_Value__c);
    }
    // end
    for(Case_High_Priority_Level1_Reasons__c eachRecord : highPrioLevel1ValuesList){
        highPrioLevel1Reasons.add(eachRecord.Level_1_Value__c);
    }
    for(Case_High_Priority_Level2_Reasons__c eachRecord : highPrioLevel2ValuesList){
        highPrioLevel2Reasons.add(eachRecord.Level_2_Value__c);
    }
    for(Case_High_Priority_Level3_Reasons__c eachRecord : highPrioLevel3ValuesList){
        highPrioLevel3Reasons.add(eachRecord.Level_3_Value__c);
    }
    for(Case_Low_Priority_Level1_Reasons__c eachRecord : lowPrioLevel1ValuesList){
        lowPrioLevel1Reasons.add(eachRecord.Level_1_Value__c);
    }
    for(Case_Low_Priority_Level2_Reasons__c eachRecord : lowPrioLevel2ValuesList){
        lowPrioLevel2Reasons.add(eachRecord.Level_2_Value__c);
    }
    for(Case_Low_Priority_Level3_Reasons__c eachRecord : lowPrioLevel3ValuesList){
        lowPrioLevel3Reasons.add(eachRecord.Level_3_Value__c);
    }
    for(Case_Medium_Priority_Level1_Reasons__c eachRecord : mediumPrioLevel1ValuesList){
        mediumPrioLevel1Reasons.add(eachRecord.Level_1_Value__c);
    }
    for(Case_Medium_Priority_Level2_Reasons__c eachRecord : mediumPrioLevel2ValuesList){
        mediumPrioLevel2Reasons.add(eachRecord.Level_2_Value__c);
    }
    for(Case_Medium_Priority_Level3_Reasons__c eachRecord : mediumPrioLevel3ValuesList){
        mediumPrioLevel3Reasons.add(eachRecord.Level_3_Value__c);
    }
    for(Case cs : newCaseList){
        if(cs.Reason != null && cs.Sub_Type_1__c !=null && cs.Sub_Type_2__c !=null){
            // Added Reason for Critical 19/07/2022
            if( criticalPrioLevel1Reasons.contains(cs.Reason) && criticalPrioLevel2Reasons.contains(cs.Sub_Type_1__c) && criticalPrioLevel3Reasons.contains(cs.Sub_Type_2__c)){
                cs.Priority = 'Critical';
            }
            // end (added else before next if)
            else if( highPrioLevel1Reasons.contains(cs.Reason) && highPrioLevel2Reasons.contains(cs.Sub_Type_1__c) && highPrioLevel3Reasons.contains(cs.Sub_Type_2__c)){
                cs.Priority = 'High';
            }
            else if(mediumPrioLevel1Reasons.contains(cs.Reason) && mediumPrioLevel2Reasons.contains(cs.Sub_Type_1__c) && mediumPrioLevel3Reasons.contains(cs.Sub_Type_2__c)){
                cs.Priority = 'Medium';
            }
            else if(lowPrioLevel1Reasons.contains(cs.Reason) && lowPrioLevel2Reasons.contains(cs.Sub_Type_1__c) && lowPrioLevel3Reasons.contains(cs.Sub_Type_2__c)){
                cs.Priority = 'Low';
            }
        }else if(cs.Reason != null && cs.Sub_Type_1__c !=null){
            // Added Reason for Critical
            if( criticalPrioLevel1Reasons.contains(cs.Reason) && criticalPrioLevel2Reasons.contains(cs.Sub_Type_1__c)){
                cs.Priority = 'Critical';
            }
            // end (added else before next if)
            else if( highPrioLevel1Reasons.contains(cs.Reason) && highPrioLevel2Reasons.contains(cs.Sub_Type_1__c)){
                cs.Priority = 'High';
            }
            else if(mediumPrioLevel1Reasons.contains(cs.Reason) && mediumPrioLevel2Reasons.contains(cs.Sub_Type_1__c)){
                cs.Priority = 'Medium';
            }
            else if(lowPrioLevel1Reasons.contains(cs.Reason) && lowPrioLevel2Reasons.contains(cs.Sub_Type_1__c)){
                cs.Priority = 'Low';
            }
        }
    }
 }

 /***********************************************************************************************
  @author : Anoori Muhammed
 * @description : Method to trigger email to instore / buying team
 **********************************************************************************************/
    //Commenting code as client doesnt require this feature.
   /* public static void notifyInstoreBuyingTeams(List<Case> newCaseList,Map<Id,Case> oldCaseMap,Boolean isUpdate){

    List<Case> caseList = new List<Case>();
    for(Case eachCaseRecord : newCaseList){
        if(isUpdate){
            if(eachCaseRecord.Reason == 'Problem with Item Received' && eachCaseRecord.Store__c != null && eachCaseRecord.Store__c != oldCaseMap.get(eachCaseRecord.Id).Store__c ){
                caseList.add(eachCaseRecord);
            }
        }else{
            if(eachCaseRecord.Reason == 'Problem with Item Received'){
                caseList.add(eachCaseRecord);
            }
        }
    }

    if(!caseList.isEmpty()){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Buying_Team__c> buyingTeamSetting = new List<Buying_Team__c>();
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where DeveloperName  = 'Notify_Instore_Buying_Team'];
        for(Case eachRecord : caseList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> sendTo = new List<String>();
            if(eachRecord.Origin == 'Web'  &&  eachRecord.Store__c != null){
                Membership_Team__c memberShipTeamSetting = Membership_Team__c.getValues(eachRecord.Store__c);
                sendTo.add(memberShipTeamSetting.Email__c);
                buyingTeamSetting = Buying_Team__c.getall().values();
                for(Buying_Team__c bt : buyingTeamSetting){
                    sendTo.add(bt.Name);
                }
            }else{
                buyingTeamSetting = Buying_Team__c.getall().values();
                for(Buying_Team__c bt : buyingTeamSetting){
                    sendTo.add(bt.Name);
                }
            }
            System.debug('emails@@@@@' + sendTo);
            mail.setToAddresses(sendTo);
            mail.setReplyTo('no-reply@landers.com');
            mail.setSenderDisplayName('TeamLanders');
            mail.setTargetObjectId(eachRecord.ContactId);
            mail.setTemplateID(emailTemplate.Id); 
            mail.setWhatId(eachRecord.Id);
            mail.setUseSignature(false); 
            mail.setBccSender(false); 
            mail.setSaveAsActivity(false); 
            mails.add(mail);
        }
        Messaging.sendEmail(mails);
    }
}
*/
/***********************************************************************************************
  @author : Anoori Muhammed
 * @description : Method to update Action on Case based on case reason & sub types
 **********************************************************************************************/

    public static void caseActionUpsert(List<Case> newCaseList,Map<Id,Case> oldCaseMap){

        String reasonSubTypeKey;
        Map<String,String> caseKeyMap =  new Map<String,String>();
        Boolean isInsert = (oldCaseMap == null);
        Boolean isValidUpdate;

        for(Case eachCaseRecord : newCaseList){

            Case oldCase = !isInsert ? oldCaseMap.get(eachCaseRecord.Id) : null;

            isValidUpdate = !isInsert  && ((eachCaseRecord.Reason != oldCase.Reason)
                                        || (eachCaseRecord.Sub_Type_1__c != null && eachCaseRecord.Sub_Type_1__c != oldCase.Sub_Type_1__c)
                                        || (eachCaseRecord.Sub_Type_2__c != null && eachCaseRecord.Sub_Type_2__c != oldCase.Sub_Type_2__c));

            if(isValidUpdate || isInsert){
                if(eachCaseRecord.Sub_Type_1__c != null && eachCaseRecord.Sub_Type_2__c != null){
                    reasonSubTypeKey = eachCaseRecord.Reason+':'+eachCaseRecord.Sub_Type_1__c+':'+eachCaseRecord.Sub_Type_2__c;
                }else if (eachCaseRecord.Sub_Type_1__c != null){
                    reasonSubTypeKey = eachCaseRecord.Reason+':'+eachCaseRecord.Sub_Type_1__c;
                }
                caseKeyMap.put(eachCaseRecord.caseNumber,reasonSubTypeKey);
            }
        }
        if(caseKeyMap.isEmpty()){
            return;
        }

        Map<String,String> actionsMap =  new Map<String,String>();

        for(Action_Settings__c eachAction : Action_Settings__c.getall().values()){
            actionsMap.put(eachAction.Key__c,eachAction.Action_Value__c);
        }

        if(actionsMap.values().isEmpty()){
            return;
        }
       
        for(Case eachCaseRecord : newCaseList){
            if(caseKeyMap.keySet().contains(eachCaseRecord.caseNumber) 
                && caseKeyMap.get(eachCaseRecord.caseNumber) != null 
                && actionsMap.keySet().contains(caseKeyMap.get(eachCaseRecord.caseNumber)) 
                && actionsMap.get(caseKeyMap.get(eachCaseRecord.caseNumber)) != null){
                    eachCaseRecord.Action__c = actionsMap.get(caseKeyMap.get(eachCaseRecord.caseNumber));
            }
        }
    }
}