#include <Wire.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// ================= CONFIGURAÇÕES =================
#define SLAVE_ADDRESS 0x08   // Endereço I2C do escravo
#define LED_PIN 13           // LED built-in
#define ONE_WIRE_BUS 2       // Pino do barramento OneWire
#define MAX_SENSORES 8       // Número máximo de sensores suportados

// ================= VARIÁVEIS GLOBAIS =================
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// ============ Estrutura para armazenar dados de cada sensor
struct SensorData {
  float temperatura;
  char tempString[10];  // Buffer para string da temperatura
  bool ativo;
  DeviceAddress endereco;
};

SensorData sensores[MAX_SENSORES];
int numSensores = 0;
int sensorAtual = 0;  // Sensor que será enviado via I2C

// ================= DECLARAÇÃO DE FUNÇÕES =================
void receiveData(int byteCount);
void sendData();
void lerTemperaturas();
void detectarSensores();
void imprimirEnderecoSensor(DeviceAddress deviceAddress);

// ================= SETUP =================
void setup() {
  // 1. Configuração do LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // 2. Inicialização do sensor de temperatura
  sensors.begin();
  Serial.begin(9600);
  Serial.println("Escravo I2C + Múltiplos DS18B20 Iniciado");
  
  // 3. Detectar e configurar sensores
  detectarSensores();
  
  // 4. Configuração I2C como escravo
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveData);  // Callback quando recebe dados
  Wire.onRequest(sendData);     // Callback quando mestre solicita dados
  
  Serial.println("Pronto para comunicação I2C");
}

// ================= LOOP PRINCIPAL =================
void loop() {
  // Atualiza as temperaturas a cada 2 segundos
  lerTemperaturas();
  delay(2000);
}

// ================= FUNÇÃO: DETECTAR SENSORES =================
void detectarSensores() {
  // Detecta quantos sensores estão presentes no barramento
  numSensores = sensors.getDeviceCount();
  
  Serial.print("Sensores DS18B20 encontrados: ");
  Serial.println(numSensores);
  
  if (numSensores == 0) {
    Serial.println("Nenhum sensor DS18B20 encontrado!");
    return;
  }
  
  // Configura cada sensor encontrado
  for (int i = 0; i < numSensores && i < MAX_SENSORES; i++) {
    if (sensors.getAddress(sensores[i].endereco, i)) {
      sensores[i].ativo = true;
      sensores[i].temperatura = -999.9;  // Valor inicial de erro
      strcpy(sensores[i].tempString, "ERR");
      
      Serial.print("Sensor ");
      Serial.print(i);
      Serial.print(": ");
      imprimirEnderecoSensor(sensores[i].endereco);
    }
  }
}

// ================= FUNÇÃO: LER TODAS AS TEMPERATURAS =================
void lerTemperaturas() {
  // Solicita leitura de todos os sensores
  sensors.requestTemperatures();
  
  // Lê temperatura de cada sensor
  for (int i = 0; i < numSensores && i < MAX_SENSORES; i++) {
    if (sensores[i].ativo) {
      sensores[i].temperatura = sensors.getTempC(sensores[i].endereco);
      
      // Verifica se a leitura é válida
      if (sensores[i].temperatura != DEVICE_DISCONNECTED_C) {
        // Converte float para string formatada
        dtostrf(sensores[i].temperatura, 6, 2, sensores[i].tempString);
        
        Serial.print("Sensor ");
        Serial.print(i);
        Serial.print(": ");
        Serial.print(sensores[i].temperatura);
        Serial.println(" °C");
      } else {
        Serial.print("Erro na leitura do sensor ");
        Serial.println(i);
        sensores[i].temperatura = -999.9;  // Valor de erro
        strcpy(sensores[i].tempString, "ERR");
      }
    }
  }
  Serial.println("---");
}

// ================= FUNÇÃO: RECEBER DADOS I2C =================
void receiveData(int byteCount) {
  Serial.print("Comando recebido do mestre: ");
  
  // Lê todos os bytes recebidos
  while (Wire.available()) {
    char comando = Wire.read();
    Serial.print(comando);
    
    // Se o comando for um número (0-7), seleciona o sensor correspondente
    if (comando >= '0' && comando <= '7') {
      sensorAtual = comando - '0';
      Serial.print(" -> Selecionando sensor ");
      Serial.println(sensorAtual);
    }
    
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
  // Verifica se o sensor atual é válido
  if (sensorAtual < numSensores && sensores[sensorAtual].ativo) {
    // Envia a string de temperatura do sensor selecionado
    Wire.write(sensores[sensorAtual].tempString, 6);  // Envia 6 bytes
    
    Serial.print("Temperatura do sensor ");
    Serial.print(sensorAtual);
    Serial.print(" enviada: ");
    Serial.println(sensores[sensorAtual].tempString);
  } else {
    // Envia mensagem de erro se o sensor não for válido
    Wire.write("ERR", 3);
    
    Serial.print("Erro: Sensor ");
    Serial.print(sensorAtual);
    Serial.println(" não disponível");
  }
}

// ================= FUNÇÃO: IMPRIMIR ENDEREÇO DO SENSOR =================
void imprimirEnderecoSensor(DeviceAddress deviceAddress) {
  for (uint8_t i = 0; i < 8; i++) {
    if (deviceAddress[i] < 16) Serial.print("0");
    Serial.print(deviceAddress[i], HEX);
    if (i < 7) Serial.print(":");
  }
  Serial.println();
}