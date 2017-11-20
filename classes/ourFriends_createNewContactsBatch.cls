/*
Author  : Steven Edwards
Date    : November 2017
Usage   : This class creates new Contacts for entries in the response payload that don't match an existing Contact
*/
global class ourFriends_createNewContactsBatch implements Database.Batchable<customerDetails>, Database.AllowsCallouts, Database.Stateful {
    string query = 'SELECT Id, ourFriendsID__c, Loyalty_Status__c FROM Contact WHERE ourFriendsID__c != null and Manual_Loyalty_Status__c = false';
    string queryInitial = 'SELECT Id, ourFriendsID__c, Loyalty_Status__c FROM Contact LIMIT 10';
    public Account A;
    public set<Contact> newContacts;
    
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
    global class repsonseBody {
		public list<customerDetails> customers;
    }
    
    global class customerDetails {
    	public string id;
    	public string firstName;
    	public string lastName;
    	public string gender;
    	public string title;
    }
    
    public repsonseBody respBod = new repsonseBody();
    
    public ourFriends_createNewContactsBatch() {
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
    
    global list<customerDetails> start(Database.BatchableContext BC) {
    	makeCallout();
    	return respBod.customers;
	}
	
	global void execute(Database.BatchableContext BC, List<customerDetails> scope) {
		
		newContacts = new set<Contact>();
	    if(database.query(query).isEmpty()) {
    		query = queryInitial;
    	}
    	list<Contact> Contacts =  database.query(query);
		//  Process creation of new contact records
		/*  Rapid growth of this set (>10000 records in a single interval) will cause issues - since the scope is driven by the set of Contact records returned by the query locator
			A possible solution would be to complete the insertion of these records in a further batch invocation, but this can't be demonstrated since only a single executeBatch call is allowed in tests
			I've included an untested call to the BatchInsertContacts class as an example, but since this is and edge case I've left it at that
		*/
		for (customerDetails cd : scope) {
			boolean hasMatch = false;
			for (Contact s : Contacts) {
				if (s.ourFriendsID__c == cd.Id) {
					hasMatch = true;
				}
			}
			if (!hasMatch) {
				Contact C = new Contact(
					ourFriendsID__c = cd.id,
    				FirstName = cd.firstName,
    				LastName = cd.lastName,
    				Gender__c = cd.gender,
    				Salutation = cd.title,
					Loyalty_Status__c = 'Friendly',
					AccountId = A.Id,
					createdByBatch__c = true
				);
				newContacts.add(C);
			}
		}
		list<Contact> newContactsList = new list<Contact>(newContacts);
		insert newContactsList;
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