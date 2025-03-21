struct info{
char home[4095];
char cur[4095];
char prev[4095];
char pe[15][4095];
 int pasteventss;
 int top;
};
struct stringinfo{
    char** withoutspace;
    int* val;
};