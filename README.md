Repositório do projeto de automação da Estação de Tratamento de Efluentes desenvolvida pelo GESAR.

# Como trabalhar nesse repositório
Esse repositório inclui projetos do PlatformIO para os microcontroladores. Para trabalhar utilizando a extensão do PlatformIO no VSCode, a pasta `mcu` precisa ser adicionada ao Workspace, pois o PlatformIO espera encontrar o arquivo `platformio.ini` na raiz do diretório. 

1. No terminal, navegue até o diretório do seu computador onde você deseja clonar o repositório remoto. Por exemplo, `D:\projetos\`.
2. Clone o repositório remoto do GitHub.
```bash
git clone https://github.com/ygorrr/autoete.git
```
3. Ainda no terminal, abra o diretório do repositório no VSCode.
```bash
code autoete/
```
4. Adicione a pasta `mcu/` individualmente ao Workspace do VSCode. No VSCode, vá em `File → Add Folder to Workspace` e selecione a pasta `autoete/mcu/`.

Os códigos-fonte de microcontroladores ficam na pasta `mcu/src/`. Configurações de compilação ficam no arquivo `mcu/platformio.ini`, definidas em ambientes `[env]`. Cada código-fonte deve ter um ambiente próprio definido em `platformio.ini`. Antes de compilar um código-fonte específico, mude para o ambiente que aponta para o arquivo `.cpp` em questão. Para isso, você pode usar a Paleta de Comandos do VSCode:

- Pressione `Ctrl + Shift + P` e escolha `PlatformIO: Pick Project Environment` na caixa de diálogo.

ou utilizar o botão de ambiente adicionado pela extensão do PlatformIO:

- Na barra inferior do VSCode, clique em `Switch PlatformIO Project Environment`.

<img src="https://raw.githubusercontent.com/ygorrr/ygorrr.github.io/main/doc-images/pio-env-bar.png" width="500" title="PlatformIO environment bar">

# MQTT

Esse projeto utiliza o broker MQTT Eclipse Mosquitto. Documentação dos utilitários de CLI podem ser encontrados em [https://mosquitto.org/documentation/](https://mosquitto.org/documentation/)

```bash
-p		# Especifica porta para conexão com o broker
--port
```

```bash
-h		# Especifica o endereço IP do host do broker
--host
```

```bash
-t		# Especifica o tópico atrelado à mensagem. Recebe strings em aspas duplas.
```

```bash
-m		# Especifica o conteúdo da mensagem. Recebe strings em aspas duplas.
```