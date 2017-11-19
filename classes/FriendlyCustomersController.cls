/*
Author  : Steven Edwards
Date    : November 2017
Usage   : Page controller for the FriendlyCustomers visualforce page
*/
public with sharing class FriendlyCustomersController {
    
    public Integer noOfRecords{get; set;}
    public Integer size{get;set;}
    public ID unfriendIdentifier {get; set;}
    
    //  We'll use a standard set controller to allow pagination of the potentially large data set
    public ApexPages.StandardSetController setCon {
        get{
            if(setCon == null){
                size = integer.valueOf(friendsListPageSize__c.getValues('Initial value').PageSize__c);
                string queryString = 'SELECT Id, Name, Gender__c, Account.Name FROM Contact WHERE Loyalty_Status__c = \'Friendly\' ORDER BY Name ASC';
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
                setCon.setPageSize(size);
                noOfRecords = setCon.getResultSize();
            }
            return setCon;
        }set;
    }
    
    Public List<Contact> getContacts(){
        List<Contact> conList = new List<Contact>();
        for(Contact c : (List<Contact>)setCon.getRecords())
            conList.add(c);
        return conList;
    }
     
    public pageReference refresh() {
        setCon = null;
        getContacts();
        setCon.setPageNumber(1);
        return null;
    }
     
    public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
    }
    
    public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
    }
  
    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }
  
    public void first() {
        setCon.first();
    }
  
    public void last() {
        setCon.last();
    }
  
    public void previous() {
        setCon.previous();
    }
  
    public void next() {
        setCon.next();
    }
    
    public void unfriend() {
    	Contact C = new Contact(
    		Id = unfriendIdentifier,
    		Loyalty_Status__c = 'Unfriendly',
    		Manual_Loyalty_Status__c = true);
    	update C;
    	refresh();
    }
}