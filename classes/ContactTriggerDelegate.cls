public without sharing class ContactTriggerDelegate extends TriggerHandler.DelegateBase {
    
    List<Contact> contactsToSetBefore;
    List<Contact> contactsToSetAfter;
    List<Contact> contactsToCheckFriendliness;
    
    public override void prepareBefore() {
    	contactsToSetBefore = new list<Contact>();
    	contactsToCheckFriendliness = new list<Contact>();
    }
    
    public override void prepareAfter() {
    	contactsToSetAfter = new list<Contact>();
    	contactsToCheckFriendliness = new list<Contact>();
    }
    
    public override void beforeInsert(sObject o) {
    	Contact newContact = (Contact)o;
    	newContact.Loyalty_Status__c = 'Standard';
    }
    
    public override void afterInsert(sObject o) {
    	Contact newContact = (Contact)o;
    	//  we want to check whether a value is included for ourFriendsID__c and add the Contact to a list to be processed against ourFriends if so 
    	if (newContact.ourFriendsID__c != null && newContact.ourFriendsID__c != '') {
    		contactsToCheckFriendliness.add(newContact);
    	}
    }
    
    public override void beforeUpdate(sObject old, sObject o) {
    	Contact oldContact = (Contact)old;
    	Contact newContact = (Contact)o;
    	//  set the value of Loyalty_Status__c if it's null - this is only required for records existing at the time of implementation, since new records will be given a value by the beforeInsert method
    	if (newContact.Loyalty_Status__c == null || newContact.Loyalty_Status__c == '' ) {
    		newContact.Loyalty_Status__c = 'Standard';
    	}
    	//  Loyalty_Status__c set to 'Standard' when ourFriendsID__c is cleared to ensure an accurate value based on a new callout
    	if ( (newContact.ourFriendsID__c == null || newContact.ourFriendsID__c == '') && newContact.ourFriendsID__c != oldContact.ourFriendsID__c) {
    		newContact.Loyalty_Status__c = 'Standard';
    	}
    	//  we want to check whether the value for ourFriendsID__c is being updated or added and add the Contact to a list to be processed against ourFriends if so
    	if (newContact.ourFriendsID__c != null && newContact.ourFriendsID__c != '' && newContact.ourFriendsID__c != oldContact.ourFriendsID__c) {
    		newContact.Loyalty_Status__c = 'Standard';
    		contactsToCheckFriendliness.add(newContact);
    	}
    }
    
    public override void finish() {
    	if (contactsToCheckFriendliness.size() > 0 && !contactsToCheckFriendliness.isEmpty() ) {
    		checkOurFriends(contactsToCheckFriendliness);
    	}
    }
    
    public void checkOurFriends(list<Contact> contactsToCheckFriendliness) {
    	for ( Contact C :  contactsToCheckFriendliness ) {
    		ourFriends_SpecificCustomer.makeCallout(C.ourFriendsID__c, C.Id);
    	}
    }
}