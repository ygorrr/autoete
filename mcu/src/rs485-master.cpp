#include <Arduino.h>
#include <SoftwareSerial.h>

#define RS485_RX 2
#define RS485_TX 3

// Pinos de enable do conversor TTL-RS-485
#define MAX485_RE 4
#define MAX485_DE 5

// Interface serial para barramento RS-485
SoftwareSerial RS485(RS485_RX, RS485_TX);


void setup() {
	RS485.begin(9600);

	pinMode(MAX485_RE, OUTPUT);
	pinMode(MAX485_DE, OUTPUT);
}

void loop() {
	delay(1000);
	digitalWrite(MAX485_RE, HIGH);
	digitalWrite(MAX485_DE, HIGH);
	RS485.write("hello world\n");
}