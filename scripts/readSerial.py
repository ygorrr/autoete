import serial
import serial.tools.list_ports

print("Portas seriais disponíveis:")
for port in serial.tools.list_ports.comports():
    print(port.device)
    
# Configure a porta serial (altere conforme necessário)
porta = 'COM6'  # Exemplo: 'COM3' no Windows ou '/dev/ttyUSB0' no Linux
baudrate = 9600

try:
    with serial.Serial(porta, baudrate, timeout=1) as ser:
        print(f"Lendo dados da porta {porta}...")
        while True:
            if ser.in_waiting > 0:
                linha = ser.readline().decode('utf-8', errors='ignore').strip()
                print(f"Recebido: {linha}")
except serial.SerialException as e:
    print(f"Erro ao acessar a porta serial: {e}")
except KeyboardInterrupt:
    print("Leitura interrompida pelo usuário.")