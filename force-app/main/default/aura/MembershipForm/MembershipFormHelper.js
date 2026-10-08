({
	getParameterByName: function(name) {
		console.log('we are in getParameterByName');
		name = name.replace(/[\[\]]/g, "\\$&");
		var url = window.location.href;
		var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
		var results = regex.exec(url);
		if (!results) return null;
		if (!results[2]) return '';
		//console.log(name + ": " + decodeURIComponent(results[2].replace(/\+/g, " ")));

		return decodeURIComponent(results[2].replace(/\+/g, " "));
	},

	computeAge: function(inputString) {
		console.log('we are in computeAge');
		//itong getAge function na to.. kopya ko lang din to sa internet.. pahirapan pa ako.. altho meron naman ako alam
		//	na basic na basic.. current year minus year of birth.. O Di BA!!!! ito accurate to the day (date)
		var today = new Date();
		var birthDate = new Date(inputString);
		var age = today.getFullYear() - birthDate.getFullYear();
		var m = today.getMonth() - birthDate.getMonth();
		if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
			age--;
		}

		return age;
	},

	validateMobile: function(inputString) {
		console.log('we are in validateMobile');
		if (inputString.length < 11 || /^09/.test(inputString) == false || /^[0-9]{11}/.test(inputString) == false)
			return false;
		else
			return true;
	},

    validateLeadForm: function(component) {
        var validLead = true;
        // Show error messages if required fields are blank
        var allValid = component.find('leadField').reduce(function (validFields, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);
        if (!allValid) {
            validLead = false;
        }

        return(validLead);
    }
})