sudo apt install python3-venv -y
python3 -m venv .venv
echo "done"
source .venv/bin/activate
echo "done"
pip install -r requirements.txt
echo "done..."
echo "verifying.........."
sleep 3
python LIZ403.py --help
echo "done"

