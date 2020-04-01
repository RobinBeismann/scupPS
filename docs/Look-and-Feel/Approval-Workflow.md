# Approval Workflow
The approval workflow allows the costcenter owner to approve requests for his users.
Users can simply ask for the Software using the MEMCM/SCCM builtin application approval workflow.

The following pictures briefly show how it works.

## Application Deployment in MEMCM/SCCM
To make a application eligible for this workflow, deploy it as "Available" to a User Collection and tick the Checkbox "An administrator must approve a request for this application on the device".

![Deployment-1](https://raw.githubusercontent.com/RobinBeismann/scupPS/master/docs/images/app_deploy_1.png)

![Deployment-2](https://raw.githubusercontent.com/RobinBeismann/scupPS/master/docs/images/app_deploy_2.png)

## Request
The user will now see this application as "Approval Required" in the Software Center and needs to fulfill the reason field and click Request

![Request-1](https://raw.githubusercontent.com/RobinBeismann/scupPS/master/docs/images/softwarecenter_request.png)

The user will see his request history after clicking "Request"

![Request-1](https://raw.githubusercontent.com/RobinBeismann/scupPS/master/docs/images/softwarecenter_requested.png)

## Approval
The manager will now see his request in scupPS and can now either approve or deny it. The manager needs to put in a denial reason which the user can see in the Software Center and which will be shown in the mail.
As soon as the manager approves the request, the MEMCM/SCCM will trigger the installation on the client.
The manager has the option to revoke a software approval which will trigger an uninstallation on the client and make the request form in the Software Center available again.

**Attention: Make sure that your Application has a proper uninstall routine which takes care of closing the application if it is inuse**


![scupPS-1](https://raw.githubusercontent.com/RobinBeismann/scupPS/master/docs/images/scupPS_pendingRequest.png)


## Mail Notifications
The user will receive the following mails depending on the actions taken in the user portal.
The text can be customized in the file "views\api\AppRequest.ps1".

![mail-1](https://raw.githubusercontent.com/RobinBeismann/scupPS/master/docs/images/mail_approved.png)
![mail-2](https://raw.githubusercontent.com/RobinBeismann/scupPS/master/docs/images/mail_denied.png)
![mail-3](https://raw.githubusercontent.com/RobinBeismann/scupPS/master/docs/images/mail_revoked.png)