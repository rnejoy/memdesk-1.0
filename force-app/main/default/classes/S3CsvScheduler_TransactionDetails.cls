public class S3CsvScheduler_TransactionDetails implements Schedulable{
    public void execute(SchedulableContext SC) {
        String url = 'callout:AWS_Callout_Test/'+ '?prefix=landers/Salesforce/transactiondetails/transactiondetails_instore_'+datetime.now().format('yyyyMMdd');
        S3CsvToSalesforceBatch y = new S3CsvToSalesforceBatch('transaction details',url);
        Id X = Database.executeBatch(y, 1);
    }
}