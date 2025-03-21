#include "headers.h"

void seperatecomp(struct info *info1, char *string, int backg)
{
    // printf("%d",backg); //------------------------------
    // int pid = fork();
    char tmppp[4095];
    strcpy(tmppp, string);
    char *args[100] = {"/bin/sh", "-c", tmppp, NULL};

    char nexttmp[4095];
    strcpy(nexttmp, string);

    char *first = strtok(nexttmp, " \n\t");
    int i = 0;
    if (!(strcmp(first, "warp") == 0 || strcmp(first, "peek") == 0 || strcmp(first, "seek") == 0 || strcmp(first, "proclore") == 0 || (strcmp(first, "pastevents") == 0)))
    {

        int pid = fork();
        if (pid == -1)
        {
            perror("fork");
        }
        else if (pid == 0)
        {  
            if (execvp("/bin/sh", args) != 0)
            {
                printf("No command");
                exit(1);
            }
        }
        else
        {
            if (backg == 0)
            {
                struct timeval start, end;
                gettimeofday(&start, NULL);

                int status;
                waitpid(pid, &status, 0);

                gettimeofday(&end, NULL);
                double elapsed = (end.tv_sec - start.tv_sec) +
                                 (end.tv_usec - start.tv_usec) / 1000000.0;

                printf("%s : %.0fs\n", args[0], elapsed);
            }
            else
            {
                printf("[%d]\n", pid);
                
                
            }
        }
    }
    else
    {

        functionn(info1, tmppp);
    }
}
