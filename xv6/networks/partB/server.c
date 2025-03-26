#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <time.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/time.h>


int main() {
   
    char ip[16]="127.0.0.1";
    int port =12345;
    // atoi(argv[1]);

    int sockfd;
    struct sockaddr_in addr, client_addr;
    socklen_t addr_size;

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("[-]socket error");
        exit(1);
    }
    struct timeval mytime[1024];

    memset(&addr, '\0', sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = INADDR_ANY;


    int flags = fcntl(sockfd, F_GETFL, 0);
    if (flags == -1)
    {
        perror("fcntl");
        exit(1);
    }
    if (fcntl(sockfd, F_SETFL, flags | O_NONBLOCK) == -1)
    {
        perror("fcntl");
        exit(1);
    }
    int n = bind(sockfd, (struct sockaddr*)&addr, sizeof(addr));
    if (n < 0) {
        perror("[-]bind error");
        exit(1);
    }

    addr_size = sizeof(client_addr);
 char buffer[1024];
    bzero(buffer, 1024);
 fgets(buffer, sizeof(buffer), stdin);
    // char token[1024];
    // bzero(token);
    int store[1024];
    char *strstore[1024];
    for (int i = 0; i < 1024; i++)
    {
        store[i] = 0;
    }
    int count = 0;
    char *token = strtok(buffer, " \t");
    strstore[count] = strdup(token);
    count++;
    while (token != NULL)
    {
        token = strtok(NULL, " \t");
        strstore[count] = strdup(token);
        char num[10];
        sprintf(num,"`%d",count);
        strcat(strstore[count],num);
    }
    int ans = 0;

    //   while (ans < count)
    // {   
        for (int i = 0; i < count; i++)
        {
            if (store[i] == 0)
            {   
                // store[i] = 1;

                ans++;
                char temp[10];
                bzero(temp,sizeof(temp));
                sprintf(temp,"%d",i);
            
            sendto(sockfd, strstore[i], sizeof(strstore[i]), 0, (struct sockaddr *)&addr, sizeof(addr));
        bzero(buffer,sizeof(buffer));
  recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, &addr_size);
            printf("Client:received chunk no %d",i);
            // sendto(sockfd, temp, sizeof(temp), 0, (struct sockaddr *)&addr, sizeof(addr));
            
            // sendto(sockfd,)
            
            }
        }

    // }
    char yess[1]="1";
    sendto(sockfd, yess, sizeof(yess), 0, (struct sockaddr *)&addr, sizeof(addr));
       
   while(1){
  recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, &addr_size);
    if(buffer[0]=='1'){
        printf("Client:Transmission Complete\n");
        break;
    }
    char *ackn;
    char* tok=strtok(buffer,"`");
    printf("Client: %s\n",tok);
    tok=strtok(NULL,"`");
    ackn=strdup(tok);
    sendto(sockfd, ackn, sizeof(ackn), 0, (struct sockaddr *)&addr, sizeof(addr));
    
   }

    return 0;
}
