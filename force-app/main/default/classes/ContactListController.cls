public with sharing class ContactListController {
    public String searchTerm { get; set; }
    public List<Contact> contacts { get; set; }

    public ContactListController() {
        contacts = new List<Contact>();
    }

    public PageReference searchContacts() {
        String soql = 'SELECT Id, Name, Membership_ID__c, Response_codes__c FROM Contact WHERE response_codes__c LIKE \'%' + searchTerm + '%\' limit 50';
        contacts = Database.query(soql);
        return null;
    }
    
    public PageReference reSend() {
    	Set<id> conSetIds= new Set<id>();
        
        for(Contact con : contacts) {
        	conSetIds.add(con.Id); 
        }   
        
        SendBulkMembersDataToAllStores.SendMembers(conSetIds);            
        
        return null;
    }    
}