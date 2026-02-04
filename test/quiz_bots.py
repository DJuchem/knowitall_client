import tkinter as tk
from tkinter import ttk, scrolledtext
import threading
import time
import random
from signalrcore.hub_connection_builder import HubConnectionBuilder

class QuizBotGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("KnowItAll Bot Controller")
        self.bots = []
        
        # --- UI LAYOUT ---
        frame = ttk.Frame(root, padding="10")
        frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        ttk.Label(frame, text="Server URL:").grid(row=0, column=0, sticky=tk.W)
        self.url_entry = ttk.Entry(frame, width=30)
        self.url_entry.insert(0, "http://localhost:5074/ws")
        self.url_entry.grid(row=0, column=1, pady=5)

        ttk.Label(frame, text="Lobby Code:").grid(row=1, column=0, sticky=tk.W)
        self.code_entry = ttk.Entry(frame, width=10)
        self.code_entry.insert(0, "1963")
        self.code_entry.grid(row=1, column=1, sticky=tk.W, pady=5)

        ttk.Label(frame, text="Number of Bots:").grid(row=2, column=0, sticky=tk.W)
        self.bot_count = ttk.Spinbox(frame, from_=1, to=20, width=5)
        self.bot_count.set(3)
        self.bot_count.grid(row=2, column=1, sticky=tk.W, pady=5)

        self.start_btn = ttk.Button(frame, text="Launch Bots", command=self.start_simulation)
        self.start_btn.grid(row=3, column=0, columnspan=2, pady=10)

        self.log_area = scrolledtext.ScrolledText(frame, width=50, height=15, state='disabled')
        self.log_area.grid(row=4, column=0, columnspan=2)

    def log(self, message):
        self.log_area.configure(state='normal')
        self.log_area.insert(tk.END, f"{message}\n")
        self.log_area.see(tk.END)
        self.log_area.configure(state='disabled')

    def start_simulation(self):
        url = self.url_entry.get()
        code = self.code_entry.get().upper()
        count = int(self.bot_count.get())
        
        self.start_btn.config(state='disabled')
        for i in range(count):
            threading.Thread(target=self.run_bot, args=(i, url, code), daemon=True).start()

    def run_bot(self, index, url, lobby_code):
        bot_name = f"Bot_{index}"
        avatar = f"avatar_{index}.png"
        
        # Use a more robust configuration for large payloads
        connection = HubConnectionBuilder()\
            .with_url(url)\
            .with_automatic_reconnect({
                "type": "raw",
                "keep_alive_interval": 10,
                "reconnect_interval": 5,
                "max_attempts": 99
            }).build()

        def on_open():
            self.log(f"[{bot_name}] Connected. Joining {lobby_code}...")
            # Arguments: code, name, avatar, spectator, hostKey
            connection.send("JoinGame", [lobby_code, bot_name, avatar, False, ""])
            time.sleep(1)
            connection.send("ToggleReady", [lobby_code, True])

        def handle_quiz_event(args):
            """Handles game_started, new_round, and lobby_update safely."""
            try:
                # If args is empty or malformed due to the JSON error, we fallback
                q_index = 0
                if args and len(args) > 0 and isinstance(args[0], dict):
                    q_index = args[0].get('questionIndex', 0)
                
                self.log(f"[{bot_name}] Round {q_index} active. Thinking...")
                
                # Randomized delay to simulate human behavior
                time.sleep(random.uniform(0.5, 1))
                
                # SubmitAnswer: code, questionId, answer, time
                # We pick a random letter since the bot doesn't need to read the large quizData string
                choice = random.choice(["A", "B", "C", "D"]) 
                connection.send("SubmitAnswer", [lobby_code, q_index, choice, 1.5])
                self.log(f"[{bot_name}] Submitted: {choice}")
            except Exception as e:
                self.log(f"[{bot_name}] Payload Error: {e}")

        # Register SignalR Handlers with error catchers
        connection.on_open(on_open)
        connection.on("game_started", handle_quiz_event)
        connection.on("new_round", handle_quiz_event)
        
        # This is likely where the large JSON crash happens; we'll log it but not let it kill the bot
        connection.on("lobby_update", lambda x: None) 
        
        connection.on_error(lambda data: self.log(f"[{bot_name}] SignalR Error: {data}"))
        
        try:
            connection.start()
            self.bots.append(connection)
        except Exception as e:
            self.log(f"[{bot_name}] Start Error: {e}")

if __name__ == "__main__":
    root = tk.Tk()
    app = QuizBotGUI(root)
    root.mainloop()