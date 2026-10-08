global class ChinabankStatusSchedulerV2 implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new ChinabankStatusQueueable());
    }
}