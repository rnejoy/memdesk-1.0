public class EraseRecords_Today implements Database.Batchable<SObject>,Database.AllowsCallouts{
    public String query2;
    
    public EraseRecords_Today(String query){
        query2 = query;
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query2);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        delete scope;
    }

    public void finish(Database.BatchableContext BC){
    }
}