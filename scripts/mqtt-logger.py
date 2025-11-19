import paho.mqtt.client as mqtt

# Define callback functions
def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")
    client.subscribe("test")

def on_publish(client, userdata, mid):
    print(f"Message {mid} published.")

def on_message(client, userdata, msg):
    print(f"Received message on topic {msg.topic}: {msg.timestamp} {msg.payload.decode()}")
    
# Create an MQTT client instance
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION1) # or VERSION2 for newer APIs

# Assign callback functions
client.on_connect = on_connect
client.on_publish = on_publish
client.on_message = on_message

# Connect to the broker (e.g., a public test broker)
broker_address = "10.0.0.170" #"broker.emqx.io"
broker_port = 1883
client.connect(broker_address, broker_port, 60)

# Start the loop in a separate thread to handle network traffic
# client.loop_start()
client.loop_forever()

# Publish a message
# topic = "test"
# message = "Hello, MQTT from Python!"
# client.publish(topic, message)

# Keep the script running for a short period to allow publishing
# import time
# time.sleep(2)

# Disconnect
# client.loop_stop()
# client.disconnect()