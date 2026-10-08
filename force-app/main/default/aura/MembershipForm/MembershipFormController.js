({
	doInit: function(component, event, helper) {
		var today = $A.localizationService.formatDate(new Date(), "MM-DD-YYYY");
		component.set('v.today', today);

		component.set("v.qrcVersion",  helper.getParameterByName('qrcVersion'));
		component.set("v.leadSource",  helper.getParameterByName('leadSource'));
		component.set("v.canvasserId", helper.getParameterByName('canvasserId'));
		component.set("v.campaignId",  helper.getParameterByName('campaignId'));
		component.set("v.URLStr", window.location.href);

		//before ANYTHING.. LET US CHECK THE VERSION OF THE QR CODE SCANNED!!!!
		var leadSource = component.get("v.leadSource");
		var recordId   = component.get("v.canvasserId");	//common for store and canvasser
		var canvType   = 'C';
		if (leadSource == 'Store')
			canvType = 'S';

		console.log('Canvasser Type: ' + canvType);

		var paction;
		if (canvType == 'S')
			paction = component.get("c.fetchQRSVersion");
		else
			paction = component.get("c.fetchQRCVersion");

		paction.setParams({'recId':recordId});
		paction.setCallback(this, function(response) {
			var state = response.getState();
			var isActive;
			if (state === "SUCCESS") {
				if (canvType == 'S') {
					component.set("v.storeObj", response.getReturnValue());
					component.set("v.qrdVersion", component.get("v.storeObj.QR_Code_Version__c"));
					component.set("v.qrdCName",   component.get("v.storeObj.Name__c"));
					isActive = component.get("v.storeObj.IsActive__c");
					component.set("v.AErrorLabel", 'Store');

					component.set("v.leadObj.Store_Signup__c", component.get("v.storeObj.Name__c"));
					component.set("v.leadObj.Store_Signup_Code__c", component.get("v.storeObj.Code__c"));
				}
				else {
					component.set("v.canvassObj", response.getReturnValue());
					component.set("v.qrdVersion", component.get("v.canvassObj.QR_Code_Version__c"));
					component.set("v.qrdCName",   component.get("v.canvassObj.Name__c"));
					isActive = component.get("v.canvassObj.IsActive__c");

					component.set("v.leadObj.Canvasser_Name__c", component.get("v.canvassObj.Name__c"));
					component.set("v.leadObj.Canvasser_Code__c", component.get("v.canvassObj.C_Code__c"));
					component.set("v.leadObj.Store_Signup__c", component.get("v.canvassObj.Store_Assignment__c"));
					component.set("v.leadObj.Store_Signup_Code__c", component.get("v.canvassObj.Store_Assignment_Code__c"));
				}

				console.log("qrdVersion: " + component.get("v.qrdVersion"));
				console.log("qrcVersion: " + component.get("v.qrcVersion"));
				console.log("qrdCName: "   + component.get("v.qrdCName"));

                console.log('store assignment code: ' + component.get("v.canvassObj.Store_Assignment_Code__c"));
                console.log('lead store assignment code: ' + component.get("v.leadObj.Store_Signup_Code__c"));
				console.log('canvasser code: ' + component.get("v.canvassObj.C_Code__c"));
				console.log('lead canvasser code: ' + component.get("v.leadObj.Canvasser_Code__c"));

				console.log('isActive: ' + isActive);
				if (isActive == false) {
					component.set("v.showQRAError", true);
				}
				else if (component.get("v.qrcVersion") * 1 != component.get("v.qrdVersion") * 1) {
					component.set("v.showQRVError", true);
				}
				else {
					var action = component.get("c.fetchProvinces");
					action.setCallback(this, function(response) {
						var state = response.getState();
						if (state === "SUCCESS") {
							component.set("v.Poptions", response.getReturnValue());
						}
					});
					$A.enqueueAction(action);

					var action2 = component.get("c.fetchNationals");
					action2.setCallback(this, function(response) {
						var state2 = response.getState();
						if (state2 === "SUCCESS") {
							component.set("v.Noptions", response.getReturnValue());
						}
					});
					$A.enqueueAction(action2);

					var action3 = component.get("c.fetchStores");
					action3.setCallback(this, function(response) {
						var state3 = response.getState();
						if (state3 === "SUCCESS") {
							component.set("v.Soptions", response.getReturnValue());
						}
					});
					$A.enqueueAction(action3);

					//this here below controls which screen we will show upon entry
					// v.screen is passed by the component propert set in Experience Builder
					var screenToShow = component.get("v.screen");
					if (screenToShow == 'Prompt') {
						//this the main screen - data entry (prompt)
						component.set("v.showMFEntry", true);
					}
					else if (screenToShow == 'Confirm') {
						//this is the confirm screen
						component.set("v.leadObj.Store_Pickup__c", 		  'Arcovia');
						component.set("v.leadObj.Customer_Type__c",   	  'Premium');
						component.set("v.leadObj.FirstName", 			  'TestFirstName');
						component.set("v.leadObj.MiddleName", 			  'TestMiddleName');
						component.set("v.leadObj.LastName", 			  'TestLastName');
						component.set("v.leadObj.Birthdate__c", 		  '2000-12-25');
						component.set("v.leadObj.Gender__c", 			  'Female');
						component.set("v.leadObj.Marital_Status__c",	  'Single');
						component.set("v.leadObj.Nationality__c",		  'Filipino');
						component.set("v.leadObj.Occupation__c",		  'President & CEO');
						component.set("v.leadObj.MobilePhone", 			  '091902347755');
						component.set("v.leadObj.Secondary_Mobile_No__c", '091781344316');
						component.set("v.leadObj.Email", 				  'test@test.com');
						component.set("v.leadObj.Street__c",			  'Cottage 14344');
						component.set("v.leadObj.Province__c",			  'Quezon Province');
						component.set("v.leadObj.City__c",   			  'Balisin Island');
						component.set("v.leadObj.Barangay__c", 			  'Balisin Resort');
						component.set("v.showConfirm", true);
					}
					else {
						//this is the thank you screen with the barcode
						component.set("v.FullName",  'TestFirstName MiddleName TestLastName');
						component.set("v.RefNumber", '299054619819');

						JsBarcode("#barcode", '299054619819', {
							lineColor: "#000000",
							width: 4,
							height: 40,
							fontSize: 20,
							displayValue: false
						});

						$A.util.toggleClass(component.find("thankyou"), "slds-hide");
					}
				}
			}
		});
		$A.enqueueAction(paction);
	},

	getCities : function(component, event, helper) {
		component.set("v.Boptions", '');
		console.log('we are in getCities!');
		var values = component.get("v.Poptions");
		var	itemValue = event.getSource().get("v.value");
		console.log('itemValue: ' + itemValue);
		var	selected  = values.find(value => value.Code__c == itemValue);
		console.log('selected: ' + selected.Name__c);
		//save both Code/value and Name of selected Province
		component.set("v.leadObj.Province__c", selected.Name__c);
		component.set("v.leadObj.Province_Code__c", itemValue);
		if (itemValue * 1 != 0) {
			var action = component.get("c.fetchCities");
			action.setParams({"Pcode": itemValue});
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					component.set("v.Coptions", response.getReturnValue());
				}
			});

			$A.enqueueAction(action);
		}
		else
			component.set("v.Coptions", '');
	},

	getBarangs : function(component, event, helper) {
		console.log('we are in getBarangs!');
		var values = component.get("v.Coptions");
		var	itemValue = event.getSource().get("v.value");
		console.log('itemValue: ' + itemValue);
		var	selected = values.find(value => value.Code__c == itemValue);
		console.log('selected: ' + selected.Name__c);
		//save both Code/value and Name of selected City
		component.set("v.leadObj.City__c", selected.Name__c);
		component.set("v.leadObj.City_Code__c", itemValue);

		if (itemValue * 1 != 0) {
			var action = component.get("c.fetchBarangs");
			action.setParams({"Ccode": itemValue});
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					component.set("v.Boptions", response.getReturnValue());
				}
			});

			$A.enqueueAction(action);
		}
		else
			component.set("v.Boptions", '');
	},

	saveBarangs : function(component, event, helper) {
		console.log('we are in saveBarangs');
		var values = component.get("v.Boptions");
		var	itemValue = event.getSource().get("v.value");
		console.log('itemValue: ' + itemValue);
		var	selected = values.find(value => value.Code__c == itemValue);
		console.log('selected: ' + selected.Name__c);
		//save both Code/value and Name of selected Barangay
		component.set("v.leadObj.Barangay__c", selected.Name__c);
		component.set("v.leadObj.Barangay_Code__c", itemValue);
	},

	saveStore : function(component, event, helper) {
		console.log('we are in saveStore');
		var values = component.get("v.Soptions"),
			itemValue = event.getSource().get("v.value"),
			selected = values.find(value => value.Code__c === itemValue);
		//save both Code/value and Name of selected Store to redeem
		component.set("v.leadObj.Store_Pickup__c", selected.Name__c);
		component.set("v.leadObj.Store_Pickup_Code__c", itemValue);
	},

	confirm : function(component, event, helper) {
		if(helper.validateLeadForm(component)) {
			//THE FOLLOWING ARE ADDITIONAL VALIDATIONS THAT ARE NOT INCLUDED IN THE DEFAULT
			//	COMPONENT VALIDATION (blank input)
			//validate age -- must be 18 and older but must not be over 105
			var xage = helper.computeAge(component.get("v.leadObj.Birthdate__c"));
			if (xage < 18 || xage > 105) {
				alert ("Oops.. you must be of legal age (18 or older) and must not be over 105!");
				return false;
			}
			//validate Mobile Phone format
			if (helper.validateMobile(component.get("v.leadObj.MobilePhone")) == false) {
				alert ("Oops.. For Mobile No. -- you have to conform to the required Mobile number pattern!\n\n" +
						"- Must be 11 digits long\n- Must start with 09\n- Must all be numbers");
				return false;
			}
			//validate Secondary Mobile Phone format if not NULL! (this field is optional)
			if (component.get("v.leadObj.Secondary_Mobile_No__c") != '') {
				if (helper.validateMobile(component.get("v.leadObj.Secondary_Mobile_No__c")) == false) {
					alert ("Oops.. For Secondary Mobile No. -- you have to conform to the required Mobile number pattern!\n\n" +
							"- Must be 11 digits long\n- Must start with 09\n- Must all be numbers");
					return false;
				}
			}
			//validate Email format
			if (_map.validateEmail(component.get("v.leadObj.Email")) == false) {
				alert ("Oops.. you have to conform to the required Email format!\n\n" +
						"- Must not have non-alpha or non-numeric characters other than the period or dot (.)\n" +
						"- Must have the @ sign\n" +
						"- Must have the domain type at the end (ex: .com, .ph, .info)");
				return false;
			}
			console.log('all additional validations okay');

			component.set("v.showMFEntry", false);
			component.set("v.showConfirm", true);
		}
	},

	goBack : function(component, event, helper) {
		component.set("v.showMFEntry", true);
		component.set("v.showConfirm", false);
	},

	save : function(component, event, helper) {
		//we immmediately disable the submit button to avoid double submission -- and YEEESS! it is working
		component.set("v.btisdisabled", true);
		//this one handles constructing the full name for Lead Company field and for display at the end
		var fullName = component.get("v.leadObj.FirstName") + " " + component.get("v.leadObj.MiddleName")
			+ " " + component.get("v.leadObj.LastName");
		component.set("v.FullName",  fullName);		//save to component variable
		//and this one generates our Reference Number.. mejo mahaba to.. 12 digits long
		//kinombine ko date ng birthdate tsaka yong last 10 digits ng milliseconds
		var refNo = ('00' + (new Date(component.get("v.leadObj.Birthdate__c")).getDate())).substr(-2)
			+ Date.now().toString().substr(-10);
		component.set("v.RefNumber", refNo);		//save to component variable

		//fill up Lead fields that are not getting direct input from input/select fields
		component.set("v.leadObj.Company", fullName);
		component.set("v.leadObj.LeadSource", component.get("v.leadSource"));
		component.set("v.leadObj.Campaign_Id__c", component.get("v.campaignId"));
		component.set("v.leadObj.ReferenceNumber__c", refNo);

		var action = component.get("c.createLeadRecord");
		action.setParams({"leadObj":component.get("v.leadObj")});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				//Prepare a toast UI message
				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"title": 	"Your application was successfully submitted.",
					"message":  "..."
				});
				resultsToast.fire();

				JsBarcode("#barcode", component.get("v.RefNumber"), {
					lineColor: "#000000",
					width: 4,
					height: 40,
					fontSize: 20,
					displayValue: false
				});

				component.set("v.showConfirm", false);
				$A.util.toggleClass(component.find("thankyou"), "slds-hide");
			}
			else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                }
				else {
                    console.log("Unknown error");
                }
			}
		});
		$A.enqueueAction(action);
	},

	handleAfterScriptsLoaded : function(component, event, helper) {
		console.log('jQuery Successfully Loaded');
	},

	handleAfterScriptsLoadedE : function(component, event, helper) {
		console.log('we are in handleAfterScriptsLoadedE');
		_map.validateEmail('test param');
	}
})