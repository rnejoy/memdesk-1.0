public class S3CsvToSalesforceCallout {
	public static void getFileFromS3(String objectTarget, String filename) {
        if (!String.isBlank(filename) && !String.isBlank(objectTarget)) {
            filename = EncodingUtil.urlEncode(filename, 'UTF-8');
            filename = filename.replace('%2F', '/');
            System.debug('filename: '+ filename);
            String url = 'callout:AWS_Callout_Test/'+ filename;
            HttpRequest req  = new HttpRequest();
            HttpResponse res = new HttpResponse();
            req.setEndpoint(url);
            req.setMethod('GET');
            Http http = new Http();
            res = http.send(req);
            if(res.getStatusCode() == 200){
				System.debug(res.getBody());
                S3CsvToSalesforceHelper.CSVtoSFObject_Method(objectTarget, res.getBody());
            }
        }
    }
}