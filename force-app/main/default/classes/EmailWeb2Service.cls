global class EmailWeb2Service {

	global class myOutputs {
		webservice String status;
	}

	webservice static myOutputs sendEmail(String mmode, String emailto, String mrecord) {
		System.Debug('we are in EmailWebService web service');
		String subject;
		String html;
		if (mmode == 'ST') {
			subject = 'System Test for Email SF Transport';
			html = mrecord;
		}
		else {
			if (mmode == 'MT') {
				EmailTemplate temp = [SELECT Subject, HTMLValue FROM EmailTemplate WHERE DeveloperName = 'Send_Test_Email'];
				subject = temp.Subject;
				html = temp.HTMLValue;
				html = html.replace('{!record}', mrecord);
			}
			else {
				if (mmode == 'UT') {
					subject = 'Customer Picture Upload Utility';
					html = mrecord;
				}
				else {
					EmailTemplate temp = [SELECT Subject, HTMLValue FROM EmailTemplate WHERE DeveloperName = 'Extensions_Send_Registration_Link'];
					subject = temp.Subject;
					html = temp.HTMLValue;
					html = html.replace('{!ExtensionURL}', EncodingUtil.urldecode(mrecord, 'utf-8'));
					html = html.replace('{!ExtensionURLEncoded}', mrecord);
				}
			}
		}

		OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where DisplayName = 'no-reply'];
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setOrgWideEmailAddressId(owea.Id);
		mail.toAddresses = new String[] {emailto};
		mail.subject  = subject;
		mail.htmlbody = html;
		Messaging.SingleEmailMessage[] mails = new List<Messaging.SingleEmailMessage> {mail};
		Messaging.SendEmailResult[] results  = Messaging.sendEmail(mails);
		String status;
		if (results[0].success) {
			System.debug('The email was sent successfully.');
			status = 'OKS';
		}
		else {
			System.debug('The email failed to send: ' + results[0].errors[0].message);
			status = results[0].errors[0].message;
		}

		myOutputs output = new myOutputs();
			output.status =  status;
		return output;
	}
}