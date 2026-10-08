global class ChinabankStatusScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new ChinabankStatusQueueable());
    }
}