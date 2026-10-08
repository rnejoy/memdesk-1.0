global class VoucherWebService {

	global class MyOutputs {
		webservice String status;
		webservice String message1;
		webservice String message2;
		webservice String message3;
		webservice String isvalid;
	}

	global class MyOutput {
		webservice String status;
		webservice String message;
	}

	webservice static MyOutputs checkVoucher(String voucher) {
		System.Debug('we are in VoucherWebService-checkVoucher');
		System.Debug('voucher :>> ' + voucher);
		String status;
		String message1;
		String message2 = '';
		String message3 = '';
		String isvalid  = '0';

		try {
			List<Voucher__c> vouch = [SELECT Claimed__c, Membership_ID__c, Start_Date__c, End_Date__c FROM Voucher__c WHERE Voucher_Code__c =: voucher];
			if (vouch.size() > 0) {
				if (vouch[0].Claimed__c == false) {
					Date tdate = Date.today();
					Date sdate = Date.valueOf(vouch[0].Start_Date__c);
					Date edate = Date.valueOf(vouch[0].End_Date__c);
					if (tdate < sdate || tdate > edate) {
						message1 = 'Valid but either not started yet or expired';
						message2 = String.valueOf(sdate).Left(10) + ':' + String.valueOf(edate).Left(10);
					}
					else {
						String membershipid = vouch[0].Membership_ID__c == null ? '' : vouch[0].Membership_ID__c;
						if (membershipid != '') {
							message1 = 'Valid, available and assigned to:';
							List<Contact> con = [SELECT FirstName, LastName FROM Contact WHERE Membership_ID__c =: membershipid];
							if (con.size() > 0) {
								message2 = con[0].FirstName + ' ' + con[0].LastName;
							}
							message3 = membershipid;
							isvalid = '1';
						}
						else {
							message1 = 'Valid and available';
							isvalid = '1';
						}
					}
				}
				else {
					message1 = 'Already claimed';
				}
			}
			else {
				message1 = 'Not in database';
			}

			status  = 'OKS';
		}
		catch (Exception e) {
			status  = 'ERR';
			message1 = String.valueOf(e);
		}

		MyOutputs output = new MyOutputs();
			output.status   = status;
			output.message1 = message1;
			output.message2 = message2;
			output.message3 = message3;
			output.isvalid  = isvalid;
		return output;
	}

	webservice static MyOutput setVoucher (String voucher) {
		System.Debug('we are in VoucherWebService-setVoucher');
		System.Debug('voucher :>> ' + voucher);

		String status;
		String message;

		try {
			List<Voucher__c> vouch = [SELECT Id FROM Voucher__c WHERE Voucher_Code__c =: voucher];
			if (vouch.size() > 0) {
				vouch[0].Claimed__c = true;

				update vouch;

				status  = 'OKS';
				message = 'Voucher successfully set to claimed';
			}
			else {
				status  = 'ERR';
				message = 'Voucher Code not in database';
			}

		}
		catch (Exception e) {
			status  = 'ERR';
			message = String.valueOf(e);
		}

		MyOutput output = new MyOutput();
			output.status  = status;
			output.message = message;
		return output;
	}
}