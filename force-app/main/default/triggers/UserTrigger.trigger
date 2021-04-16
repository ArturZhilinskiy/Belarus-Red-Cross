trigger UserTrigger on User (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

    TriggerDispatcher.run(new UserTriggerHandler(), Trigger.operationType);

}