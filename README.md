# Getting Started
See the Guide on how to contribute [here](https://github.com/Euklidian-Space/poll-sip/CONTRIBUTING.md#how-to-contribute) for instructions on how to fork and set up your repository.

# Installing Dependencies
In the root directory of your newly cloned project `mix deps.get`


---

Noob tip 

*If you can, "clone with `SSH` instead of clone with `HTTPS`. This means that, when you type in git remote add origin, you should use a link that looks like this: `git@github.com:*YOUR_USER_NAME/YOUR_REPO_NAME.git.*` Observe how that differs from* `https://github.com/YOUR_USER_NAME/YOUR_REPO_NAME.git`* 
While the first creates a remote that uses `ssh` authentication, the latter uses `https`, so it'll always prompt you to enter your username and password to authenticate the connection. For more see this [link](https://gist.github.com/juemura/899241d73cf719de7f540fc68071bd7d)*

---

# About Poll-Sip  
This is an open source project to be used, changed, given to anyone and by anyone.  The idea of this project is to build polling service that leverages the Elixir's concurrency model.  

Pull requests are welcome!

## Table of Contents

- [Main Goal](#main-goal)
- [Features](#features)
- [About the application](#about-the-application)
- [Where to get the files](#where-to-get-the-files)
- [Requirements](#requirements)
- [ToDo](#todo)


## Main Goal

The main goal of the app is to provide the user with a polling tool to be used in any Elixir application.

## Features

* **Users** will be able to:  
  * Create any number of polls they want.

* **Polls** will:
  * Be Elixir Processes.
  * Will be supervised, and thus have the fault tollerance built into an Elixir GenServer process. 


### *About the application*
* Built with the Elixir programming language.
* [MIT License](../blob/master/LICENSE)

### *Where to get the files*
* [This repository](https://github.com/Euklidian-Space/poll-sip)

## *Requirements*
* Requirements

## *ToDo*
* Improvements
