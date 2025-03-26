#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

int main()
{

  char *ip = "127.0.0.1";
  int port = 23456;
  // atoi(argv[1]);

  int sockfd;
  struct sockaddr_in addr;
  char buffer[1024];
  socklen_t addr_size;

  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  memset(&addr, '\0', sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  addr.sin_addr.s_addr = inet_addr(ip);

  bzero(buffer, 1024);
  strcpy(buffer, "Hello, World!");
  sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, sizeof(addr));
  printf("[+]Data send: %s\n", buffer);

  bzero(buffer, 1024);
  addr_size = sizeof(addr);
  recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, &addr_size);
  printf("[+]Data recv: %s\n", buffer);
  int deci = 0;
  while (1)
  {
    bzero(buffer, 1024);
    recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&addr, &addr_size);
    if (buffer[strlen(buffer) - 1] == '\n')
    {
      buffer[strlen(buffer) - 1] = '\0';
    }
    printf("Server: %s\n", buffer);
    char num[1];
    // fflush(stdout);
    scanf("\n");
    scanf("%c", &num[0]);
    printf("ClientB: %c\n", num[0]);
    sendto(sockfd, num, 1, 0, (struct sockaddr *)&addr, sizeof(addr));
    char res[0];
    recvfrom(sockfd, res, 1, 0, (struct sockaddr *)&addr, &addr_size);
    printf("Server: %c\n", res[0]);
    if (res[0] == 'W')
    {
      printf("You Win\n");
    }
    else if (res[0] == 'D')
    {
      printf("It is a Draw\n");
    }
    else if (res[0] == 'L')
    {
      printf("You Lost\n");
    }
    bzero(buffer, 1024);
    recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&addr, &addr_size);
    if (buffer[strlen(buffer) - 1] == '\n')
    {
      buffer[strlen(buffer) - 1] = '\0';
    }
    printf("Server: %s\n", buffer);
    char more;
    scanf("\n%c", &more);
    // printf("%c\n",more);
    int rec=1;
  char recc;
    sendto(sockfd, &more, 1, 0, (struct sockaddr *)&addr, sizeof(addr));
    recvfrom(sockfd, &recc, 1, 0, (struct sockaddr *)&addr, &addr_size);
  // printf("%c\n",recc);

    if (more=='N' || recc=='N')
    {
      deci = -1;
    }

    if (deci == -1)
    {
      printf("Disconnected from the server.\n");
      break;
    }
  }
      close(sockfd);

  return 0;
}