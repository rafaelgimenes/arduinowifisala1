/*
* Codigo de exemplo by falecom@rafaelgimenes.net
*Projeto que controla 2 lampadas usando arduino wifi, 
*usa RTC1302 pra verificar a hora e em determinado periodo programado ele alterna o ativamento das lampadas, 
*para simular que tem gente na casa"
*/
#include <WiServer.h>
#include <stdio.h>   //DS1302
#include <string.h>  //DS1302
#include <DS1302.h>  //DS1302
#define pinDigDsCE 5 //DS1302
#define pinDigDsIO 6  //DS1302
#define pinDigDsSCLK 7 //DS1302

#define WIRELESS_MODE_INFRA	1
#define WIRELESS_MODE_ADHOC	2
//Parametros do ds1302
char impdta[50]; //DS1302 para impressao da data
int  dta[7] = {2013,1,26,10,30,2,7};     //DS1302 0=ano,1=mes,2=dia,3=hora,4=minuto,5=segundo,6=dia da semana;sk
DS1302 rtc(pinDigDsCE,pinDigDsIO,pinDigDsSCLK); // objeto DS1302
//Parametros do Wireless ----------------------------------------
unsigned char local_ip[] = {192,168,2,23};	// IP address of WiShield
unsigned char gateway_ip[] = {192,168,2,1};	// router or gateway IP address
unsigned char subnet_mask[] = {255,255,255,0};	// subnet mask for the local network
const prog_char ssid[] PROGMEM = {"zapata"};		// max 32 bytes
unsigned char security_type = 0;	// 0 - open; 1 - WEP; 2 - WPA; 3 - WPA2

// WPA/WPA2 passphrase
const prog_char security_passphrase[] PROGMEM = {"12345678"};	// max 64 characters

// WEP 128-bit keys
// sample HEX keys
prog_uchar wep_keys[] PROGMEM = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d,	// Key 0
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// Key 1
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// Key 2
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	// Key 3
				};

// setup the wireless mode
// infrastructure - connect to AP
// adhoc - connect to another WiFi device
unsigned char wireless_mode = WIRELESS_MODE_INFRA;
unsigned char ssid_len;
unsigned char security_passphrase_len;
//---------------------------------------------------------------------------
int pnAState = 0; 
int pnBState = 0; 
boolean mdA=true;
int pnA = 8; 
int pnB = 9; 
Time t;


//recebe a url processa, e retorna uma pagina;
boolean enviaPagina(char* URL) { 
  
    //respondendo o status
    if(strcmp(URL, "/pnAState") == 0){
    	printPinoStatusOnly(pnAState); 
	return true;
    }else if(strcmp(URL, "/pnBState") == 0){
    	printPinoStatusOnly(pnBState); 
	return true;
    }else if(strcmp(URL, "/mdAState") == 0){
    	printPinoStatusOnly(mdA); 
	return true;
    }
    //se achou a url, inverte o estado do pino e seta em seu novo estado
    if (strcmp(URL, "/pnA") == 0){ 
	pnAState = !pnAState; 
	digitalWrite(pnA,pnAState);
    //	printPinoStatus("pnA", pnAState); 
    }else if (strcmp(URL, "/pnB") == 0){
	pnBState = !pnBState;
	digitalWrite(pnB,pnBState);
    //	printPinoStatus("pnB", pnBState); 
    }else if (strcmp(URL, "/mdA") == 0){ 
	mdA = !mdA; 
    }
    // URL was recognized 
    	WiServer.print("<html><body bgcolor=9FB6CD><font face=tahoma>"); 
    	WiServer.print("<b>Casa Control Arduino Wifi - </b><hr>");
    	printPinoStatus("pnA", pnAState); 
    	printPinoStatus("pnB", pnBState); 
        printPinoStatus("mdA", mdA); 
    	WiServer.print(impdta);
    	WiServer.print("<hr>by falecom@rafaelgimenes.net</font></body></html>"); 

    return true; 
    // URL not found 
    //return false; 
}
//traduz o pino e faz o link pra ligar ou desligar.
void printPinoStatus(String pino, int estado) { 
        WiServer.print("Pino ");
	WiServer.print(""+pino);
	WiServer.print(" esta ");
	if(estado ==0) { 
            WiServer.print("off <a href=/"); 
            WiServer.print(pino); 
            WiServer.print(">Ligar</a><br><br>"); 
        } else { 
            WiServer.print("on <a href=/"); 
            WiServer.print(pino); 
            WiServer.print(">Desligar</a><br><br>"); 
            mdA=false;
        } 
}
void printPinoStatusOnly(int estado) { 
	if(estado ==0) { 
            WiServer.print("%off%"); 
        } else { 
            WiServer.print("%on%");
            mdA=false; 
        } 
}

void impHora()
{
  /* Get the current time and date from thchip */
  t = rtc.time();
  /* Format the time and date and insert into the temporary buffer */
  snprintf(impdta, sizeof(impdta), "%04d-%02d-%02d %02d:%02d:%02d",
           t.yr, t.mon, t.date,
           t.hr, t.min, t.sec);
}


void setup() { 
  // Initialize WiServer and have it use the sendMyPage function to serve pages 
  WiServer.init(enviaPagina);  
  pinMode(pnA, OUTPUT); 
  pinMode(pnB, OUTPUT); 
}

void loop(){
  // Run WiServer 
  WiServer.server_task(); 
  delay(10); 
  impHora();
  if(mdA){
    //se hora for maior que 19
    if (t.hr==19&& t.min>50){  
        digitalWrite(pnA,HIGH);
        digitalWrite(pnB,LOW);
    }
    
    if (t.hr==20&& t.min>40){  
        digitalWrite(pnA,LOW);
        digitalWrite(pnB,HIGH);
    }
    
     if (t.hr==21 && t.min>45){  
        digitalWrite(pnA,LOW);
        digitalWrite(pnB,HIGH);
     }

    if (t.hr >= 6 && t.hr < 19){  
        digitalWrite(pnA,LOW);
        digitalWrite(pnB,LOW);
     }
    
    
  }
}

 

