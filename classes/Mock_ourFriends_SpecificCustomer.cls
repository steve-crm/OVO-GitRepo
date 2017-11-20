@isTest
global class Mock_ourFriends_SpecificCustomer implements HttpCalloutMock {

    // Implement interface method to return a response in test
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"customer": {"id": "C-137","firstName": "Rick","lastName": "Sanchez","gender": "Male","title": "Mr"}}');
        res.setStatusCode(200);
        res.setStatus('OK');
		return res;
	}
}