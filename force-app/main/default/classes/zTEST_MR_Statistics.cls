@isTest
public class zTEST_MR_Statistics {

    @isTest static void testMyController() {

        Test.StartTest();
            MR_Statistics controller = new MR_Statistics();
            controller.getStats();
        Test.StopTest();
    }
}