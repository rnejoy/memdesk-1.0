({
    doInit : function(component, event, helper){
		console.log('recordId: ' + component.get("v.recordId"));
		var action = component.get("c.getContactRec");
		action.setParams({"conId": component.get("v.recordId")});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				component.set("v.contactObj", response.getReturnValue());

				var laction = component.get("c.getLeadRec");
				laction.setParams({"conId": component.get("v.recordId")});
				laction.setCallback(this, function(response) {
					var state = response.getState();
					if (state === "SUCCESS") {
						component.set("v.leadObj", response.getReturnValue());
						if (component.get("v.leadObj.LeadSource") == 'Canvasser') {
							component.set("v.StoreCanvaLabel", "Canvasser");
							component.set("v.StoreCanvaName", component.get("v.leadObj.Canvasser_Name__c"));
						}
						else {
							component.set("v.StoreCanvaLabel", "Store");
							component.set("v.StoreCanvaName", component.get("v.leadObj.Store_Signup__c"));
						}

						var dt = new Date(component.get("v.contactObj.Birthdate__c"));
						var bdate = dt.getMonth().toString() + dt.getDate().toString();
						dt = new Date();
						var syear = dt.getFullYear(); var smon  = dt.getMonth(); var sday  = dt.getDate();
						var sdate = smon.toString() + sday.toString();
						dt = new Date(component.get("v.contactObj.Membership_Expiry_Date__c"));
						var xyear = dt.getFullYear(); var xmon  = dt.getMonth(); var xday  = dt.getDate();

						if (xyear > syear)
							xmon += 12;
						if (xmon - smon <= 3) {
							document.getElementById('tmmessage').style.display = "block";
							document.getElementById('specialmsgdiv').style.display = "block";
						}
						if (xmon - smon == 3 && sday < xday) {
							document.getElementById('tmmessage').style.display = "none";
							document.getElementById('specialmsgdiv').style.display = "none";
						}

						if (bdate == sdate) {
							document.getElementById('hbmessage').style.display = "block";
							document.getElementById('specialmsgdiv').style.display = "block";
							document.getElementById('hbmessage').style.color = component.get("v.hbcolor");
						}
					}
				});
				$A.enqueueAction(laction);
			}
		});
		$A.enqueueAction(action);
    }
})