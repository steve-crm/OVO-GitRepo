/*
Author  : Steven Edwards
Date    : November 2017
Usage   : This class implements Integration_Log__c trigger logic
*/
public with sharing class IntegrationLogTriggerDelegate extends TriggerHandler.DelegateBase {
    
    list<Integration_Log__c> logsToProcess;
    list<Contact> contactsToupdate;
    
    
    //  Inner classes to deserialize response
    public class repsonseBody {
		public customerDetails customer;
    }
    
    public class customerDetails {
    	public string id;
    	public string firstName;
    	public string lastName;
    	public string gender;
    	public string title;
    }
    
    repsonseBody respBod;
    
    public override void prepareBefore() {
    	logsToProcess = new list<Integration_Log__c>();
    }
    
    public override void prepareAfter() {
    	logsToProcess = new list<Integration_Log__c>();
    	contactsToupdate = new list<Contact>();
    	respBod = new repsonseBody();
    }
    
    public override void afterInsert(sObject o) {
    	Integration_Log__c newLog = (Integration_Log__c)o;
    	//  we want to check whether a paylod is returned for the contact processed by the contact trigger
    	if (newLog.Contact_Id__c != null && newLog.Contact_Id__c != '') {
    		logsToProcess.add(newLog);
    	}
    }
    
    public override void finish() {
    	if (logsToProcess.size() > 0 && !logsToProcess.isEmpty() ) {
    		processLogs(logsToProcess);
    	}
    }
    
    public void processLogs(list<Integration_Log__c> logs) {
    	for (Integration_Log__c L : logs) {
			respBod = (repsonseBody) JSON.deserialize(L.Response_Body__c, repsonseBody.class);
 			system.debug('** deserialized response respBod : '+respBod);
 			system.debug('** respBod.customer.firstName : '+respBod.customer.firstName);
 			if ( respBod.customer.firstName != null && respBod.customer.firstName != '') {
 				Contact C = new Contact (
 					Id = L.Contact_Id__c,
 					Loyalty_Status__c = 'Friendly');
 				contactsToupdate.add(C);
 			}
    	}
    	if(contactsToupdate.size() > 0 && !contactsToupdate.isEmpty() ) {
    		update contactsToupdate;
    	}
    }
}