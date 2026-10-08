public class chinabankDelayedDispatcher implements Schedulable {

    private List<Id> contactIds;

    public chinabankDelayedDispatcher(List<Id> contactIds) {
        this.contactIds = contactIds;
    }

    public void execute(SchedulableContext sc) {
        ChinaBankTriggerService.sendContactsToChinaBank(contactIds);
    }

    public static void schedule(List<Id> contactIds, Integer delayMinutes) {

        Datetime runAt = System.now().addMinutes(delayMinutes);

        String cronExpression =
            runAt.second() + ' ' +
            runAt.minute() + ' ' +
            runAt.hour() + ' ' +
            runAt.day() + ' ' +
            runAt.month() + ' ? ' +
            runAt.year();

        System.schedule(
            'ChinabankDelay_' + System.currentTimeMillis(),
            cronExpression,
            new chinabankDelayedDispatcher(contactIds)
        );
    }
}