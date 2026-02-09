import customtkinter as ctk
import tkinter as tk
from tkinter import filedialog, messagebox
import json
import mysql.connector
import hashlib
import threading
import uuid  # ✅ Required for the random fingerprint logic

# Theme Settings
ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")

class DBTool(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("KnowItAll - DB Force Uploader")
        self.geometry("600x700")
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(4, weight=1)

        self.json_data = None

        # --- 1. Database Configuration ---
        self.frame_config = ctk.CTkFrame(self)
        self.frame_config.grid(row=0, column=0, padx=20, pady=10, sticky="ew")
        self.frame_config.grid_columnconfigure(1, weight=1)

        ctk.CTkLabel(self.frame_config, text="Database Connection", font=("Arial", 14, "bold")).grid(row=0, column=0, columnspan=4, pady=10)

        # Host and Port
        ctk.CTkLabel(self.frame_config, text="Host:").grid(row=1, column=0, padx=10, pady=5, sticky="w")
        self.entry_host = ctk.CTkEntry(self.frame_config)
        self.entry_host.insert(0, "192.168.1.111")
        self.entry_host.grid(row=1, column=1, padx=10, pady=5, sticky="ew")

        ctk.CTkLabel(self.frame_config, text="Port:").grid(row=1, column=2, padx=5, pady=5, sticky="w")
        self.entry_port = ctk.CTkEntry(self.frame_config, width=60)
        self.entry_port.insert(0, "3306")
        self.entry_port.grid(row=1, column=3, padx=10, pady=5, sticky="ew")

        # User, Pass, DB
        self.entry_user = self.create_input(self.frame_config, "User:", "root", 2)
        self.entry_pass = self.create_input(self.frame_config, "Password:", "", 3, show="*")
        self.entry_db = self.create_input(self.frame_config, "Database:", "knowitall", 4)

        # Test Connection Button
        self.btn_test = ctk.CTkButton(self.frame_config, text="Test Connection", command=self.test_connection, fg_color="#E0A800", text_color="black")
        self.btn_test.grid(row=5, column=0, columnspan=4, pady=10, padx=10, sticky="ew")

        # --- 2. File Selection ---
        self.frame_file = ctk.CTkFrame(self)
        self.frame_file.grid(row=1, column=0, padx=20, pady=10, sticky="ew")
        
        self.btn_load = ctk.CTkButton(self.frame_file, text="Select JSON File", command=self.load_json)
        self.btn_load.pack(pady=10, padx=10, fill="x")
        
        self.lbl_file = ctk.CTkLabel(self.frame_file, text="No file selected", text_color="gray")
        self.lbl_file.pack(pady=5)

        # --- 3. Action ---
        self.btn_upload = ctk.CTkButton(self, text="FORCE UPLOAD (Allow Duplicates)", command=self.start_upload, state="disabled", fg_color="#C0392B", hover_color="#E74C3C", height=50)
        self.btn_upload.grid(row=2, column=0, padx=20, pady=10, sticky="ew")

        # --- 4. Log Window ---
        self.textbox = ctk.CTkTextbox(self, width=500)
        self.textbox.grid(row=3, column=0, padx=20, pady=10, sticky="nsew")

    def create_input(self, parent, label, default, row, show=None):
        ctk.CTkLabel(parent, text=label).grid(row=row, column=0, padx=10, pady=5, sticky="w")
        entry = ctk.CTkEntry(parent, show=show)
        entry.insert(0, default)
        entry.grid(row=row, column=1, columnspan=3, padx=10, pady=5, sticky="ew")
        return entry

    def log(self, message):
        self.textbox.insert("end", message + "\n")
        self.textbox.see("end")

    def load_json(self):
        file_path = filedialog.askopenfilename(filetypes=[("JSON Files", "*.json")])
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    self.json_data = json.load(f)
                self.lbl_file.configure(text=f"Loaded: {len(self.json_data)} questions", text_color="white")
                self.btn_upload.configure(state="normal")
                self.log(f"Successfully loaded {len(self.json_data)} questions.")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to parse JSON: {e}")

    def test_connection(self):
        host = self.entry_host.get()
        try:
            port = int(self.entry_port.get())
        except ValueError:
            messagebox.showerror("Error", "Port must be an integer.")
            return

        user = self.entry_user.get()
        password = self.entry_pass.get()
        database = self.entry_db.get()

        try:
            self.log(f"Testing connection to {host}:{port}...")
            conn = mysql.connector.connect(
                host=host,
                port=port,
                user=user,
                password=password,
                database=database,
                connection_timeout=5
            )
            if conn.is_connected():
                self.log("✅ Connection Successful!")
                messagebox.showinfo("Success", "Connection Valid!")
                conn.close()
        except mysql.connector.Error as err:
            self.log(f"❌ Connection Failed: {err}")
            messagebox.showerror("Connection Failed", str(err))

    def start_upload(self):
        threading.Thread(target=self.upload_process).start()

    def upload_process(self):
        self.btn_upload.configure(state="disabled")
        
        host = self.entry_host.get()
        try:
            port = int(self.entry_port.get())
        except:
            self.log("Error: Invalid Port")
            self.btn_upload.configure(state="normal")
            return

        user = self.entry_user.get()
        password = self.entry_pass.get()
        database = self.entry_db.get()

        try:
            self.log(f"Connecting to DB...")
            conn = mysql.connector.connect(
                host=host,
                port=port,
                user=user,
                password=password,
                database=database
            )
            cursor = conn.cursor()
            self.log("Connected! Starting Force Upload...")

            success_count = 0
            error_count = 0

            for q in self.json_data:
                # 1. Map Fields
                q_text = q.get("Question", "")
                q_type = q.get("Type", "text")
                correct = q.get("CorrectAnswer", "")
                incorrect = json.dumps(q.get("IncorrectAnswers", []))
                difficulty = q.get("Difficulty", "Medium")
                image_url = q.get("MediaPayload", None)
                
                # -----------------------------------------------------------
                # ✅ THE FIX: RANDOMIZE FINGERPRINT TO BYPASS DUPLICATE CHECK
                # -----------------------------------------------------------
                unique_salt = str(uuid.uuid4())
                # We hash the text + a random UUID so the hash is ALWAYS unique
                fingerprint = hashlib.sha256((q_text + unique_salt).encode('utf-8')).hexdigest()

                # 3. SQL Insert (Standard INSERT, not IGNORE)
                sql = """
                    INSERT INTO questions 
                    (type, question, correct_answer, incorrect_answers, difficulty, fingerprint, image)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """
                val = (q_type, q_text, correct, incorrect, difficulty, fingerprint, image_url)

                try:
                    cursor.execute(sql, val)
                    success_count += 1
                except mysql.connector.Error as err:
                    self.log(f"SQL Error: {err}")
                    error_count += 1

            conn.commit()
            cursor.close()
            conn.close()

            self.log("-" * 30)
            self.log(f"UPLOAD COMPLETE")
            self.log(f"✅ Added: {success_count}")
            self.log(f"❌ Errors: {error_count}")
            self.log("-" * 30)
            messagebox.showinfo("Success", f"Force Upload Complete!\nAdded: {success_count}\nErrors: {error_count}")

        except mysql.connector.Error as err:
            self.log(f"Database Error: {err}")
            messagebox.showerror("Database Error", str(err))
        except Exception as e:
            self.log(f"General Error: {e}")
        
        self.btn_upload.configure(state="normal")

if __name__ == "__main__":
    app = DBTool()
    app.mainloop()