#include "headers.h"

void proclore(char* str,char* token,char* copy,char* check){
              
                copy[strlen(copy)]='\n';
                char *tok = strtok(copy, " \t\n");
                tok = strtok(NULL, " \t\n\0");
                // int hey=0;
                // char numb[256];
                // int jj=0;
             
                // for(int ii=8;ii<strlen(copy);ii++){
                //     if(!(copy[ii]==' ' || copy[ii]=='\t')){
                //         hey=1;
                //         numb[jj]=copy[ii];
                //         jj++;
                //     }
                // }
                int pid;
                if (strlen(token)==strlen(check) || tok==NULL || tok[0]=='\n' || tok[0]=='\t' )
                {
                    pid = getpid();

                    printf("pid : %d\n", pid);
                }
                else
                {  
                     pid=atoi(tok);
                    printf("pid : %d\n", pid);
                }

                    int pgid = getpgid(pid);
                    int fpgid = tcgetpgrp(STDIN_FILENO);
                    int fgbg; // 0 for bg 1 for fg
                    char vm[169];
                    char statttus[2];
                    if (fpgid == pgid)
                    {
                        fgbg = 1;
                    }
                    else
                    {
                        fgbg = 0;
                    }
                    char filePath[4095];
                    snprintf(filePath, 4095, "/proc/%d/status", pid);
                    FILE *file = fopen(filePath, "r");
                    char line[4095];
                    char vmsize[4095] = "VmSize:";
                    char status[4095] = "State";
                    int checkk = 0;
                    while (fgets(line, 4095, file) != NULL && checkk < 2)
                    {
                        char tempo[4095];
                        strcpy(tempo, line);
                        if (strstr(line, vmsize) != NULL)
                        {
                            char *token13 = strtok(line, " ");
                            token13 = strtok(NULL, " ");
                            strcpy(vm, token13);
                            checkk++;
                        }
                        if (strstr(line, status) != NULL)
                        {

                            checkk++;
                            statttus[0] = line[7];
                            if (fgbg == 1)
                            {
                                statttus[1] = '+';
                            }
                        }
                    }

//                     char symlinkPath[4096];
//     snprintf(symlinkPath, sizeof(symlinkPath), "/proc/%d/exe", pid);
//     char pathh[4096];
// ssize_t bytesRead = readlink(symlinkPath, pathh, 4095);
   

                    //  printf("pid : %d\n", pid);
                    printf("process status : %c%c\n", statttus[0], statttus[1]);
                    printf("Process Group : %d\n", fpgid);
                    printf("Virtual memory : %s\n", vm);
//                      if (bytesRead == -1) {
//         perror("readlink");

//     }

//     pathh[bytesRead] = '\0';
//     if (bytesRead != -1) 
//                      printf("executable path : %s\n", pathh);
}
