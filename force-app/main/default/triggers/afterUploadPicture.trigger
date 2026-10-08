//Important!  SendBulkMembersDataToAllStores.SendMembers must be commented/uncommented based on requirements. 


trigger afterUploadPicture on Contact (after update,After Insert) {
    afterUploadPicture.processDecodeURL(trigger.newMap, trigger.oldMap);
        
    //to Mridul.. for not respecting my trigger and updating it by adding code.. BS to you!!!!!
    //don't ever add again because I am going to delete whatever you add.. always
    //   THIS IS MY TRIGGER
}