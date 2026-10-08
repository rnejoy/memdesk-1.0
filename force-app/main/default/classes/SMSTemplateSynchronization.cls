public class SMSTemplateSynchronization {
	@InvocableMethod
	public static void synchronize(List<Id> tempIds) {
		for (Integer i=0; i<tempIds.size(); i++) {
			try {
				post2gcp2(tempIds[i]);
			}
			catch (Exception e) {
				System.debug('Send Error: ' + e);
			}
		}
	}

	@future(callout=true)
	public static void post2gcp2(Id tempId) {
		//whether it is create or update, we just send all the fields.. sms_template_synchronize.php will take care of UPSERTING the affected record
		SMS_Template__c temp = [SELECT Is_Tested__c, Template_Number__c, Template_Title__c, Message_Type__c, Message_Body__c FROM SMS_Template__c WHERE Id =: tempId];
		Integer length = temp.Message_Body__c.length();
		Integer parts;
		temp.Message_Length__c = String.valueOf(length);
		if (length > 918) {
			temp.Message_Length__c = 'Message length is greater than 918. Message was truncated to 918.';
			temp.Message_Body__c   = temp.Message_Body__c.substring(0, 918) + ' ... truncated here ...';
		}

		if (length > 765)
			parts = 6;
		else if (length > 612)
			parts = 5;
		else if (length > 549)
			parts = 4;
		else if (length > 306)
			parts = 3;
		else if (length > 160)
			parts = 2;
		else
			parts = 1;
		temp.Number_Parts__c = parts;

		String environment = System.Label.SMS_Environment;
		System.Debug('environment :>> ' + environment);
		String url = 'https://sms.mylanders.ph/test_send_sms/sms_template_synchronize.php';
		if (environment == 'Prod')
			url = 'https://sms.mylanders.ph/prod_send_sms/sms_template_synchronize.php';

		String params = '&template_number=' + temp.Template_Number__c +
						'&template_title='  + temp.Template_Title__c  +
						'&message_type='    + temp.Message_Type__c    +
						'&message_body='    + EncodingUtil.urlEncode(temp.Message_Body__c, 'UTF-8') +
						'&is_tested='       + temp.Is_Tested__c;

		String response = httpReq(url, params);
		System.Debug('response: ' + response);
		temp.Synch_Result__c = response;
		update temp;
	}

	private static String httpReq(String url, String params) {
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('POST');
		req.setBody(params);
		HttpResponse res = h.send(req);

		return res.getBody();
	}
}