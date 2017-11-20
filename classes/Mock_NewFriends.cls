@isTest
global class Mock_NewFriends implements HttpCalloutMock {
	
	private static string bodyContent;
	
    // Implement interface method to return a response in test
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setStatus('OK');
		createJSONPayload();
		res.setBody(bodyContent);
		return res;
	}
	
	//  Inner classes to serialize generated response
    public class customerDetails {
    	public string id;
    	public string firstName;
    	public string lastName;
    	public string gender;
    	public string title;
    }
	
	public string createJSONPayload() {
		list<customerDetails> cdList = new list<customerDetails>();
		for(integer i=1; i < 200; i++ ) {
			customerDetails cd = new customerDetails();
			cd.id = string.valueOf(i);
			cd.firstName = 'Test'+string.valueOf(i);
			cd.lastName = 'Customer'+string.valueOf(i);
			cd.gender = 'Female';
			cd.title = 'Mrs';
			cdList.add(cd);
		}
		string customers = JSON.serialize(cdList);
		bodyContent = '{"customers":'+customers+'}';
		system.debug('**  bodyContent : '+bodyContent);
		return bodyContent;
	}
}