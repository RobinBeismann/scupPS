# scupPS
Just another System Center User Panel made to address missing features of the SCCM/MEMCM Approval Function.

## What does this Portal offer?
This portal on one hand offers a interface that builts upon the native SCCM Software Center Approval Workflow and allows the costcenter manager to approve application requests for his users and on the other hand allows the helpdesk to view useful informations about computers like inventoried software and updates derived from the SCCM Hardware Inventory.
* **MEMCM / SCCM Support**
  * Supports all MEMCM/SCCM Versions starting from 1906
  * Tested on:
    * MEMCM 2002
    * MEMCM 1910
    * SCCM 1906
  * Limited functionality:
    * SCCM 1902
  * Works no matter if the Feature "Approve application requests for users per device" is enabled or not
* **Application Approval Workflow**
  * *Supports all Application Model based Apps in MEMCM/SCCM*
  * **Manager View**
    * View pending Approval Requests which were started by your users using the native Software Center
    * View the history of Approval Requests for your Costcenter
    * Approve, Deny or Revoke Requests of Software for your Costcenter
  * **User View**
    * View your own requests and their Status
  * **Admin View**
    * See all requests and approve, deny or revoke them
    * Pre-create Requests for a User on a specific Machine
* **Helpdesk Functions**
  * **List Client Details**: View a hardware summary of a client (Manufacturer, Model, Serialnumber, Name, Domain, Memory, Disks and Config Manager Client details)
  * **List Computers**: View computers, their primary user, last activity, last AD Site and the last logged on User per Collection
  * **List Computer Summary**: View a list of device models sorted by count
  * **List Software**: View installed Updates of a client
  * **List Task Sequence Status**: View the status of currently running or recently run task sequences
  * **List Updates**: View installed Software on a client



## What technologies are used?
This panel runs on a Powershell 7.0 based Webserver called [Pode](https://github.com/Badgerati/Pode) and can/should be hosted as a IIS Website.
The website itself has no own database and gets all informations from the MEMCM/SCCM using the CIM Interface (previously WMI).
Authentication to the website is handled by the IIS hosting the Pode Instance, this can be anything that IIS supports, mostly Kerberos or Claim based SAML Authentication.

## Sounds cool, show me more!
Checkout [the documentation](https://www.scupPS.de), it holds the installation guideline and a presentation of its functions!
