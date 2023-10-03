from flask import Flask, render_template, request
import json

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

print("ahahaha")

@app.route('/test', methods=['POST', 'GET'])
def test():
    if request.method == 'GET':
        msg = "lol"
        print("SENT >>", msg)
        return msg
    print("RECEIVED >>",list(request.form))
    json.dump(request.form, "sourcemap.json")
    return render_template('index.html')

app.run(host='0.0.0.0',port='1111',debug=False)