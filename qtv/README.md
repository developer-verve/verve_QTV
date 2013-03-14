# Quick TV

### Welcome to the Quick TV application, the following are instructions for getting up and running with a local development environment.

The Quick TV application consists of a server application built on the Play! Framework and 2 Flex applications which share a set of actionscript libraries.

Quick TV is closely integrated with the Amazon Web Services and 3rd party video hosting solutions so you'll need an open internet connection when developing the application.
	
We've provided a setup script that does a lot of the heavy lifting of getting your machine set up. We'll set up a couple of new directories under /usr/local but, other than that, we won't be doing anything outside of the directory this file is in.
	
Other than the files in and under this directory you'll require:
	
1. Play! Framework v1.2.4 
2. Flex Framework 4.6.0.23201B
3. MySQL 5.x
	
1 and 2 are provided by the setup script, we assume that MySQL is already installed and you'll need to manually configure a user and a database as specified at "Setup MySQL" below.

## Requirements

### Before you go any further you're going to need a couple of things setup (we _could_ do this step in the setup script that follows, and we probably will, but we don't have time to write it just now).

1. Install Haxe
2. Install the following libraries via haxelib

	nme
	mconsole
	msignal
	minject
	mmvc
	polygonal-core
	polygonal-ds
	hamcrest
	actuate

## Setup Environment and Dependencies

### The following are instructions on using the setup script to configure your machine for development of Quick TV

You'll first need to make the setup script executable, so run
	
	chmod +x setup.sh
	
then run the script (with sudo to ensure privileges) with the relevant arguments:
	
	sudo ./setup.sh {build environment} {git branch name}

If you're just setting up for development then use the following command
	
	sudo ./setup.sh development html5
	
this will:
	
* Create /usr/local directory if it doesn't already exist.
* Download the Play! framework to the /usr/local directory.
* Create a symlink /usr/local/play-current pointing to the downloaded version.
* Assign the 'development' id to your play framework installation.
* Download the Flex Framework to the /usr/local directory.
* Create a symlink /usr/local/flex-current pointing to the downloaded version.
* Create your build-user.properties file from the checked-in template.
* Checkout all the required projects from github and googlecode.
* Set the development path for NME in Haxelib to the Quick TV fork of the NME project.
* Rebuild the NME command line tools.
* Resolve dependencies for the web application.
* Create the eclipse project files for the web application.
* Run the ant build for all projects.

## Setup MySQL

### Once the setup script has successfully executed everything you need is in place, but the server won't be able to persist any data until it can connect to MySQL.

If you check the qtv-play-webapp/conf/application.conf file you'll see the connection string configuration that Play! uses. If you're not familiar with play's config format don't worry just follow these instructions.

1. Create a new MySQL user with username: quicktv password: fishesdog22 
2. Create a new MySQL database with the name 'quicktv'.
3. Give the new 'qtv' user all privileges on the 'quicktv' database.

If you don't have the time - here's the commands to give MySQL (once you're logged in)

	create user 'quicktv'@'localhost' identified by fishesdog22
	grant all privileges on quicktv.* to 'quicktv'@'localhost' with grant option
	create database quicktv;

That's it, Play! should now be able to talk to MySQL

## Setup Flash Builder

### Once the setup script has successfully executed everything you need is in place, but to comfortably write code for the application you'll need to configure your IDE - we only support Flash Builder right now.

Open Flash Builder and follow the instructions below:
	
1. Open Flash Builder->Preferences
2. Select General->Workspace->Linked Resources
3. Click 'New' and add a new Linked Resouce with:
	
	Name: QTV_ROOT
	Location: {browse to the directory that contains this file}
	
4. Click Ok to add the new resource
5. Select File->Import
6. Select 'Existing Projects into Workspace'
7. Browse to the directory containing this file.
8. Select 'Open' Flash Builder should find 5 projects:
	
	qtv-flex-editor-vod
	qtv-flex-management-client
	qtv-play-webapp
	
9. Unselect any other project Flex Builder has picked up - you just want these 3.
10. Select 'Finish' and Flash Builder will import the projects for you.

## Running the Application

### Once you've setup the environment and your IDE you're ready to run the application locally, the following instructions will show you the easiest way to do this.

#### In Flash Builder:
	
* Expand the qtv-java-webapp project
* Expand the /eclipse folder
* Right-click on the qtv-java-webapp.launch file
* Select Run As->qtv-java-webapp

#### From the Terminal

if Play! Framework directory is on your path you can just do

play run

from within the qtv-play-webapp directory, this will start the server and start logging to the console.

Whichever way you do it - next you'll want to:

* Open a web browser and point it at
	
	http://localhost:9000
	
it'll take a few seconds but you'll start seeing output from the server in the Flash Builder console. The server will run through a bootstrap routine that may take a few minutes the first time it runs. When it's complete you'll see the login page in the browser. You'll be able to login with:
	
	email: trevor.burton@quicktvpro.com
	pass: trevor.burton
	
You can run the qtv-flex-management-client project as a normal flex project once you've logged in to the browser.