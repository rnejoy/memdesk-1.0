({
	loadContacts : function(component) {
		console.log('Extra 2 recordId: ' + component.get("v.recordId"));
		var action = component.get("c.getContactRec");
		action.setParams({"conId": component.get("v.recordId")});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				component.set("v.contactObj", response.getReturnValue());
				var accId = component.get("v.contactObj.AccountId");
				var sType = 'Primary';
				component.set("v.relconLabel", sType);
				if (component.get('v.contactObj.Customer_Sub_Type__c') == 'Primary') {
					sType = 'Extension';
					component.set("v.relconLabel", sType + 's');
				}

				console.log('accId: ' + accId);
				console.log('sType: ' + sType);

				var paction = component.get("c.getRelatedRecs");
				paction.setParams({'accId': accId, 'sType': sType});
				paction.setCallback(this, function(response) {
					var state = response.getState();
					if (state === "SUCCESS") {
						component.set("v.contacts", response.getReturnValue());
						this.updateTotal(component);
					}
				});
				$A.enqueueAction(paction);
			}
		});
		$A.enqueueAction(action);
	},

	getPictureURL : function(component) {
		var action = component.get("c.getPictureURL");
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state == "SUCCESS") {
				console.log('pictureURL: ' + response.getReturnValue());
				component.set("v.pictureURL", response.getReturnValue());
			}
		});
		$A.enqueueAction(action);
	},

	updateTotal: function(component) {
		var contacts = component.get("v.contacts");
		component.set("v.totalContacts", contacts.length);
	}
})