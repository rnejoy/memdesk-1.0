public class S3CsvToSalesforceBatch implements Database.Batchable<String>,Database.AllowsCallouts{
    public String objectTarget2;
    public String url2;
    
    public S3CsvToSalesforceBatch(String objectTarget, String url){
        url2 = url;
        objectTarget2 = objectTarget;
    }
    
    public List<String> start(Database.BatchableContext BC){
        HttpRequest req  = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setEndpoint(url2);
        req.setMethod('GET');
        Http http = new Http();
        res = http.send(req);
        ListBucketResult result;
        if(res.getStatusCode() == 200) {
            result = new ListBucketResult(res.getBody());
        }
        return result.Keys;
    }
    
    public void execute(Database.BatchableContext BC, List<String> scope){
        for(String s : scope){
            S3CsvToSalesforceCallout.getFileFromS3(objectTarget2, s);
        }
    }
    
    public void finish(Database.BatchableContext BC){
    }
}