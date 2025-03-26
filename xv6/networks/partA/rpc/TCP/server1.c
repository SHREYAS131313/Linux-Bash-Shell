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
    int port2 = 23456;

    int server_sock1, client_sock1, server_sock2, client_sock2;
    struct sockaddr_in server_addr1, client_addr1, server_addr2, client_addr2;
    socklen_t addr_size;
    char buffer[1024];
    char buffer2[1024];

    server_sock1 = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock1 < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }

    memset(&server_addr1, '\0', sizeof(server_addr1));
    server_addr1.sin_family = AF_INET;
    server_addr1.sin_port = htons(port1);
    server_addr1.sin_addr.s_addr = inet_addr(ip);

    int n1 = bind(server_sock1, (struct sockaddr *)&server_addr1, sizeof(server_addr1));
    if (n1 < 0)
    {
        perror("[-]Bind error");
        exit(1);
    }

    listen(server_sock1, 1);
    printf("[Port %d] Listening for a client...\n", port1);

    addr_size = sizeof(client_addr1);
    client_sock1 = accept(server_sock1, (struct sockaddr *)&client_addr1, &addr_size);
    printf("[Port %d] Client 1 connected.\n", port1);

    server_sock2 = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock2 < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }

    memset(&server_addr2, '\0', sizeof(server_addr2));
    server_addr2.sin_family = AF_INET;
    server_addr2.sin_port = htons(port2);
    server_addr2.sin_addr.s_addr = inet_addr(ip);

    int n2 = bind(server_sock2, (struct sockaddr *)&server_addr2, sizeof(server_addr2));
    if (n2 < 0)
    {
        perror("[-]Bind error");
        exit(1);
    }

    listen(server_sock2, 1);
    printf("[Port %d] Listening for a client...\n", port2);

    addr_size = sizeof(client_addr2);
    client_sock2 = accept(server_sock2, (struct sockaddr *)&client_addr2, &addr_size);
    printf("[Port %d] Client 2 connected.\n", port2);

    int deci = 0;
    while (1)
    {
        bzero(buffer, 1024);
        bzero(buffer2, 1024);

        strcpy(buffer, "Enter your decision:0|1|2");
        strcpy(buffer2, "Enter your decision:0|1|2");

        printf("Server: %s\n", buffer);


        send(client_sock1, buffer, 1024, 0);
        send(client_sock2, buffer2, 1024, 0);

        char numA[1];
        recv(client_sock1, numA, 1, 0);
        printf("received1\n");
        char numB[1];
        recv(client_sock2, numB, 1, 0);
        printf("received2\n");
        char result[1]; // wrt A // 0 rock 1 paper 2 scissor
        if (numA[0] == numB[0])
        {
            result[0] = 'D';

            printf("It is a draw\n");
            send(client_sock1, result, 1, 0);
            send(client_sock2, result, 1, 0);
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
            send(client_sock1, result, 1, 0);
            send(client_sock2, antiresult, 1, 0);
        }

        bzero(buffer, 1024);
        strcpy(buffer, "Do you want to play one more game, reply with Y/N ?");
        printf("Server: %s\n", buffer);
        send(client_sock1, buffer, 1024, 0);
        send(client_sock2, buffer, 1024, 0);

        char moregame1, moregame2;
        recv(client_sock1, &moregame1, 1, 0);
        recv(client_sock2, &moregame2, 1, 0);
        printf("%c\n", moregame1);
        printf("%c\n", moregame2);

        send(client_sock1, &moregame2, 1, 0);
        send(client_sock2, &moregame1, 1, 0);

        if (moregame1 == 'N' || moregame2 == 'N')
        {
            deci = -1;
        }
        // char fdec[1];
        int stop = 1;
        char stopp = '1';
        if (deci == -1)
        {
            stopp = '0';
            send(client_sock1, &stopp, 1, 0);
            send(client_sock2, &stopp, 1, 0);

            printf("[+]Client A disconnected.\n");
            printf("[+]Client B disconnected.\n");
            break;
        }
    }

    close(client_sock1);
    close(client_sock2);
    close(server_sock1);
    close(server_sock2);

    return 0;
}
