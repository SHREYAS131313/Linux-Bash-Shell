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

  int sockfd;
  struct sockaddr_in server_addr;
  char buffer[1024];

  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0)
  {
    perror("[-]socket error");
    exit(1);
  }

  memset(&server_addr, '\0', sizeof(server_addr));
  server_addr.sin_family = AF_INET;
  server_addr.sin_port = htons(port);
  server_addr.sin_addr.s_addr = inet_addr(ip);

  int n = connect(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr));
  if (n < 0)
  {
    perror("[-]connect error");
    exit(1);
  }

  bzero(buffer, 1024);
  // strcpy(buffer, "Hello, World!");
  // send(sockfd, buffer, strlen(buffer), 0);
  // printf("[+]Data send: %s\n", buffer);

  // bzero(buffer, 1024);
  // recv(sockfd, buffer, sizeof(buffer), 0);
  // printf("[+]Data recv: %s\n", buffer);

  int deci = 0;
  while (1)
  {
    bzero(buffer, 1024);
    recv(sockfd, buffer, sizeof(buffer), 0);
    printf("Server: %s\n", buffer);
    if (buffer[strlen(buffer) - 1] == '\n')
    {
      buffer[strlen(buffer) - 1] = '\0';
    }

    char num[1];
    scanf("\n");
    scanf("%c", &num[0]);
    printf("ClientB: %c\n", num[0]);
    send(sockfd, num, 1, 0);

    char res[1];
    recv(sockfd, res, 1, 0);
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
    recv(sockfd, buffer, sizeof(buffer), 0);
    if (buffer[strlen(buffer) - 1] == '\n')
    {
      buffer[strlen(buffer) - 1] = '\0';
    }
    printf("Server: %s\n", buffer);

    char more;
    scanf("\n%c", &more);
    send(sockfd, &more, 1, 0);

    char recc;
    recv(sockfd, &recc, 1, 0);

    if (more == 'N' || recc == 'N')
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
