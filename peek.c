#include "headers.h"
void peeking(char *strr, char *copy, char *check, struct info *info1)
{
  char str[4095];
  strcpy(str,copy);
    char hii[4095];
    strcpy(hii, copy);
char hoho[4095];
strcpy(hoho,copy);
char hehe[4095];
hehe[0]='.';

char* token2=strtok(hoho," \t");
while(token2!=NULL){

    strcpy(hehe,token2);
    token2=strtok(NULL," \t");
}
    char path[4095];
    char temp[4095];
    char slash[2];
    slash[0] = '/';
    int checkpath = 0;
    for (int i = 0; i < strlen(hii); i++)
    {
        if (hii[i] == '/')
        {
            checkpath = 1;
        }
    }
    int what=0;
    int huha=0;
   // printf("%d",checkpath);
    if((checkpath!=1)&&(hehe[0]!='-' && hehe[0]!='~' && hehe[0]!='.')){
        checkpath=1;
        what=1;
    }
     if((hehe[0]!='-' && hehe[0]!='~' && hehe[0]!='.')){
        huha=1;
    }

    char hey[4095];
    strcpy(hey, hii);
    char *token1 = strtok(hey, " \t");
    token1 = strtok(NULL, " \t");
    if (checkpath == 1)
    {   if(what==1){
        strcpy(path,hehe);
    } 
    else {
        if (strstr(token1, slash) != NULL)
        {
            strcpy(path, token1);
        }
        else
        {
            token1 = strtok(NULL, " \t");
            if (strstr(token1, slash) != NULL)
            {
                strcpy(path, token1);
            }
            else
            {
                token1 = strtok(NULL, " \t");
                if (strstr(token1, slash) != NULL)
                {
                    strcpy(path, token1);
                }
            }
        }
    }
    }
    else
    {
        char *token = strtok(hii, " \t");

        token = strtok(NULL, " \t"); //-l
        strcpy(temp, token);
        token = strtok(NULL, " \t"); //-a
        if (token == NULL)
        {
            strcpy(path, temp);
        }
        else
        {
            strcpy(temp, token);         // temp=-a
            token = strtok(NULL, " \t"); // ~
                                         // if(token==NULL){
            strcpy(path, temp);          //~ /-
                                         // }
        }
    }
    char tmp[4095];
for(int i=0;i<strlen(hehe);i++){
    if(path[i]=='\n'){
        path[i]='\0';
        
    }
}
// printf("%d",checkpath);
    if (checkpath == 1)
    {   
       
        chdir(path);
        char haha[13];

        int j = 0;
        for (int i = 0; i < strlen(str) - 2; i++)
        {
            if (str[i] == '-')
            {
                haha[j] = str[i + 1];
                j++;
                if (str[i + 2] != ' ')
                {

                    haha[j] = str[i + 2];
                    j++;
                }
            }
        }
        if (j == 0)
        {
            haha[0] = 's';
        }
        peekprint(str, copy, check, info1, haha);
        chdir(info1->cur);
    }
    else
    {
        char one[13] = ".";
        char two[13] = "..";
        char three[13] = "~";
        char four[13] = "-";
        char getonthedancefloor[13]="hi";
        char haha[13];

        int j = 0;
        for (int i = 0; i < strlen(str) - 2; i++)
        {
            if (str[i] == '-')
            {
                if ((i + 1) < strlen(str) || str[i + 1] != ' ')
                {
                    haha[j] = str[i + 1];
                    j++;
                    if (str[i + 2] != ' ')
                    {

                        haha[j] = str[i + 2];
                        j++;
                    }
                }
            }
        }
        if (j == 0)
        {
            haha[0] = 's';
        }

        if (strcmp(three, path) != 0 && strcmp(four, path) != 0)
        {
            chdir(path);
            
            peekprint(str, copy, check, info1, haha);   
            chdir(info1->cur);
        }
        else
        {
            if (path[0] == '~')
            {
                chdir(info1->home);
                printf("%s\n",info1->home);
                peekprint(str, copy, check, info1, haha);
                chdir(info1->cur);
            }
            if (path[0] == '-')
            {
                chdir(info1->prev);
                peekprint(str, copy, check, info1, haha);
                chdir(info1->cur);
            }
        }
    }
}

void print_file_details(const char *path, struct dirent *entry)
{
    struct stat st;
    if (lstat(path, &st) == -1)
    {
        perror("lstat");
        return;
    }

    // File permissions
    char perms[11];
    snprintf(perms, sizeof(perms), "%c%c%c%c%c%c%c%c%c%c",
             (S_ISDIR(st.st_mode)) ? 'd' : '-',
             (st.st_mode & S_IRUSR) ? 'r' : '-',
             (st.st_mode & S_IWUSR) ? 'w' : '-',
             (st.st_mode & S_IXUSR) ? 'x' : '-',
             (st.st_mode & S_IRGRP) ? 'r' : '-',
             (st.st_mode & S_IWGRP) ? 'w' : '-',
             (st.st_mode & S_IXGRP) ? 'x' : '-',
             (st.st_mode & S_IROTH) ? 'r' : '-',
             (st.st_mode & S_IWOTH) ? 'w' : '-',
             (st.st_mode & S_IXOTH) ? 'x' : '-');

    struct passwd *pwd = getpwuid(st.st_uid);
    struct group *grp = getgrgid(st.st_gid);

    struct tm *timeinfo;
    timeinfo = localtime(&st.st_mtime);
    char time_str[64];
    strftime(time_str, sizeof(time_str), "%b %d %H:%M", timeinfo);

    printf("%s %4ld %s %s %8lld %s %s\n",
           perms, (long)st.st_nlink, pwd->pw_name, grp->gr_name,
           (long long)st.st_size, time_str, entry->d_name);
}

void peekprint(char *str, char *copy, char *check, struct info *info1, char *haha)
 {
     //  printf("%s\n",haha);
//     printf ("%d\n",strcmp(haha,"al "));
    struct dirent **namelist;
    int n = scandir(".", &namelist, NULL, alphasort);
    if (n == -1)
    {
        perror("scandir");
    }   
    else
    {
        char la[13] = "la";
        char al[13] = "al";
        if (haha[0] == 's')
        {
            for (int i = 0; i < n; i++)
            {
                if (namelist[i]->d_name[0] != '.')
                {
                    printf("%s\n", namelist[i]->d_name);
                }
            }
        }
        else if (strlen(haha)>1 && ((haha[0]=='l' && haha[1]=='a') || ((haha[0]=='a' && haha[1]=='l')) ))
        {
            for (int i = 0; i < n; i++)
            {

                print_file_details(namelist[i]->d_name, namelist[i]);

                // free(namelist[i]);
            }
        }
        else if(haha[0]=='l'){
               for (int i = 0; i < n; i++)
            {
                if(namelist[i]->d_name[0]!='.')
                print_file_details(namelist[i]->d_name, namelist[i]);

                // free(namelist[i]);
            }
        }
        else{ //-a
            for(int i=0;i<n;i++){
                
                    printf("%s\n", namelist[i]->d_name);
                
            }
        }

        // for (int i = 0; i < n; i++)
        // {
        //     free(namelist[i]);
        // }

        // free(namelist);
    }

 }