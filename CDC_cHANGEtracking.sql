/*
SQL Server Change Data Tracking Explained (YouTube Tutorial Style)

In SQL Server, there are two built-in features that help track changes made to data:

Change Data Capture (CDC)
Change Tracking (CT)

Both allow you to detect inserts, updates, and deletes without building custom solutions using triggers or audit tables.

Why Do We Need Change Tracking?

Imagine you have an application, data warehouse, or reporting system that needs to know when data changes.

Instead of creating:

Triggers
Timestamp columns
Audit tables

SQL Server provides built-in features that are easier to manage and usually perform better.

Option 1: Change Data Capture (CDC)

Think of CDC as a full audit trail.

When a row changes, CDC records:

What operation occurred (Insert, Update, Delete)
Which columns changed
The old and new values
Historical records of all changes

CDC works by reading the SQL Server transaction log and storing change information in special change tables.

Example

Suppose a customer record changes:

CustomerID	Name	Salary
1	John	50000

Salary is updated to 60000.

CDC can tell you:

The row was updated
Salary changed from 50000 to 60000
When the change occurred
Best For
Auditing
Compliance
ETL processes
Data warehouses
Historical reporting
Option 2: Change Tracking (CT)

Think of Change Tracking as a lightweight notification system.

It tells you:

"This row changed."

But it does not tell you:

What the old value was
What the new value was
The complete history
Example

If John's salary changes from 50000 to 60000:

Change Tracking simply records:

CustomerID 1 was updated.

Your application must then read the current value from the table.

Best For
Mobile app synchronization
Data synchronization between systems
Applications that only need current data
CDC vs Change Tracking
Change Data Capture (CDC)

✔ Stores history
✔ Stores changed values
✔ Tracks inserts, updates, and deletes
✔ Good for auditing

Change Tracking (CT)

✔ Tracks changed rows only
✔ Minimal storage usage
✔ Lower overhead
✔ Good for synchronization

Quick Analogy

Imagine a security camera system:

CDC

Like recording video footage.

You can go back and see:

What happened
When it happened
What changed
Change Tracking

Like a motion sensor.

It only tells you:

Something changed here

It doesn't show the details.

Which One Should You Use?

Use CDC when you need:

Audit history
Reporting
ETL processes
Detailed change information

Use Change Tracking when you need:

Fast synchronization
Low storage overhead
Only the latest version of the data
Key Exam/Interview Question

What is the main difference between CDC and Change Tracking?

Answer:
CDC stores the actual data changes and historical information, while Change Tracking only records that a row changed and does not store the changed values.

*/
