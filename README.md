# scupPS
Just another System Center User Panel made to address missing features of the SCCM/MEMCM Approval Function.

## What does this Portal offer?
This portal on one hand offers a interface that builts upon the native SCCM Software Center Approval Workflow and allows the costcenter manager to approve application requests for his users and on the other hand allows the helpdesk to view useful informations about computers like inventoried software and updates derived from the SCCM Hardware Inventory.

## What technologies are used?
This panel runs on a Powershell 7.0 based Webserver called [Pode](https://github.com/Badgerati/Pode) and can/should be hosted as a IIS Website.
The website itself has no own database and gets all informations from the MEMCM/SCCM using the CIM Interface (previously WMI).
Authentication to the website is handled by the IIS hosting the Pode Instance, this can be anything that IIS supports, mostly Kerberos or Claim based SAML Authentication.
