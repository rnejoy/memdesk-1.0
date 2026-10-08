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


public class Store_MemberJsonBodyGen {
    public static String jsongenerator(String memId, string PartnerKey){
        JSONGenerator memberSfToJSON = JSON.createGenerator(false);
        contact con = [select id , Membership_ID__c , Name  ,Customer_Sub_Type__c ,
                       Membership_Start_Date__c , Membership_Expiry_Date__c ,
                       Is_Active__c , Is_VAT_Exempt__c , Customer_Type__c ,
                       Membership_Type__c , Account.id , Account.type from contact where id = : MemId];
        String membershipId;
        String memberName;
        String membershipDate;
        String membershipExipry;
        String AccType;
        String customerType;
        String membershipType;
        String AccId;
        membershipId = (con.Membership_ID__c == null) ? '' : con.Membership_ID__c;
        customerType = (con.Customer_Type__c == null) ? '' : con.Customer_Type__c;
        membershipType = (con.Membership_Type__c == null) ? '' : con.Membership_Type__c;
        AccType = (con.Customer_Sub_Type__c  == null) ? '' :   con.Customer_Sub_Type__c;
        AccId = (con.Account.id == null) ? '' : con.Account.id;
        
        if(con.Membership_Start_Date__c == null)
        {
            membershipDate = '';
        } else {
             Date dToday =con.Membership_Start_Date__c;
             String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
             membershipDate = dateStr; 
          }
        if(con.Membership_Expiry_Date__c == null)
        {
            membershipExipry = '';
        } else {
            Date dToday =con.Membership_Expiry_Date__c;
            String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
            membershipExipry = dateStr;
          }
        //mSu33mIbRgdCc6V3rDkbiQ==khpCnjDEBi3GcFY+YQ44PYhlShcjh3RvprXuvGiLiNzytjMyQWgEY0fHM2GvDQYd
        memberSfToJSON.writeStartObject();
        memberSfToJSON.writeStringField('PartnerKey', PartnerKey);
        memberSfToJSON.writeFieldName('CustomerDetails');
        memberSfToJSON.writeStartArray();
        memberSfToJSON.writeStartObject();
        memberSfToJSON.writeStringField('Code' , membershipId );
        memberSfToJSON.writeStringField('Name', con.Name);
        memberSfToJSON.writeStringField('MemDate', membershipDate);
        memberSfToJSON.writeStringField('ExpDate', membershipExipry);
        memberSfToJSON.writeBooleanField('Active', con.Is_Active__c);
        memberSfToJSON.writeBooleanField('Vatxmpt', con.Is_VAT_Exempt__c );
        memberSfToJSON.writeStringField('AcctType',  AccType);
        memberSfToJSON.writeStringField('CusType', customerType );
        memberSfToJSON.writeStringField('MemType', membershipType );  
        memberSfToJSON.writeStringField('AccountId', AccId );      
        memberSfToJSON.writeEndObject();
        memberSfToJSON.writeEndArray();
        memberSfToJSON.writeEndObject();    
        String reqBody = memberSfToJSON.getAsString();
        system.debug('reqBody*****'+reqBody);
        return reqBody;
        
    }
     public static String jsonGeneratorBulk(Set<Id> cSet, string PartnerKey){
        JSONGenerator memberSfToJSON = JSON.createGenerator(false);
        List<contact> conList = [select id , Membership_ID__c , Name  ,Customer_Sub_Type__c ,
                       Membership_Start_Date__c , Membership_Expiry_Date__c ,
                       Is_Active__c , Is_VAT_Exempt__c , Customer_Type__c ,
                       Membership_Type__c , Account.id , Account.type from contact where id IN :cSet];
         memberSfToJSON.writeStartObject();
         memberSfToJSON.writeStringField('PartnerKey', PartnerKey);
         memberSfToJSON.writeFieldName('CustomerDetails');
         memberSfToJSON.writeStartArray();
         for(contact con : conList){
         
        String membershipId;
        String memberName;
        String membershipDate;
        String membershipExipry;
        String AccType;
        String customerType;
        String membershipType;
        String AccId;
        membershipId = (con.Membership_ID__c == null) ? '' : con.Membership_ID__c;
        customerType = (con.Customer_Type__c == null) ? '' : con.Customer_Type__c;
        membershipType = (con.Membership_Type__c == null) ? '' : con.Membership_Type__c;
        AccType = (con.Customer_Sub_Type__c  == null) ? '' :   con.Customer_Sub_Type__c;
        AccId = (con.Account.id == null) ? '' : con.Account.id;
        
        if(con.Membership_Start_Date__c == null)
        {
            membershipDate = '';
        } else {
             Date dToday =con.Membership_Start_Date__c;
             String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
             membershipDate = dateStr; 
          }
        if(con.Membership_Expiry_Date__c == null)
        {
            membershipExipry = '';
        } else {
            Date dToday =con.Membership_Expiry_Date__c;
            String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
            membershipExipry = dateStr;
          }
        //mSu33mIbRgdCc6V3rDkbiQ==khpCnjDEBi3GcFY+YQ44PYhlShcjh3RvprXuvGiLiNzytjMyQWgEY0fHM2GvDQYd
        
        
        memberSfToJSON.writeStartObject();
        memberSfToJSON.writeStringField('Code' , membershipId );
        memberSfToJSON.writeStringField('Name', con.Name);
        memberSfToJSON.writeStringField('MemDate', membershipDate);
        memberSfToJSON.writeStringField('ExpDate', membershipExipry);
        memberSfToJSON.writeBooleanField('Active', con.Is_Active__c);
        memberSfToJSON.writeBooleanField('Vatxmpt', con.Is_VAT_Exempt__c );
        memberSfToJSON.writeStringField('AcctType',  AccType);
        memberSfToJSON.writeStringField('CusType', customerType );
        memberSfToJSON.writeStringField('MemType', membershipType );  
        memberSfToJSON.writeStringField('AccountId', AccId );      
        memberSfToJSON.writeEndObject();
             }
         memberSfToJSON.writeEndArray();
        memberSfToJSON.writeEndObject();  
        String reqBody = memberSfToJSON.getAsString();
        system.debug('reqBody*****'+reqBody);
        return reqBody;
        
    }
    
}