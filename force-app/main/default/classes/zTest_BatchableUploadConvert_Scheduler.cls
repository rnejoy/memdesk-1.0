@isTest
public class zTest_BatchableUploadConvert_Scheduler {

    @isTest
    static void testMyController() {
        Test.startTest();
        BatchableUploadConvert_Scheduler sh = new BatchableUploadConvert_Scheduler();
        String sch = '0 0 2 * * ?';
        system.schedule('Test Batchable Upload Convert Sheduler', sch, sh);
        Test.stopTest();
    }
}