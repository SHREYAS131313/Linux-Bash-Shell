#include "headers.h"
// #include "structs.h"

void extrafunc(struct info *info1,char* str){
       char copy[4095];
        char check[4095];
        char *commands[4095];
        char inpuut[4095];
        char howmuch[4095];
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
            if (info1->pasteventss == 0)
            {
                strcpy(info1->pe[0], copy);

                // for(int i=0;i<info1.pe[])
                info1->pasteventss = 1;
            }
            else
            {
       
                if (strcmp(info1->pe[info1->pasteventss - 1], copy) != 0 || tab==-1)
                {
                    if (info1->pasteventss <= 14)
                    {
                        strcpy(info1->pe[info1->pasteventss], copy);
                        info1->pasteventss = info1->pasteventss + 1;
                    }
                    else
                    {
                        info1->pe[info1->top][0] = '\0';
                        strcpy(info1->pe[info1->top], copy);
                        info1->top = ((info1->top) + 1) % 15;
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
seperatecomp(info1,store[i],back[i]);
       }
}






void functionn(struct info *info1, char *str)
{

    int checkwarp = 0;

    int ppresent = 0;

    char copy[4095];
    char check[4095];
    char *commands[4095];

    strcpy(check, str);
    strcpy(copy, str);

    int count = 0;
    const char delim[] = {" /\n\t"};

    char warpp[13] = "warp";

    char *token = strtok(str, delim);
    //  printf("%s..",token);

    if (strcmp(token, warpp) == 0)
    {
        checkwarp = 1;
        token = strtok(NULL, delim);
        if (token == NULL)
        {
            strcpy(info1->prev, info1->cur);
            strcpy(info1->cur, info1->home);
              printf("\033[0;34m");
            printf("%s\n", info1->home);
    printf("\033[0m");
            chdir(info1->home);
            // checkwarp = 0;
        }
        while (token != NULL)
        {
            char x[2] = "~";
            char y[2] = "-";
            if (token[0] == '~' || strcmp(x, token) == 0)
            {
                char path[4095];
                strcpy(info1->prev, info1->cur);

                strcpy(path, info1->home);
                strcat(path, token + 1);
                strcpy(info1->cur, path);
                chdir(path);
                displayproperly(info1->cur, info1);
                token = strtok(NULL, delim);
                printf("\n");
            }
            else if (strcmp(y, token) == 0)
            {
                char tmp[4095];
                strcpy(tmp, info1->cur);
                strcpy(info1->cur, info1->prev);
                strcpy(info1->prev, tmp);
                chdir(info1->cur);
                displayproperly(info1->cur, info1);
                token = strtok(NULL, delim);
                printf("\n");
            }
            else
            {

                strcpy(info1->prev, info1->cur);
                strcpy(info1->cur, getanydir(token, info1));

                displayproperly(info1->cur, info1);

                token = strtok(NULL, delim);
                printf("\n");
            }
        }
    }
    else
    {
        char *pro = "proclore";
        char *peekk = "peek";
        char *past = "pastevents";
        if (strcmp(pro, token) == 0)
        {
            proclore(str, token, copy, check);
        }
        else if (strcmp(peekk, token) == 0)
        {
            peeking(str, copy, check, info1);
            // printf("0");
        }
        else if (strcmp(past, token) == 0)
        {

            token = strtok(NULL, " \t");
            if (token == NULL)
            {
                // if(info1.pasteventss==15){
                int hh = 0;
                int hhhh = info1->top;
                while (hh < info1->pasteventss)
                {
                    //functionn(info1,info1->pe[hhhh]);
                     printf("%s\n",info1->pe[hhhh]);
                    hhhh = (hhhh + 1) % 15;
                    hh++;
                }
                // }
            }
            else if (strcmp(token, "purge") == 0)
            {
                info1->pasteventss = 0;
                info1->top = 0;
                for (int i = 0; i < 15; i++)
                {
                    info1->pe[i][0] = '\0';
                }
            }
            else
            {
                token = strtok(NULL, " \t");
                int x = atoi(token);
                // printf("%d\n",x);
                if (x > info1->pasteventss)
                {
                    printf("event too old");
                }
                else
                {
                    char ppp[4095];
                    int intex;
                    if (info1->pasteventss < 15)
                    {
                        intex = info1->pasteventss - x;
                    }
                    else
                    {
                        intex = (info1->top + 15-x) % 15;
                    }
                    char huhuhu[4095];
                    strcpy(huhuhu,info1->pe[intex]);
                    // printf("%s",huhuhu);
                    extrafunc(info1, huhuhu);
                }
            }
        }
    }
}
