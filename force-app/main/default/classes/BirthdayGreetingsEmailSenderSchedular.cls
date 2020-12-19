public with sharing class BirthdayGreetingsEmailSenderSchedular implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        Database.executebatch(new BirthdayGreetingsEmailSenderBatch(), 200);
    }
    
}