/*
Author  : Steven Edwards
Date    : November 2017
Usage   : This class implements a generic handler for all triggers, allowing all logic to be maintained in classes for simpler bulkification
*/
public with sharing class TriggerHandler {
    
    //  Interface for trigger delegate
	public interface Delegate 	{
		void prepareBefore();
		void prepareAfter();
		void beforeInsert(SObject o);
		void beforeUpdate(SObject old, SObject o);
		void beforeDelete(SObject o);
		void afterInsert(sObject o);
		void afterUpdate(sObject old, sObject o);
		void afterDelete(sObject o);
		void afterUndelete(sObject o);
		void finish();
	}
	
	//  Abstract implementation of Interface
	public abstract class DelegateBase implements Delegate {
		public virtual void prepareBefore() {}
		public virtual void prepareAfter() {}
		public virtual void beforeInsert(SObject o) {}
		public virtual void beforeUpdate(SObject old, SObject o) {}
		public virtual void beforeDelete(SObject old) {}
		public virtual void afterInsert(SObject o) {}
		public virtual void afterUpdate(SObject old, SObject o) {}
		public virtual void afterDelete(SObject o) {}
		public virtual void afterUndelete(SObject o) {}
		public virtual void finish() {}
	}
	
	//  Execution
	public static void execute(Delegate d) {
		//  Before
		if (Trigger.isBefore) {
			d.prepareBefore();
			if (Trigger.isInsert) {
				for (SObject o : Trigger.new) {
					d.beforeInsert(o);
				}
			} else if (Trigger.isUpdate) {
				for (SObject old : Trigger.old) {
					d.beforeUpdate(old, Trigger.newMap.get(old.id));
				}
			} else if (Trigger.isDelete) {
				for (SObject old : Trigger.old) {
					d.beforeDelete(old);
				}
			}
		} else { //  After
			d.prepareAfter();
			if (Trigger.isInsert) {
				for (SObject o : Trigger.new) {
					d.afterInsert(o);
				}
			} else if (Trigger.isUpdate) {
				for (SObject old : Trigger.old) {
					d.afterUpdate(old, Trigger.newMap.get(old.id));
				}
			} else if (Trigger.isDelete) {
				for (SObject old : Trigger.old) {
					d.afterDelete(old);
				}
			}
		}
		//  and finally
		d.finish();
	}	
}