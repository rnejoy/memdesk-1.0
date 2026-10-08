public class S3CsvScheduler_FB implements Schedulable{
    public void execute(SchedulableContext SC) {
        String url = 'callout:AWS_Callout_Test/'+ '?prefix=landers/Salesforce/transaction/transaction_fb_'+datetime.now().format('yyyyMMdd');
        S3CsvToSalesforceBatch y = new S3CsvToSalesforceBatch('transactions',url);
        Id X = Database.executeBatch(y, 1);
    }
}