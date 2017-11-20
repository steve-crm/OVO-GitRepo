/*
Author  : Steven Edwards
Date    : November 2017
Usage   : This class completes batch processing of the newFriends 'customers' callout
*/
global class NewFriends implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
     
    string query = 'SELECT Id, ourFriendsID__c, Loyalty_Status__c FROM Contact WHERE ourFriendsID__c != null and Manual_Loyalty_Status__c = false';
    string queryInitial = 'SELECT Id, ourFriendsID__c, Loyalty_Status__c FROM Contact LIMIT 10';
    public Account A;
    public set<Contact> newContacts;
    public set<Contact> updatedContacts;
    
    //  Inner class to hold response for parsing
    public class Response {
    	public integer code {get; set;}
    	public string status {get; set;}
    	public string body {get; set;}
    	public boolean success {get; set;}
    	public string errorMessage {get; set;}
    	
    	public Response (integer code, string status, string body) {
    		this.code = code;
    		this.body = body;
    		this.status = status;
    		this.success = (code == 200);
    	}
    }
	
	//  Inner classes to deserialize response
    public class repsonseBody {
		public list<customerDetails> customers;
    }
    
    public class customerDetails {
    	public string id;
    	public string firstName;
    	public string lastName;
    	public string gender;
    	public string title;
    }
    
    public repsonseBody respBod = new repsonseBody();
    
    public NewFriends() {
    	A = [SELECT Id FROM Account WHERE Name = 'OVO Assignment'];  // in a real-life scenario, business logic would likely apply to this association but we're using a default for this exercise
    }
    
    public repsonseBody makeCallout() {
    	Response resp;
    	string endpoint = customerDetails_Endpoint__c.getValues('All Customers').endpoint_url__c;
    	string method = 'GET';
    	Integration_Log__c intlog = new Integration_Log__c();
    	Attachment att = new Attachment();
    	  	
    	//  check a callout can be performed, log an error if not
    	if ( limits.getCallouts() >= limits.getLimitCallouts() ) {
    		system.debug('**  limits.getCallouts() : '+limits.getCallouts());
    		system.debug('**  limits.getLimitCallouts() : '+limits.getLimitCallouts());
			intlog.Description__c = 'Callout Failed';
			intlog.Error_Message__c = 'Limit Exception - max number of callouts reached';
			intlog.Endpoint__c = endpoint;
			intlog.Method__c = method;
			insert intlog;
    	} else {
    		//  configure and perform the callout
    		HttpRequest req = new HttpRequest();
			req.setEndpoint(endpoint);
			req.setMethod(method);
    		
    		Http h = new Http();		
			HTTPResponse res = h.send(req);
			resp = new Response(res.getStatusCode(), res.getStatus(), res.getBody() );
			system.debug('**  resp : '+resp);
 			//  check response is parsed correctly
 			if (resp == null) {
    			intlog.Description__c = 'Failed to parse';
    			intlog.Error_Message__c = 'The response could not be parsed.';
    			intlog.Endpoint__c = endpoint;
    			intlog.Method__c = method;
    			intlog.Request__c = string.valueOf(req);
				intlog.Response__c = string.valueOf(res);
				intlog.Response_Code__c = string.valueOf(res.getStatusCode());
				intlog.Response_Status__c = res.getStatus();
				intlog.Response_Body__c = res.getBody();
				insert intlog;
 			} else {
	 			//  parse the repsonse
	 			respBod = (repsonseBody) JSON.deserialize(res.getBody(), repsonseBody.class);
	 			system.debug('**  respBod : '+respBod);
	 			//  Log successful callout
    			intlog.Description__c = 'Callout Succeeded';
    			intlog.Endpoint__c = endpoint;
    			intlog.Method__c = method;
				intlog.Request__c = string.valueOf(req);
				intlog.Response__c = string.valueOf(res);
				intlog.Response_Code__c = string.valueOf(res.getStatusCode());
				intlog.Response_Status__c = res.getStatus();
				intlog.Response_Body__c = 'All Customers payload potentially very large - see attachment responseBody.txt for content.';
	    		insert intlog;
	    		
	    		//  create an attachment to store the json response for batch processing
		    	att.Body = Blob.valueOf(res.getBody());
		        att.Name = 'ourFriends.txt';
		        att.OwnerId = UserInfo.getUserId();
		        att.ParentId = intlog.Id;      
		        att.IsPrivate = false; 
		        insert att;
 			}
    	}
    	return respBod;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
    	//  Initial run conditions - where no Contacts are returned by the query, we substitute the set with a handful of records to allow first-run processing
    	if(database.query(query).isEmpty()) {
    		query = queryInitial;
    	}
    	return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<Contact> scope) {
		
		//  Since the ContactTriggerDelegate creates all new contacts with 'Loyalty_Status__c = Standard' and matches any updated ourFriendsID__c values to set Loyalty_Status__c = Friendly
		//  we only need to update those at 'Friendly' that no longer appear to 'Standard', and insert new Contact records for unmatched ids
		newContacts = new set<Contact>();
	    updatedContacts = new set<Contact>();
	    makeCallout();
		
		//  Process update to Contact records where ourFriendsID__c no longer appears in the response
		for (Contact s : scope) {
			for (customerDetails cd : respBod.customers) {
				if (s.ourFriendsID__c == cd.Id) {
					break;
				} else {
					s.Loyalty_Status__c = 'Standard';
					updatedContacts.add(s);
				}
			}
		}
		//  perform updates to Contacts in each batch
		list<Contact> updatedContactsList = new list<Contact>(updatedContacts);
		update updatedContactsList;
	}
	
	global void finish(Database.BatchableContext BC) {
   		
   		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];
	   	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {a.CreatedBy.Email};
		mail.setToAddresses(toAddresses);
		mail.setSubject('ourFriends bacth reconciliation ' + a.Status);
		mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
		try { // use a try-catch block so hitting the single email limit (15 in a dev org) doesn't prevent the batch being processed
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		} catch (Exception e) {
			system.debug('**  Confirmation email not sent :'+e.getMessage());
		}	
			
	}	
}