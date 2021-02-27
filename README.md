# render-handbrakeCLI-script
This is a script that make easier to use HandbrakeCLI.
The concept is to have some easy settings used with command-line, while writing complex ones hard-coded in the script. <br/>
Be nice, it's my first script with bash and my first attemnt to do something open-source. 

## Before Use
### Installation
- Make sure to install HandbrakeCLI in your distribution
- Copy `render.sh` in your system (suggested: `/opt`)
### Configuration
- Open  `render.sh` and 
	- change first line if you don't use bash (eg: `#!/bin/sh`)
	- set the two variables:
    	- `Output_dir`: is the directory where all output file are saved
    	- `ConfigDir`: is the directory where cofing-files (queue) is saved<br/>
    **NOTE**: be sure to have writing permit on that folders!
 - Under the `#ENCODER SETTINGS` you can set the major settings.<br/>
Check **HandbrakeCLI** if any setting is unclear. 
### Fast use (optional)
This will add the command with short name (no abs-path) in terminal
- `ln -s <full-path-to-render.sh> /bin/<name>`

## Usage
`render.sh inputFile.avi [-flag, ...]` <br/>
Do **NOT** stack flag in single dash (eg: `-fv`) <br/>
Actually, the script accept one input at time <br/>
### Help
```
This is a program to manage HandbrakeCLI easily.
User will eventually asked about input if:
  - more than one input-file is passed;
  - Output file already exists;
  - with --find-sub: which subfile add.
	NORMAL FLAGS
-q|--quality [int]			Set the quality
-p|--preset [medium|slow|slower, ...]	Set the preset
-s|--subtitle [file]			Add file to subtitles
-f|--find-sub				Search sub in dir and subdir of input file
-v|--verbose				Output is more talkative
	MODAL FLAGS
-F|--force				Activate ForceMode
-FI|--force-input (NOT YET)		First input-file is selected
-FO|--force-output (NOT YET)		Overwrite output-file without prompt
	QUEUE MANAGEMENT
-Q|--queue				Create the queue file or print it
-QA|--queue-add				Add current command to queue
-QX|--queue-exec			Run sequentialy commands in queue(Implict --force-output)(Current command is not added)

NOTE
ForceMode: no input from user will be asked.
  - with --find-sub: all files found added
 ```
 
 ## Security Issue
 - The `queue` file is a simple text-file where the complete HandbrakeCLI commands are saved. With `--queue-exec` the script will read and execute every line in that file, so be sure that no dangerous or malicious are not written.
 - Also, there is no sanitisation of the input.
