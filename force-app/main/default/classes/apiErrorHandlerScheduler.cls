global class apiErrorHandlerScheduler implements schedulable {
    global void execute(schedulableContext sc){
      apiErrorHandler.retriggerFailed();
    }
    

}