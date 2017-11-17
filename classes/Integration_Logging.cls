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