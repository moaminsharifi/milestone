# Milestone Prototype

This prototype is a simple representation of Miletone project.  
**milestone** is a shell script file running based on _~/.milestone_ and _~/.practices_ files.  
The _~/.milestone_ file contains the list of tasks in each line, e.g. ^C Programming Language$  
where ^ represents the beginning of the line and $ the end of the same line.  
Each task line must be prefixed with another line containing # at the biginning and a number as the level of priority of the tasks.  
Multiple tasks can have the same level of priority.  
e.g.  
```txt
\#1
C Programming Language
```

Each prefix can also hold the unit of progress and the combination of (done/total) pair, e.g. chapter, video, day, week, session  
e.g.  
```txt
\#1 chapter 7 / 20
C Programming Language
```

With this combination of [priority, progress and task name], milestone prototype will work properly.

The _~/.practices_ file also holds the practice category and topics tree branched by tab character.  
e.g.  
```txt
Cxx Programming Language
	Classes and Objects
	Templates and Type Aliases
	Standard Template Library
		Containers
			string, vector, list, queue, stack, map
		Algorithms
			fill, transport
	Logging
	Unit Testing
```

The lowest level branches are considered as practices, the top levels as categories.

## Milestone-Improved Objectives

* Database storage
* Online synchronization and accounting
* Milestone daemon (milestoned)
* Milestone client (milestone)
* Milestone server (milsetone-server)
* Standard roadmap structure
* Standard practice structure
* Basic GUI
* Milestone configuration file
* Multiple resource progress
* Progress Tracking on Resource and Skill
* Progress Tracking based on all related units
