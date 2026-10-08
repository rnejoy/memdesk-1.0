/**
 * @author : Anoori Muhammed / Satish Lokinindi
 * @date : 15-01-2022
 * @description : Case Trigger
 * @last modified on  : 01-02-2022
 * @last modified by  : Anoori Muhammed / Satish Lokinindi
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0  15-01-2022   Anoori Muhammed   Initial Version
**/
trigger  caseTrigger on Case (before update,before insert,after insert,after update) {

    if(Trigger.isBefore){

        if(Trigger.isInsert){
            CaseTriggerHelper.updateCasePriority(Trigger.New);
            CaseTriggerHelper.caseActionUpsert(Trigger.New,null);
        }

        if(Trigger.isUpdate){
            //CaseTriggerHelper.sendEscalationEmail(Trigger.New,Trigger.OldMap);
           // CaseTriggerHelper.changeCaseStatus(Trigger.New,Trigger.OldMap);
            CaseTriggerHelper.updateCasePriority(Trigger.New);
            CaseTriggerHelper.caseActionUpsert(Trigger.New,Trigger.OldMap);
        }
    }
    /*    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            CaseTriggerHelper.notifyInstoreBuyingTeams(Trigger.New,Trigger.oldMap,false);
        }
        if(Trigger.isUpdate){
            CaseTriggerHelper.notifyInstoreBuyingTeams(Trigger.New,Trigger.oldMap,true);
        }
    } 
    */
}