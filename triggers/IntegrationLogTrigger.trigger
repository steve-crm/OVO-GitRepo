trigger IntegrationLogTrigger on Integration_Log__c (
	after delete, 
	after insert, 
	after undelete, 
	after update, 
	before delete, 
	before insert, 
	before update) {
    
    TriggerHandler.execute(new IntegrationLogTriggerDelegate());
}