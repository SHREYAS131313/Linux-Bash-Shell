[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/76mHqLr5)
# Description
Running the code : 1) make
                    2) ./a.out
My code has a main.c , where input is taken , split based on semicolons and checks if the process is bg or fg  and executes each function , which is in semicolonand.c file. This handles background and forground processes seperately and if it is a bash command uses execvp or else calls a function named functionn , which is in tmpmain.c file. This handles functions like warp , peek , proclore , pastevents. 
Also there are seperate files to handle warp , proclore and peek .

Structs.h contains info struct , which contains home directory, current directory and previous directory.

3 files named file.txt which has past 15 commands , top.txt which has the number pointing to current oldest element and paste.txt which has number of commands is generated on running ./a.out .
# Assumptions
