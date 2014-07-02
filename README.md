argumentation-logic-visualizer
==============================

Visualization program for Argumentation Logic

This program was created in order to explore Argumentation Logic, a concept created by Prof. Antonis Kakas, Dr. Francesca Toni and Prof. Paolo Mancarella.

# Repository Contents:

The following is a table with the top level folders along with a description of what they contain:

Folder | Content Description
-|-
Client | Contains all of the GUI interface of the project
Core | Contains the implementations of the various Argumentation Logic algorithms
Presentation | Contains the slides for the presentation of the project
Report | Contains the souce code of the report
Server | Contains all the server files

# Project Structure Overview

The project, as sugessted by it's folder structure, is divided into 3 modules:
* Core Module
* Client Module
* Server Module

The Core module contains the code implementation of all the related Argumentation Logic algorithms. It is implemented in SWI-Prolog. This can be loaded and used on its own by consulting the bootstrap.pl file in a Prolog interpreter.

The Server module is also written in SWI-Prolog. This allows it to natively import the Core module and use it in order to serve requests from the Client. This module can be started by first editing the configuration file conf.pl and then firing it up by consulting the boostrap.pl file and a Prolog terminal and then calling the predicate boot/0.

The Client module acts as a front-end to the Core module, providing a nicer way of working with the Core.

# Setting up the project

The following is a quick start guide for setting up and running the project:
* Download the project into a directory of your preference
* Edit the Server/config.pl file and set the document root directory to be Client/web/. You can use a relative or absolute path but with a relative path you might need to run the server in a specific directory.
* In the same file, choose which port you'd like the server to run on
* Rename folder Client/web/js into Client/web/ps
* Rename folder Client/web/css into Client/web/cssss
* Open a SWI-Prolog terminal (interpreter)
* Consult the Server/bootstrap.pl file. This should load the entire server and core modules
* Issue the query "boot.", which starts the server on the specified port
* Open a browser (tested on Chrome) and navigate to "localhost:<port>" where <port> is your chosen port number

These steps should allow you to fire up the server and start the client that provides the GUI to the backend.
