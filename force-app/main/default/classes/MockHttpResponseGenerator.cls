@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody('<?xml version="1.0" encoding="UTF-8"?>\n<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>seari-as3</Name><Prefix>landers/Salesforce/transaction/transaction_instore&amp;online&amp;central_20230112</Prefix><Marker></Marker><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated><Contents><Key>landers/Salesforce/transaction/transaction_instore&amp;online&amp;central_20230112_003430_0.csv</Key><LastModified>2023-01-11T16:34:39.000Z</LastModified><ETag>&quot;abc247c0743434e434c0cf1414c876cd&quot;</ETag><Size>1483699</Size><Owner><ID>172fa4c692d08e28ea7269432625c7512f1323aae877fc77b4921ad3b391d00c</ID><DisplayName>LNDSYSAD</DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>');
        res.setStatusCode(200);
        return res;
    }
}