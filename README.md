# OrangeB

This is a simple app that loads transactions from a webservice (https://api.myjson.com/bins/1a30k8)

Each transactions has:
* id
* date
* description
* amount
* fee

Not all fields are mandatory. 
When the app is launched a REST request is sent to the endpoint and the different transactions are retrieved and stored in the internal database of the app (using Core Data).
Transactions with not a valid date format are not saved.
If there are transactions with the same ID only the newest is saved.

The user interface of the app is compound of a UITableViewController with three sections. In the first section the user can see the total balance (the sum of all amounts taking the fees into account). In the second section the user can see the last transaction and in the last section all the previous transactions.

## I have created some services to help in different tasks:

* RestService: This service allow us to make REST calls to the different endpoints using URLSession.
* ReachabilityService: This is a simple service that allow us to check if there is an active internet connection or not.
* TransactionManagerService: This service provides is responsible of getting the transactions (using the Rest Service) and storing them in the database using the Core Data service.
* CoreDataService: This service give us a layer to deal with all the Core Data operations like fetching, storing and deleting all the objects. The service also give us the tools for a lighweight migration. This means that if in a future version of the app the database model changes a new database storage file will be created with this new model.


## IMPROVEMENTS
There are some changes that can be made to improve the overall status of the app.
* A different screen should be created for when there is no data to be shown
* Users could have the option to reload the table using a "Pull to refresh" gesture
* Implement UITableViewDataSourcePrefetching to allow a better scrolling experience for when there are a lot of transactions to be shown on the list
* Develop a pagination system to retrieve the list of transactions using pages. Some changes should be made to the webservice in order to achieve this. With this system the app could retrieve only the items needed for the visible cells of the table instead of the whole list of transactions.
* Some Unit Tests were developed to assure that UITableView follows the datasource and delegate protocols but more unit tests can be developed to increase the code coverage of the app something that helps if the team wants to establish a CI environment.
* In a more complex application UI tests would be neccessary to test the screen flow.

![alt text](https://github.com/VictorVarLed/OrangeB/blob/master/Screenshot.png)


