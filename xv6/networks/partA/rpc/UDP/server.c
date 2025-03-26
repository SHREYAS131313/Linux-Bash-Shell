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
  int port1 = 12345;
  // atoi(argv[1]);
  int port2 = 23456;
  // atoi(argv[2]);

  int sockfd1, sockfd2;
  struct sockaddr_in server_addr1, server_addr2, client_addr1, client_addr2;
  char buffer[1024];
  char buffer2[1024];

  socklen_t addr_size;
  int n;

  // Create the first socket
  sockfd1 = socket(AF_INET, SOCK_DGRAM, 0);
  if (sockfd1 < 0)
  {
    perror("[-]socket error");
    exit(1);
  }

  // Set up the first server address
  memset(&server_addr1, '\0', sizeof(server_addr1));
  server_addr1.sin_family = AF_INET;
  server_addr1.sin_port = htons(port1);
  server_addr1.sin_addr.s_addr = inet_addr(ip);

  // Bind the first socket to the first port
  n = bind(sockfd1, (struct sockaddr *)&server_addr1, sizeof(server_addr1));
  if (n < 0)
  {
    perror("[-]bind error");
    exit(1);
  }

  // Create the second socket
  sockfd2 = socket(AF_INET, SOCK_DGRAM, 0);
  if (sockfd2 < 0)
  {
    perror("[-]socket error");
    exit(1);
  }

  // Set up the second server address
  memset(&server_addr2, '\0', sizeof(server_addr2));
  server_addr2.sin_family = AF_INET;
  server_addr2.sin_port = htons(port2);
  server_addr2.sin_addr.s_addr = inet_addr(ip);

  // Bind the second socket to the second port
  n = bind(sockfd2, (struct sockaddr *)&server_addr2, sizeof(server_addr2));
  if (n < 0)
  {
    perror("[-]bind error");
    exit(1);
  }
  bzero(buffer, 1024);
  bzero(buffer2, 1024);

  addr_size = sizeof(client_addr1);
  recvfrom(sockfd1, buffer, 1024, 0, (struct sockaddr *)&client_addr1, &addr_size);
  recvfrom(sockfd2, buffer2, 1024, 0, (struct sockaddr *)&client_addr2, &addr_size);

  printf("[Port %d] Data recv: %s\n", port1, buffer);
  printf("[Port %d] Data recv: %s\n", port2, buffer2);

  bzero(buffer, 1024);
  bzero(buffer2, 1024);

  strcpy(buffer, "Welcome to the UDP Server (Port 1).");
  strcpy(buffer2, "Welcome to the UDP Server (Port 2).");

  sendto(sockfd1, buffer, 1024, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
  sendto(sockfd2, buffer2, 1024, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2));

  printf("[Port %d] Data send: %s\n", port1, buffer);
  printf("[Port %d] Data send: %s\n", port2, buffer2);
  int deci = 0;
  while (1)
  {
    bzero(buffer, 1024);
    bzero(buffer2, 1024);
    // strcpy(buffer, "Enter your decision");
    // bzero(buffer, 1024);
    strcpy(buffer, "Enter your decision:0|1|2");
    strcpy(buffer2, "Enter your decision:0|1|2");

    printf("Server: %s\n", buffer);
    sendto(sockfd1, buffer, 1024, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
    sendto(sockfd2, buffer2, 1024, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2));

    char numA[1];
    recvfrom(sockfd1, numA, 1, 0, (struct sockaddr *)&client_addr1, &addr_size); // 0 | 1 | 2
    printf("received1\n");
    char numB[1];
    recvfrom(sockfd2, numB, 1, 0, (struct sockaddr *)&client_addr2, &addr_size);
    printf("received2\n");
    char result[1]; // wrt A // 0 rock 1 paper 2 scissor
    if (numA[0] == numB[0])
    {
      result[0] = 'D';

      printf("It is a draw\n");
      sendto(sockfd1, result, 1, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
      sendto(sockfd2, result, 1, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2));
    }
    else
    {
      if ((int)numA[0] > (int)numB[0])
      { 
        

        if (numA[0] != '2' || numB[0] != '0')
          result[0] = 'W';
        else
          result[0] = 'L';
        
      }
      if ((int)numA[0] < (int)numB[0])
      {
        if ((numA[0] == '0' && numB[0] == '2'))
          result[0] = 'W';
        else
          result[0] = 'L';
      }
      char antiresult[1];
      if (result[0] == 'W')
      {
        antiresult[0] = 'L';
        printf("Client A has won\n");
      }
      else if (result[0] == 'L')
      {
        antiresult[0] = 'W';
        printf("Client B has won\n");
      }
      sendto(sockfd1, result, 1, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
      sendto(sockfd2, antiresult, 1, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2));
    }
    //  char moregame;
    bzero(buffer, 1024);
    strcpy(buffer, "Do you want to play one more game, reply with Y/N ?");
    printf("Server: %s\n", buffer);
    sendto(sockfd1, buffer, 1024, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
    sendto(sockfd2, buffer, 1024, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2));

    char moregame1, moregame2;
    recvfrom(sockfd1, &moregame1, 1, 0, (struct sockaddr *)&client_addr1, &addr_size);
    recvfrom(sockfd2, &moregame2, 1, 0, (struct sockaddr *)&client_addr2, &addr_size);
printf("%c\n",moregame1);
printf("%c\n",moregame2);

sendto(sockfd1, &moregame2, 1, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
    sendto(sockfd2, &moregame1, 1, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2));


    if (moregame1 == 'N' || moregame2 == 'N')
    {
      deci = -1;
    }
    // char fdec[1];
    int stop = 1;
    char stopp='1';
    if (deci == -1)
    {
      stop = 0;
      stopp='0';
      sendto(sockfd1, &stopp, 1, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
      sendto(sockfd2, &stopp, 1, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr2));

      printf("[+]Client A disconnected.\n");
      printf("[+]Client B disconnected.\n");
      break;
    }
  }

      close(sockfd1);
      close(sockfd2);
  return 0;
}
