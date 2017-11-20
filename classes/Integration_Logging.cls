/*
Author  : Steven Edwards
Date    : November 2017
Usage   : This class performs the insertion of Integration_Log__c records generated in response to a callout to the ourFriends service returning customer details based on the provided Id parameter
*/
public with sharing class Integration_Logging {
    
    public static void createLogs(list<Integration_Log__c> logs) {
    	if (logs.size() > 0 && !logs.isEmpty() ) {
    		try {
    			insert logs;
    		} catch (Exception e) {
    			system.debug('**  Integration_Log__c failed : '+e.getMessage() );
    		}
    	}
    }
}