@isTest
private class ourFriends_createNewContactsBatchTest {

    private static Contact testcon;
    private static customerDetails_Endpoint__c EP;
    
    static void prepareTestData(){
    	
    	//  Insert Custom Setting record for endpoint
    	EP = new customerDetails_Endpoint__c(
    		Name = 'All Customers',
    		endpoint_url__c = 'https://sheltered-depths-66346.herokuapp.com/customers'
    	);
    	insert EP;
    	
    	//  Insert Account
    	Account A = new Account(
    		Name = 'OVO Assignment'
    	);
    	insert A;
    	
    	//  Insert test Contact record
    	testCon = new Contact(
    		FirstName = 'Morty',
    		LastName = 'Smith',
    		Gender__c = 'Male',
    		Salutation = 'Mr'
    	);
    	insert testCon;
    }
	
    static testMethod void testNewFriendsBatch() {
        prepareTestData();
        //  Set mock callout class
    	Test.setMock(HttpCalloutMock.class, new Mock_NewFriends());
    	
    	//  Invoke batch
    	ourFriends_createNewContactsBatch ncb= new ourFriends_createNewContactsBatch();
		database.executebatch(ncb);
        
    }
}