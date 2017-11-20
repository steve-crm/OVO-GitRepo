@isTest
public class ContactTriggerDelegate_Test {
    
    private static Contact testcon;
    private static customerDetails_Endpoint__c EP;
    
    static void prepareTestData(){
    	
    	//  Insert Custom Setting record for endpoint
    	EP = new customerDetails_Endpoint__c(
    		Name = 'Specific Customer',
    		endpoint_url__c = 'https://sheltered-depths-66346.herokuapp.com/customer?id='
    	);
    	insert EP;
    	
    	//  Set mock callout class
    	Test.setMock(HttpCalloutMock.class, new Mock_ourFriends_SpecificCustomer());
    	
    	//  Insert test Contact record
    	testCon = new Contact(
    		ourFriendsID__c = 'C-137',
    		FirstName = 'Rick',
    		LastName = 'Sanchez',
    		Gender__c = 'Male',
    		Salutation = 'Mr'
    	);
    	insert testCon;
    }
    
    static testMethod void testContactInsertAndUpdate() {
		prepareTestData();
		//  Making asserts here is awkward, given the @future method being used to make the callout...
		testCon.ourFriendsID__c = null;
		update testCon;
    }
}