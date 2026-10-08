({
	doInit : function(component, event, helper) {
		helper.loadContacts(component);
		helper.getPictureURL(component);
	},
})