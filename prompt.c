#include "headers.h"
// #include "structs.h"
char *substrig(char *path, char *home)
{
    // char home[4095];
    //  strcpy(home,info1->home);
    char *result = strstr(path, home);
    int n = strlen(home);
    int m = strlen(path);
    char *ans=(char*)malloc(sizeof(char)*4095);
    if (result != NULL)
    {  
        if(n==m) return NULL;
        for (int i = n; i < m; i++)
        {
            ans[i - n] = path[i];
        }
        return ans;
    }
    else
    {
        return path;
    }
}
void display(char *initial, struct info *info1)
{
    char home[4095];
    strcpy(home, info1->home);
    char current[4095];
    for(int i=0;i<4095;i++){
    current[i]='\0';
    }
    getcwd(current, sizeof(current));
    char *username = getenv("USER");
    char sysName[4095];
    gethostname(sysName, sizeof(sysName));
    char substrcheck[4095];
       printf("\033[0;32m");
    if(substrig(initial,home)==NULL){
        printf("<%s@%s:~>", username, sysName);
    printf("\033[0m");
    }
      
    else{

    
    strcpy(substrcheck,substrig(initial, home));
  
       printf("\033[0;32m");
    if (strlen(substrcheck) < strlen(initial))
    {
        printf("<%s@%s:~%s>", username, sysName, substrcheck);
    }
    else
    {
        printf("<%s@%s:%s>", username, sysName, current);
    }
    printf("\033[0m");
    fflush(stdout);
    }
}
void displayproperly(char *initial, struct info *info1)
{
    char home[4095];
    strcpy(home, info1->home);
    char current[4095];
    for(int i=0;i<4095;i++){
    current[i]='\0';
    }
    getcwd(current, sizeof(current));
    char *username = getenv("USER");
    char sysName[4095];
    gethostname(sysName, sizeof(sysName));
    char *substrcheck;
    substrcheck = (char *)malloc(sizeof(char) * 4095);
    printf("\033[0;34m");
    if(substrig(initial,home)==NULL){
        printf("%s",info1->home);
        //printf("<%s@%s:~>", username, sysName);
    printf("\033[0m");
    }
else{
    substrcheck = substrig(initial, home);
    // if (strlen(substrcheck) < strlen(initial))
    // {
    //     printf("~%s", substrcheck);
    // }
    // else
    // {
        printf("\033[0;34m");
        printf("%s", current);
    printf("\033[0m");
    fflush(stdout);
}
    // }
}
