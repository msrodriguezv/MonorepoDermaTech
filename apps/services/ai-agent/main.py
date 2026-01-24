from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({"status": "AI Agent Running", "tech": "Python + Flask"})

@app.route('/analyze', methods=['POST'])
def analyze():
    return jsonify({
        "diagnosis": "ANALISIS PENDIENTE", 
        "advice": "Este es un resultado simulado desde Python"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)