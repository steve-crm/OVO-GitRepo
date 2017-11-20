public class BatchInsertContacts implements Database.Batchable<Contact> {

    public list<Contact> queue;
    
    public BatchInsertContacts(list<Contact> records) {
        queue = records;
    }
    
    public list<Contact> start(Database.BatchableContext bc) {
        return queue;
    }
    
    public void execute(Database.BatchableContext bc, list<Contact> records) {
        insert records;
    }
    
    public void finish(Database.BatchableContext bc) {
    }
}