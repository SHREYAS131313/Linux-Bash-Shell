#include "headers.h"
int checkdir(char* file,struct info* info1){
    int x=chdir(file);
    chdir(info1->cur);
    return x;
}
char *getanydir(char *file,struct info* info1)
{
    char *ans;
    //file[strlen(file)-1]='\0';
    ans = (char *)malloc(4095);
    if (chdir(file) == 0)
    {
        // printf("Yes\n");
          
        //  strcpy(ans,file);
    }
    getcwd(ans, 4095);
//   else{
//     perror(chdir);
//   }
   
 //printf("111");
    return ans;
}