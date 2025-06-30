Vietnamese Accent Inserter

A local Vietnamese diacritic insertion service using a FastAPI backend and a macOS Automator Quick Action for one-key accent correction.

⸻

🚀 Features
	•	FastAPI Server: Load the peterhung/vietnamese-accent-marker-xlm-roberta model once and serve accent insertion requests.
	•	Shell Client: add_accents_withserver.sh reads stdin, POSTs to the local server, and returns accented text.
	•	macOS Automator Quick Action: Select any paragraph in any app and press your chosen hotkey to replace it with properly accented Vietnamese.

⸻

📦 Repository Structure

├── server.py                  # FastAPI application
├── server.sh                  # Script to launch the FastAPI server
├── add_accents_withserver.sh  # Shell client that calls the local API
└── README.md                  # This file


⸻

🛠️ Prerequisites
	•	macOS (Ventura or later recommended)
	•	Python 3.8+ with pip
	•	Homebrew (optional, but recommended for Python installs)
	•	Automator (built-in on macOS)
	•	Uvicorn (ASGI server)

You can install Homebrew from https://brew.sh.

⸻

1. Setup FastAPI Server
	1.	Clone this repository

git clone https://github.com/your-username/vn-accent-inserter.git
cd vn-accent-inserter


	2.	Create and activate a virtual environment (optional but recommended)

python3 -m venv .venv
source .venv/bin/activate


	3.	Install Python dependencies

pip install --upgrade pip
pip install fastapi uvicorn transformers torch numpy


	4.	Download tag definitions (if not done automatically)

mkdir -p ~/.cache/vn_accent
curl -sL \
  https://huggingface.co/peterhung/vietnamese-accent-marker-xlm-roberta/resolve/main/selected_tags_names.txt \
  -o ~/.cache/vn_accent/selected_tags_names.txt


	5.	Make server.sh executable

chmod +x server.sh


	6.	Start the server

./server.sh

The API will listen on http://127.0.0.1:8000/accent.

⸻

2. Shell Client: add_accents_withserver.sh
	1.	Make it executable

chmod +x add_accents_withserver.sh


	2.	Test it in terminal

echo "Nhin nhung mua thu di" | ./add_accents_withserver.sh

You should see: Nhìn những mùa thu dị (or similar).

⸻

3. macOS Automator Quick Action
	1.	Open Automator (⌘+Space → type “Automator”).
	2.	New Document → Quick Action.
	3.	Configure the workflow header:
	•	Workflow receives current: text
	•	in: any application
	•	✅ Check Output replaces selected text
	4.	Add a Run Shell Script action (from the Utilities library).
	5.	Set:
	•	Shell: /bin/zsh
	•	Pass input: to stdin
	6.	Paste the following into the script box:

#!/bin/zsh
# Load your shell environment
[ -f ~/.zprofile ] && source ~/.zprofile
[ -f ~/.zshrc   ] && source ~/.zshrc

# Ensure PATH contains Homebrew and system bins
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Optionally activate the venv
PROJECT="$HOME/Projects/vn_accent_inserter"
[ -f "$PROJECT/.venv/bin/activate" ] && source "$PROJECT/.venv/bin/activate"

# Read selected text and call the shell client
paragraph="$(cat)"
[ -n "$paragraph" ] && printf '%s' "$paragraph" | "$PROJECT/add_accents_withserver.sh"


	7.	Save the Quick Action with a name like Add Vietnamese Accents.

⸻

4. Assign a Keyboard Shortcut
	1.	Open System Settings → Keyboard → Keyboard Shortcuts.
	2.	Select Services (or Quick Actions).
	3.	Find Add Vietnamese Accents under the Text section.
	4.	Click and assign a hotkey (e.g. ⌘⌥⌃V).

⸻

🎉 Usage
	1.	In any app that supports text selection, highlight a paragraph of un-accented Vietnamese.
	2.	Press your configured hotkey.
	3.	The text is replaced in-place with correct Vietnamese accents.

⸻

🤝 Contributing

Feel free to open issues or PRs to improve performance, support batch processing, or add new features.

⸻

📜 License

MIT License
