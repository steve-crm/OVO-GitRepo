/*
Author  : Steven Edwards
Date    : November 2017
Usage   : This class schedules the batchable NewFriends class
*/
global class Schedule_ourFriends implements Schedulable {
    global void execute(SchedulableContext SC) {
        NewFriends nf= new NewFriends();
		database.executebatch(nf);
    }   
}