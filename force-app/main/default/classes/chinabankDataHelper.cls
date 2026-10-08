public with sharing class chinabankDataHelper {
    
    public static string transformBusinessStreet(string business_street, string current_street){
        if(String.isBlank(business_street)){
            return current_street;
        }
        return business_street;
    }
}