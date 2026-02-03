from flask import Flask, request, jsonify
import random

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "AI Agent Ready"})

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.get_json()
    symptoms = data.get('text', '')

    print(f"🧠 Analizando síntomas: {symptoms}")

    # Lógica Simulada de IA (Aquí conectarías TensorFlow/PyTorch luego)
    # Por ahora devolvemos un mock inteligente
    
    mock_diagnoses = [
        {"diagnosis": "DERMATITIS DE CONTACTO", "priority": 2, "confidence": 0.85},
        {"diagnosis": "URTICARIA AGUDA", "priority": 3, "confidence": 0.92},
        {"diagnosis": "ACNÉ VULGAR", "priority": 1, "confidence": 0.95}
    ]
    
    result = random.choice(mock_diagnoses)

    return jsonify(result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3008)