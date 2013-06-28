strings-toolkit
===============

Bitlancer Strings Toolkit


Terminology
===========

* Strings Chicken Environment: Puppet Infrastructure (puppet master, postgresql, puppetdb) plus strings control panel, strings MySQL, strings queue processor, and strings API servers
* Strings Customer Puppet Environment: A customer's puppet infrastructure (puppet master, postgresql, puppetdb)
* Stringed Infrastructure: Client infrastructure spun up by the Strings Chicken Environment and Puppetized utilizing the Strings Customer Puppet Environment


Strings Chicken Environment
===========================

To setup a Strings Chicken Environment (the one that lays the eggs):

1) Pick the OpenStack (Rackspace) account you're going to use to host the infrastructure.
2) Run infra/setup/create-base-image.sh to generate the base image for this account.
3) Run infra/setup/bootstrap-strings-infra.sh, passing in the base image ID, to spin up the infrastructure.
4) Profit.  You have a Strings Chicken Environment up and running.

To tear down a Strings Chicken Environment (no more eggs?):

1) Run infra/setup/teardown-strings-infra.sh.
2) Profit.  Your environment is gone.  You still have the base image, though!


Strings Customer Puppet Environment
===================================

To setup a Strings Customer Puppet Environment (the egg, essentially):

1) Run infra/setup/create-customer-dns.sh to create the customer DNS zones in their cloud account.
2) Create any cloud network in the customer's cloud accounts, if applicable.  This is a manual task.
3) Run system/setup/create-customer-schema.sh to create the customer inside the MySQL database (organization, base user, etc.).
4) Run openldap/setup/create-customer.sh to create the new customer database in the primary LDAP server.
5) Run infra/setup/bootstrap-customer-infra.sh, passing in the base image ID, to spin up customer puppet infrastructure.
