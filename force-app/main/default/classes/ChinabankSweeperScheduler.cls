global class ChinabankSweeperScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new ChinabankSweeperQueueable());
    }
}