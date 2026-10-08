@IsTest
public class ChinabankSweeperScheduler_Test {

    @IsTest
    static void testSchedulerTriggersQueueable() {
        // Define a CRON expression for 11 PM
        String cronExp = '0 0 23 * * ?';

        Test.startTest();
        // Schedule the job
        String jobId = System.schedule(
            'Test Chinabank Sweeper', 
            cronExp, 
            new ChinabankSweeperScheduler()
        );
        Test.stopTest();

        // Verify the job exists in the CronTrigger table
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];

        System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');
        System.assertEquals(0, ct.TimesTriggered, 'Job should not have run yet');
    }
}