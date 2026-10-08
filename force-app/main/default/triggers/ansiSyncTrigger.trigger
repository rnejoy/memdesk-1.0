trigger ansiSyncTrigger on Contact (after update,After Insert) {
    If(Trigger.IsAfter){
    	Set<id> conSetIds= new Set<id>();
        if(Trigger.isInsert){
            for(Contact con : Trigger.new){
                conSetIds.add(con.id);
            }
            SendBulkMembersDataToAllStores.SendMembers(conSetIds);            
        }

        if(Trigger.isUpdate){
            for(Contact con :Trigger.new){
                if(con.Membership_Expiry_Date__c != Trigger.OldMap.get(con.Id).Membership_Expiry_Date__c ||
                   con.Membership_ID__c != Trigger.OldMap.get(con.Id).Membership_ID__c ||
                   con.Membership_Start_Date__c != Trigger.OldMap.get(con.Id).Membership_Start_Date__c ||
                   con.Is_Active__c != Trigger.OldMap.get(con.Id).Is_Active__c ||
                   con.Is_VAT_Exempt__c != Trigger.OldMap.get(con.Id).Is_VAT_Exempt__c ||
                   con.Customer_Sub_Type__c != Trigger.OldMap.get(con.Id).Customer_Sub_Type__c ||
                   con.Customer_Type__c != Trigger.OldMap.get(con.Id).Customer_Type__c ||
                   con.Membership_Type__c != Trigger.OldMap.get(con.Id).Membership_Type__c ||
                   con.AccountId != Trigger.OldMap.get(con.Id).AccountId 
                  ) conSetIds.add(con.id);   
                	
            }
            if(System.IsBatch() == false && System.isFuture() == false){
            	SendBulkMembersDataToAllStores.SendMembers(conSetIds);     
            }
        }
    }
}