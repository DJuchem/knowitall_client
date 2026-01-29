import customtkinter as ctk
import re
import json
import requests

# CONFIG
SERVER_URL = "http://localhost:5074/api/admin" # You'll need to create this endpoint
THEME_COLOR = "#E91E63"

class AdminApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("KnowItAll Admin Console")
        self.geometry("800x600")
        
        self.tabview = ctk.CTkTabview(self)
        self.tabview.pack(fill="both", expand=True, padx=20, pady=20)
        
        self.setup_music_tab()
        self.setup_config_tab()

    def setup_music_tab(self):
        tab = self.tabview.add("Music Import")
        
        ctk.CTkLabel(tab, text="Paste C# GameCard List Here:").pack(pady=5)
        self.text_input = ctk.CTkTextbox(tab, height=300)
        self.text_input.pack(fill="x", padx=10)
        
        self.btn_parse = ctk.CTkButton(tab, text="Parse & Upload", fg_color=THEME_COLOR, command=self.parse_music)
        self.btn_parse.pack(pady=10)
        
        self.status_label = ctk.CTkLabel(tab, text="Ready", text_color="gray")
        self.status_label.pack()

    def setup_config_tab(self):
        tab = self.tabview.add("Deployment Config")
        
        self.entries = {}
        fields = ["App Title", "Logo Path", "Background Music", "Enabled Modes (comma sep)"]
        defaults = ["KNOW IT ALL", "assets/logo.png", "assets/music/default.mp3", "general,music,math"]
        
        for i, field in enumerate(fields):
            ctk.CTkLabel(tab, text=field).pack(anchor="w", padx=20)
            entry = ctk.CTkEntry(tab)
            entry.insert(0, defaults[i])
            entry.pack(fill="x", padx=20, pady=(0, 10))
            self.entries[field] = entry
            
        ctk.CTkButton(tab, text="Save Configuration", fg_color=THEME_COLOR, command=self.save_config).pack(pady=20)

    def parse_music(self):
        raw_text = self.text_input.get("1.0", "end")
        # Regex to match your specific C# syntax
        # Artist="Michael Jackson", Title="Billie Jean", Year=1982, MediaPayload="OZGtRvYF-A4"
        pattern = r'Artist="(.*?)",\s*Title="(.*?)",\s*Year=(\d+),\s*MediaPayload="(.*?)"'
        
        matches = re.findall(pattern, raw_text)
        
        results = []
        for match in matches:
            results.append({
                "artist": match[0],
                "title": match[1],
                "year": int(match[2]),
                "youtubeId": match[3]
            })
            
        if results:
            # Here you would POST to your server
            # requests.post(f"{SERVER_URL}/import-music", json=results)
            
            # For now, let's just save to a JSON file you can drop into the server folder
            with open("music_db.json", "w") as f:
                json.dump(results, f, indent=4)
                
            self.status_label.configure(text=f"Success! Exported {len(results)} tracks to music_db.json", text_color="green")
        else:
            self.status_label.configure(text="No matches found. Check syntax.", text_color="red")

    def save_config(self):
        config = {
            "appTitle": self.entries["App Title"].get(),
            "logoPath": self.entries["Logo Path"].get(),
            "bgMusic": self.entries["Background Music"].get(),
            "modes": self.entries["Enabled Modes (comma sep)"].get().split(",")
        }
        with open("deployment_config.json", "w") as f:
            json.dump(config, f, indent=4)
        print("Config saved!")

if __name__ == "__main__":
    app = AdminApp()
    app.mainloop()