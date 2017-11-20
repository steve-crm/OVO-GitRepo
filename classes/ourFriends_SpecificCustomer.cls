/*
Author  : Steven Edwards
Date    : November 2017
Usage   : This class utilises the ourFriends service to return customer details based on the provided Id parameter
*/
public with sharing class ourFriends_SpecificCustomer {
    
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
	
    @future(Callout = true)
    //  callout is a future method since synchronous aren't permitted in a trigger context
    //  the streaming api could be used with a vf page utlising the apex:detail tag overriding the standard view page to allow a page update without the user having to refresh the page
    public static void makeCallout(string ourFriendsID, string ContactId) {
    	
    	Response resp;
    	string endpoint = customerDetails_Endpoint__c.getValues('Specific Customer').endpoint_url__c + ourFriendsID;
    	string method = 'GET';
    	list<Integration_Log__c> intLogs = new list<Integration_Log__c>();
    	//repsonseBody respBod = new repsonseBody();
    	
    	//  check a callout can be performed, log an error if not
    	if ( limits.getCallouts() >= limits.getLimitCallouts() ) {
    		intLogs.add(new Integration_Log__c(
    			Description__c = 'Callout Failed',
    			Error_Message__c = 'Limit Exception - max number of callouts reached',
    			Endpoint__c = endpoint,
    			Method__c = method
    		));
    	} else {
    	//  configure and perform the callout
    		HttpRequest req = new HttpRequest();
			req.setEndpoint(endpoint);
			req.setMethod(method);
    		
    		Http h = new Http();		
			HTTPResponse res = h.send(req);
			resp = new Response(res.getStatusCode(), res.getStatus(), res.getBody() );
 			//  check response is parsed correctly
 			if (resp == null) {
 				intLogs.add(new Integration_Log__c(
	    			Description__c = 'Failed to parse',
	    			Error_Message__c = 'The response could not be parsed.',
	    			Endpoint__c = endpoint,
	    			Method__c = method,
	    			Request__c = string.valueOf(req),
					Response__c = string.valueOf(res),
					Response_Code__c = string.valueOf(res.getStatusCode()),
					Response_Status__c = res.getStatus(),
					Response_Body__c = res.getBody(), 
					Contact_Id__c = ContactId
	    		));
 			} else {
	 			//  Log successful callout
	 			intLogs.add(new Integration_Log__c(
	    			Description__c = 'Callout Succeeded',
	    			Endpoint__c = endpoint,
	    			Method__c = method,
					Request__c = string.valueOf(req),
					Response__c = string.valueOf(res),
					Response_Code__c = string.valueOf(res.getStatusCode()),
					Response_Status__c = res.getStatus(),
					Response_Body__c = res.getBody(), 
					Contact_Id__c = ContactId
	    		));
 			}
    	}
    	//  insert Integration_Log__c records
    	if (intLogs.size() > 0 && !intLogs.isEmpty() ) {
    		Integration_Logging.createLogs(intLogs);
    	}
    }
}