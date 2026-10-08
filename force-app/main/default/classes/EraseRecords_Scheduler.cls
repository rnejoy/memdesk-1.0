public class EraseRecords_Scheduler implements Schedulable{
    
    public void execute(SchedulableContext SC) {
        String query = 'SELECT Id FROM Transaction__c';
        EraseRecords_Today eraseToday = new EraseRecords_Today(query);
        Id eraserBatch = Database.executeBatch(eraseToday, 10000);
    }
}