const { Kafka } = require('kafkajs');
const crypto = require('crypto');

async function run() {
  const kafka = new Kafka({
    clientId: 'test-producer',
    brokers: ['localhost:9092'],
  });

  const producer = kafka.producer();
  await producer.connect();
  console.log('🚀 Conectado a Kafka');

  // Generamos un UUID real para la cita
  const realUUID = crypto.randomUUID();

  // Caso de prueba: Reacción alérgica aguda (Dermatología)
  const datosPaciente = {
    appointmentId: realUUID, 
    qrData: 'QR-DERMA-URGENCIA-001',
    symptoms: {
      description: 'Tengo ronchas rojas que pican mucho en los brazos y el cuello, aparecieron de golpe después del almuerzo.',
      painLevel: 9,
      duration: '30 minutos'
    }
  };

  await producer.send({
    topic: 'patient-triage-topic',
    messages: [
      { value: JSON.stringify(datosPaciente) },
    ],
  });

  console.log('✅ Paciente crítico enviado:', datosPaciente.appointmentId);
  console.log('📝 Síntomas:', datosPaciente.symptoms.description);

  await producer.disconnect();
}

run().catch(console.error);