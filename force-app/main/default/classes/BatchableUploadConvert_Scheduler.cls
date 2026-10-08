public class BatchableUploadConvert_Scheduler implements Schedulable {
    public void execute(SchedulableContext SC) {
        BatchableUploadConvert batchjob = new BatchableUploadConvert();
        Database.executeBatch(batchjob, 10);
    }
}