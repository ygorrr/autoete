#include <Wire.h>

#define SLAVE_ADDRESS 0x08    // Endereço do escravo
#define LED_PIN 13           // LED built-in

void setup() {
  pinMode(LED_PIN, OUTPUT);
  Wire.begin();              // Inicia como mestre
  Serial.begin(9600);
  Serial.println("Mestre I2C - Monitor de Temperatura");
  Serial.println("====================================");
}

void loop() {
  // 1. Envia comando para solicitar temperatura
  Wire.beginTransmission(SLAVE_ADDRESS);
  Wire.write("TEMP?");        // Comando para solicitar temperatura
  Wire.endTransmission();
  
  Serial.println("Solicitando temperatura do escravo...");
  digitalWrite(LED_PIN, HIGH);
  
  // 2. Aguarda breve momento
  delay(500);
  
  // 3. Solicita dados do escravo (8 bytes)
  Wire.requestFrom(SLAVE_ADDRESS, 6);
  
  // 4. Lê a resposta do escravo
  //Serial.print("Temperatura recebida: ");
  String Readstr;
  while (Wire.available()) {
    //Serial.print("Temperatura recebida: ");
    char c = Wire.read();
    Readstr = Readstr+c;
    //Serial.print(c);
    //Serial.println("°C");
  }
  Serial.print("Temperatura recebida: ");
  Serial.print( Readstr);
  Serial.println(" °C");
  
  digitalWrite(LED_PIN, LOW);
  Serial.println("----------------------------");
  
  delay(3000);  // Aguarda 3 segundos para próxima leitura
}