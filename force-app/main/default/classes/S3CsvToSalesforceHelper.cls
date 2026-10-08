public class S3CsvToSalesforceHelper {
    public static void CSVtoSFObject_Method(String objectTarget, String csvAsString){
        //String csvAsString;
        //csvAsString = csvBlob.toString();
        String[] csvFileLines = safeSplit(csvAsString, '\n');
        System.debug('csvFileLines size = '+ csvFileLines.size());
        if(csvFileLines.size() > 0){
            CommaSplitAndAssigntoField(objectTarget, csvFileLines);
        }
        System.debug('Success');
    }
    public static List<String> safeSplit(String inStr, String delim){
        Integer regexFindLimit = 100;
        Integer regexFindCount = 0;
        
        List<String> output = new List<String>();
        
        Matcher m = Pattern.compile(delim).matcher(inStr);
        
        Integer lastEnd = 0;
    
        while(!m.hitEnd()){
            while(regexFindCount < regexFindLimit && !m.hitEnd()){
                if(m.find()){
                    output.add(inStr.substring(lastEnd, m.start()));  
                    lastEnd = m.end();
                }
                else{
                    output.add(inStr.substring(lastEnd));
                    lastEnd = inStr.length();
                }
                
                regexFindCount++;
            }
    
            m.reset(inStr);        
            m.region(lastEnd, m.regionEnd());
            
            regexFindCount = 0;
        }
        
    	return output;
	}
    public static void CommaSplitAndAssigntoField(String objectTarget, String[] csvFileLines){
        
        if(objectTarget == 'transactions'){
            Contact dummyMember = [SELECT Id FROM Contact LIMIT 1];
            List<Transaction__c> transactionsList = new List<Transaction__c>();
            for(Integer i = 1; i <= csvFileLines.size()-1; i++){
                String[] items = csvFileLines[i].split(',',-1);
                if(items.size() == 29 && items[4] != ''){
                	Transaction__c newTransaction = new Transaction__c();
                    newTransaction.Branch__c = items[0];
                    if(!String.isBlank(String.Valueof(items[1]))){
                        newTransaction.Cashier_Code__c = decimal.valueOf(items[1]);    
                    }
                    if(!String.isBlank(String.Valueof(items[2]))){
                        newTransaction.Credit_Memo_Expiration_Date__c = date.valueOf(items[2]);
                    }
                    if(!String.isBlank(String.Valueof(items[3]))){
                        newTransaction.Date_and_Time_Returned__c = datetime.valueOf(items[3]);
                    }
                    if(items[4].length() > 16 ){
                    	newTransaction.Membership_ID__c = items[4].substring(0, 15);
                    }
                    else{
                        newTransaction.Membership_ID__c = items[4];
                    }
                    if(!String.isBlank(String.Valueof(items[5]))){
                        newTransaction.Transaction_Date__c = date.valueOf(items[5]);
                    } 
                    newTransaction.Name = items[6];
                    newTransaction.Transaction_Type__c = items[7];
                    newTransaction.Food_service_code__c = items[8];
                    newTransaction.Caltex_code__c = items[9];
                    newTransaction.Mode__c = items[10];
                    newTransaction.Type__c = items[11];
                    if(items[12].length() > 254 ){
                        newTransaction.Remarks__c = items[12].substring(0, 254);
                    }
                    else{
                        newTransaction.Remarks__c = items[12];    
                    }
                    newTransaction.Status__c = items[13];
                    newTransaction.Void__c = items[14];
                    newTransaction.Credit_Memo_Number__c = items[15];
                    if(!String.isBlank(String.Valueof(items[16]))){
                        newTransaction.Manager_Code__c = decimal.valueOf(items[16]);
                    }
                    newTransaction.Billing_Information__c = items[17];
                    //newTransaction.DeliveryAddress = items[18];
                    newTransaction.Delivery_Date__c = items[19];
                    if(!String.isBlank(String.Valueof(items[20]))){
                        newTransaction.Delivery_Fee__c = decimal.valueOf(items[20]);
                    }
                    newTransaction.Delivery_Time__c = items[21];
                    newTransaction.Ship_To__c = items[22];
                    //newTransaction.vouchercode = items[23];
                    newTransaction.Manager_Name__c = items[24];
                    newTransaction.Credit_Memo_Reasons__c = items[25];
                    //newTransaction.Personal_Shopper__c = items[26];
                    newTransaction.Payment_Method__c = items[27];
                    newTransaction.Source_of_Purchase__c = items[28];
                    newTransaction.Member__c = dummyMember.Id;
                    transactionsList.add(newTransaction);   
                }
            }
            if(transactionsList.size() > 0){
                System.debug('Transaction list size: '+transactionsList.size());
                Database.insert(transactionsList,false);
            }
        }
        else if(objectTarget == 'transaction details'){
            Transaction__c dummyTransaction = [SELECT Id FROM Transaction__c LIMIT 1];
            List<Transaction_Details__c> transactionDetailsList = new List<Transaction_Details__c>();
            // csvFileLines.size()-1 because an extra line is always present on the files 
            for(Integer i = 1; i <csvFileLines.size()-1; i++){
                String[] items = csvFileLines[i].split(',',-1);
                if(items.size() == 26 && items[5] != ''){
                    Transaction_Details__c newTransactionDetails = new Transaction_Details__c();
                    newTransactionDetails.Article__c = items[0];
                    if(!String.isBlank(String.Valueof(items[1]))){
                        newTransactionDetails.Price__c = decimal.valueOf(items[1]);
                    }
                    if(!String.isBlank(String.Valueof(items[2]))){
                        newTransactionDetails.Quantity__c = decimal.valueOf(items[2]);
                    }
                    newTransactionDetails.Remarks__c = items[3];
                    //newTransactionDetails.Subtotal__c = items[4];
                    newTransactionDetails.Transaction_No__c = items[5];
                    newTransactionDetails.Item_Description_POS_Number__c = items[6];
                    newTransactionDetails.Membership_ID__c = items[7];
                    newTransactionDetails.Article_Description__c = items[8];
                    newTransactionDetails.Class__c = items[9];
                    newTransactionDetails.Dept__c = items[10];
                    if(!String.isBlank(String.Valueof(items[11]))){
                        newTransactionDetails.Reg_SRP__c = decimal.valueOf(items[11]);
                    }
                    newTransactionDetails.Sub_class__c = items[12];
                    newTransactionDetails.Subdept__c = items[13];
                    if(!String.isBlank(String.Valueof(items[14]))){
                        newTransactionDetails.Promo_SRP__c = decimal.valueOf(items[14]);
                    }
                    newTransactionDetails.Promo_Type__c = items[15];
                    if(!String.isBlank(String.Valueof(items[16]))){
                        newTransactionDetails.Promo_Code__c = decimal.valueOf(items[16]);
                    }
                    //newTransactionDetails.DiscountCode = items[17];
                    //newTransactionDetails.netsales = items[18];
                    //newTransactionDetails.btgi = items[19],
                    //newTransactionDetails.manualdiscount = items[20],
                    //newTransactionDetails.grossafterpromo = items[21],
                    //newTransactionDetails.promodiscount = items[22],
                    //newTransactionDetails.tax = items[23],
                    //newTransactionDetails.gross = items[24],
                    //newTransactionDetails.onsale = items[25]
                    newTransactionDetails.Transaction__c = dummyTransaction.Id;
                    transactionDetailsList.add(newTransactionDetails);	
                }
            }
            if(transactionDetailsList.size() > 0){
                Database.insert(transactionDetailsList, false); 
            }
        }

	}
}