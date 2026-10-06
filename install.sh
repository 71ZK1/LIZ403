python3 -m venv liz403-env
echo "done"
source liz403-env/bin/activate
echo "done"
pip install -r requirements.txt
echo "done..."
echo "verifying.........."
sleep 3
python LIZ403.py --help
echo "done"
