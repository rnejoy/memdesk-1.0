public with sharing class chinaBankTriggerService {

    @future(callout=true)
    public static void sendContactsToChinaBank(List<Id> contactIds) {

        for (Id conId : contactIds) {
            try {
                chinabankAPIService.sendToBank(conId);
            } catch (Exception ex) {
                System.debug('Error sending Contact to China Bank: ' + conId + ' | ' + ex.getMessage());
            }
        }
    }
}