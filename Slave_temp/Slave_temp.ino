#include <Wire.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// ================= CONFIGURAÇÕES =================
#define SLAVE_ADDRESS 0x08    // Endereço I2C do escravo
#define LED_PIN 13           // LED built-in
#define ONE_WIRE_BUS 2       // Pino do sensor DS18B20

// ================= VARIÁVEIS GLOBAIS =================
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
float temperatura = 0.0;
char tempString[10];  // Buffer para string da temperatura

// ================= DECLARAÇÃO DE FUNÇÕES =================
void receiveData(int byteCount);
void sendData();
void lerTemperatura();

// ================= SETUP =================
void setup() {
  // 1. Configuração do LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // 2. Inicialização do sensor de temperatura
  sensors.begin();
  Serial.begin(9600);
  Serial.println("Escravo I2C + DS18B20 Iniciado");
  
  // 3. Verifica se o sensor foi encontrado
  int deviceCount = sensors.getDeviceCount();
  Serial.print("Sensores DS18B20 encontrados: ");
  Serial.println(deviceCount);
  
  // 4. Configuração I2C como escravo
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveData);  // Callback quando recebe dados
  Wire.onRequest(sendData);     // Callback quando mestre solicita dados
  
  Serial.println("Pronto para comunicação I2C");
}

// ================= LOOP PRINCIPAL =================
void loop() {
  // Atualiza a temperatura a cada 2 segundos
  lerTemperatura();
  delay(2000);
}

// ================= FUNÇÃO: LER TEMPERATURA =================
void lerTemperatura() {
  // Solicita leitura do sensor
  sensors.requestTemperatures();
  
  // Lê temperatura em Celsius
  temperatura = sensors.getTempCByIndex(0);
  
  // Verifica se a leitura é válida
  if (temperatura != DEVICE_DISCONNECTED_C) {
    // Converte float para string formatada
    dtostrf(temperatura, 6, 2, tempString);
    
    Serial.print("Temperatura lida: ");
    Serial.print(temperatura);
    Serial.println(" °C");
  } else {
    Serial.println("Erro na leitura do sensor!");
    temperatura = -999.9;  // Valor de erro
  }
}

// ================= FUNÇÃO: RECEBER DADOS I2C =================
void receiveData(int byteCount) {
  Serial.print("Comando recebido do mestre: ");
  
  // Lê todos os bytes recebidos
  while (Wire.available()) {
    char comando = Wire.read();
    Serial.print(comando);
    
    // Pisca LED quando recebe dados
    digitalWrite(LED_PIN, HIGH);
  }
  Serial.println();
  
  // Apaga LED após breve delay
  delay(100);
  digitalWrite(LED_PIN, LOW);
}

// ================= FUNÇÃO: ENVIAR DADOS I2C =================
void sendData() {
  // Envia a temperatura atual para o mestre
  Wire.write(tempString ,6);  // Envia 8 bytes (formato: " 25.50")
  
  Serial.print("Temperatura enviada para mestre: ");
  Serial.println(tempString);
}
