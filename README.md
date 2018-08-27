# OrangeB

This is a simple app that loads transactions from a webservice (https://api.myjson.com/bins/1a30k8)

Each transactions has:
* id
* date
* description
* amount
* fee

Not all fields are mandatory. 
When the app is launched a REST request is sent to the endpoint and the different transactions are retrieved and stored in the internal database of the app (using Core Data)
Transactions with not a valid date format are not saved.
If there are transactions with the same ID only the newest is saved.

The user interface of the app is compound of a UITableViewController with three sections. The first section the user can see the total balance (the sum of all amounts taking the fees into account). In the second section the user can see the last transaction and in the last section all the previous transactions.

I have created some services to help in different tasks:

* RestService: This service allow us to make REST calls to the different endpoints using URLSession.
* CoreDataService: This service give us a layer to deal with all the Core Data operations like fetching, storing and deleting all the objects.
* ReachabilityService: This is a simple service that allow us to check if there is an active internet connection or not.
* TransactionManagerService: This service provides is responsible of getting the transactions (using the Rest Service) and storing them in the database using the Core Data service.

IMPROVEMENTS
There are some changes that can be made to improve the user experience.
* A different screen should be created for when there are no data to be shown
* Users should have the option to reload the table using a "Pull to refresh" gesture
