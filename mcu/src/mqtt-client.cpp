#include <Arduino.h>
#include <SPI.h>
#include <Ethernet.h>
#include <PubSubClient.h>

// --- Configurações de rede ---
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress ip(10, 0, 0, 171);        // IP do Arduino
IPAddress server(10, 0, 0, 170);    // IP do broker Mosquitto

// --- Clientes ---
EthernetClient ethClient;
PubSubClient mqtt(ethClient);

void callback(char* topic, byte* payload, unsigned int length);
void reconnect();

void setup() {
	Serial.begin(9600);
	Ethernet.begin(mac, ip);
	delay(1500);
	mqtt.setServer(server, 1883);
	mqtt.setCallback(callback);
}

void loop() {
	if (!mqtt.connected()) {
		reconnect();
	}
	mqtt.loop();

	static uint32_t lastMsg = 0;
	if (millis() - lastMsg >= 5000)	{
		lastMsg = millis();
		mqtt.publish("test", "Olá!");
	}	
}

void callback(char* topic, byte* payload, unsigned int length) {
	Serial.print("Mensagem em [");
	Serial.print(topic);
	Serial.print("]: ");
	for (uint16_t i = 0; i < length; i++) {
		Serial.print((char)payload[i]);
	}
	Serial.println();	
}

void reconnect() {
	while (!mqtt.connected()){
		Serial.print("Tentando conectar ao broker...");
		if (mqtt.connect("ArduinoClient")) {
			Serial.println("Conectado");
			mqtt.subscribe("test");
		} else {
			Serial.print("falhou, rc=");
			Serial.print(mqtt.state());
			Serial.println(" - tentando novamente em 5s");
			delay(5000);
		}
	}
}