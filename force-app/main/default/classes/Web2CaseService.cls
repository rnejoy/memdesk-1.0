global class Web2CaseService {
	global class myOutputs {
		webservice String status;
		webservice String message;
	}

	global class myInputs {
		webservice String membershipId;
		webservice String fullName;
		webservice String emailAdd;
		webservice String enqrType;
		webservice String esubTyp1;
		webservice String orderNum;
		webservice String message;
		webservice String attachment;
		webservice String fileName;
	}

	webservice static myOutputs receiveCase(myInputs input) {
		System.Debug('we are in Chaio2CaseService');
		System.debug(JSON.serializePretty(input));
		String status;
		String message;

		Group getGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Web Case Queue' LIMIT 1];
		Case newCase = new Case();
		newCase.Origin 		  = 'Web';
		newCase.SuppliedName  = input.fullName;
		newCase.SuppliedEmail = input.emailAdd;
		newCase.Reason 		  = input.enqrType;
		newCase.Sub_Type_1__c = input.esubTyp1;
		newCase.Order_No__c   = input.orderNum;
		newCase.Subject		  = 'Landers.ph-Contact Us';
		newCase.Description	  = input.message;
		newCase.OwnerId		  = getGroup.Id;

		String memId = input.membershipId == null ? '' : input.membershipId;
		if (memId != '') {
			List<Contact> getMember = [SELECT Id FROM Contact WHERE Membership_ID__c =: memId];
			if (getMember.size() > 0)
				newCase.ContactId = getMember[0].Id;
		}

		try {
			insert newCase;

			String attach = input.attachment == null ? '' : input.attachment;
			if (attach != '') {
				ContentVersion newAttach = new ContentVersion();
				newAttach.FirstPublishLocationId = newCase.Id;
				newAttach.VersionData 			 = EncodingUtil.base64Decode(attach);
				newAttach.Title 				 = input.fileName;
				newAttach.PathOnClient 			 = input.fileName;
				insert newAttach;
			}

			status  = 'OKS';
			message = 'Web service successfully completed';
		}
		catch (Exception e) {
			status  = 'ERR';
			message = String.valueOf(e);
		}

		myOutputs output = new myOutputs();
		output.status  = status;
		output.message = message;
		return output;
	}
}