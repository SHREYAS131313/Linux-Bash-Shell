#include "headers.h"
// #include "structs.h"
int main()
{
    FILE *file;
    file = fopen("file.txt", "a");
    FILE *top;
    FILE *pasteventsss;
    top = fopen("topp.txt", "a");
    pasteventsss = fopen("paste.txt", "a");
    fseek(file, 0, SEEK_END);
    long size = ftell(file);
    if (size == 0)
    {
        fprintf(top, "0");
        fprintf(pasteventsss, "0");
    }

   fclose(top);
   fclose(pasteventsss);
   fclose(file);

    struct info info1;
    char initial[1690];
    for(int i=0;i<1690;i++){
    initial[i]='\0';
    }
    getcwd(initial, sizeof(initial));
    strcpy(info1.home, initial);
    strcpy(info1.cur, initial);
    strcpy(info1.prev, initial);
    char lin[4095];
 file = fopen("file.txt", "r");
    top = fopen("topp.txt", "r");
    pasteventsss = fopen("paste.txt", "r");

    while (fgets(lin, 4095, top))
    {
        info1.top = atoi(lin);

    }
    lin[0] = '\0';
    while (fgets(lin, 4095, pasteventsss))
    {
        info1.pasteventss = atoi(lin);

    }
    lin[0] = '\0';
    int cow = 0;
    while (cow<info1.pasteventss && fgets(lin, sizeof(lin), file))
    {   lin[strlen(lin)-1]='\0';
        strcpy(info1.pe[cow], lin);
        cow++;
    }
    fclose(file);
    fclose(top);
    fclose(pasteventsss);
    int checkwarp = 0;

    while (1)
    {
        
        int ppresent = 0;
        // printf("--%d--",checkwarp);
            //  if (checkwarp == 0)
        display(info1.cur, &info1);
        char str[4095];
        char copy[4095];
        char check[4095];
        char *commands[4095];
        char inpuut[4095];
        char howmuch[4095];
        fgets(str, 4095, stdin);
        strcpy(check, str);
        strcpy(inpuut,str);
        strcpy(copy, str);
        strcpy(howmuch,str);
copy[strlen(copy)-1]='\0';
int num=0;
char *store[169];
int back[169];
        int count = 0;
        const char delim[] = {" /\n\t"};
char* tkn=strtok(inpuut,";\n");
while(tkn!=NULL){
    store[num]=strdup(tkn);
    int x=strlen(store[num]);
    for(int i=0;i<x;i++){
        if(store[num][i]=='&'){
            back[num]=1;
            store[num][i]='\0';
        }
    }
        //printf("..%s..",store[num]);
    // strcpy()
    num++;
    tkn=strtok(NULL,";\n");
}

// for(int i=0;i<num;i++){
//     if(store[i][strlen(store[i]-1)]=='&'){
//         back[i]=1;
//           store[i][strlen(store[i]-1)]='\0';
//       //  printf(",,%s..",store[num]);
//     }
  

// }       

        char warpp[13] = "warp";
    
        char *token1 = strtok(str, delim);
        int tab=0;
if(token1!=NULL){


       if (strcmp(token1,"pastevents") != 0)
        //if(strstr(howmuch,"pastevents")==NULL)
        {
            if (info1.pasteventss == 0)
            {
                strcpy(info1.pe[0], copy);

                // for(int i=0;i<info1.pe[])
                info1.pasteventss = 1;
            }
            else
            {
       
                if (strcmp(info1.pe[info1.pasteventss - 1], copy) != 0 || tab==-1)
                {
                    if (info1.pasteventss <= 14)
                    {
                        strcpy(info1.pe[info1.pasteventss], copy);
                        info1.pasteventss = info1.pasteventss + 1;
                    }
                    else
                    {
                        info1.pe[info1.top][0] = '\0';
                        strcpy(info1.pe[info1.top], copy);
                        info1.top = ((info1.top) + 1) % 15;
                    }
                }
            }
        }
    }
           // printf("..%s..\n",info1.pe[0]);

       for(int i=0;i<num;i++){
      //  printf("%s",store[i]);
// char *token=strtok(store[i],delim);
// printf("%s",store[i]);
seperatecomp(&info1,store[i],back[i]);
       }

        chdir(info1.home);
        file = fopen("file.txt", "w");
        top = fopen("topp.txt", "w");
        pasteventsss = fopen("paste.txt", "w");
        char buff1[4095], buff2[4095];
        sprintf(buff1, "%d", info1.top);
        sprintf(buff2, "%d", info1.pasteventss);
        fprintf(top, "%s", buff1);
        fprintf(pasteventsss, "%s", buff2);
        for (int i = 0; i < info1.pasteventss; i++){
            fprintf(file, "%s\n", info1.pe[i]);
        }
        fclose(file);
        fclose(top);
        fclose(pasteventsss);
        chdir(info1.cur);
    }
}

