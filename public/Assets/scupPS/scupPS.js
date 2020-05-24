var url = '/api';

var HttpClient = function() {
this.get = function(aUrl, aCallback, requesttype) {
        var anHttpRequest = new XMLHttpRequest();
        anHttpRequest.onreadystatechange = function() { 
            if (anHttpRequest.readyState == 4 && anHttpRequest.status == 200)
                aCallback(anHttpRequest.responseText);
        }
        requesttype = "GET";
        
        anHttpRequest.open( requesttype, aUrl, true );            
        anHttpRequest.send( null );
    }
}

function handleApprovalRequest(requestAction,requestID,userFirstname,userLastname,userMail,softwareTitle,machine,approverFirstname,approverLastname,approverMail) {

    var suburl = (url + '?operation=' + requestAction + 
                    '&submitrequestid=' + requestID );
                  
    var client = new HttpClient();
    
    if(requestAction == "AppRequest_deny" | requestAction == "AppRequest_revoke"){
        reason = window.prompt("Please enter the reason:");
        suburl = suburl + '&submitdenyreason='  + reason;
    }

    console.log(suburl);

    client.get( suburl, function(response) {
        alert(response);                
    }, "POST");

    document.getElementById('btn_approve_' + requestID).disabled = true;
    document.getElementById('btn_deny_' + requestID).disabled = true;
}