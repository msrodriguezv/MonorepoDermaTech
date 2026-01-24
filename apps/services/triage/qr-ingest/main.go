package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log" // 👈 Usamos este paquete para imprimir en consola
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/swagger"
	"github.com/google/uuid"
	"github.com/skip2/go-qrcode"

	// Importa la documentación generada
	_ "qr-ingest/docs"
)

// Estructura de entrada
type IngestRequest struct {
	StudentId string   `json:"studentId" example:"EST-SWAGGER-01"`
	Symptoms  []string `json:"symptoms" example:"dolor, mareo"`
}

// Estructura de respuesta
type IngestResponse struct {
	Status        string `json:"status" example:"SUCCESS"`
	Message       string `json:"message" example:"Procesado Correctamente"`
	AppointmentId string `json:"appointmentId" example:"550e8400..."`
	QrData        string `json:"qr_data" example:"DERMA|EST|UUID"`
	QrImage       string `json:"qr_image" example:"data:image/png;base64..."`
}

// Estructura Kafka
type KafkaMessage struct {
	StudentId     string   `json:"studentId"`
	Symptoms      []string `json:"symptoms"`
	AppointmentId string   `json:"appointmentId"`
	QrData        string   `json:"qrData"`
	Timestamp     string   `json:"timestamp"`
}

// @title           DermaTech Triage API
// @version         1.0
// @description     Microservicio de Ingesta (Lineal)
// @host            localhost:3006
// @BasePath        /api

// @Summary      Generar QR
// @Description  Recibe datos y devuelve el QR generado (Imagen + Texto)
// @Tags         Triage
// @Accept       json
// @Produce      json
// @Param        request body IngestRequest true "Datos"
// @Success      200  {object}  IngestResponse
// @Router       /triage/ingest [post]
func ingestHandler(c *fiber.Ctx) error {
	var req IngestRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Body inválido"})
	}

	log.Printf("🔄 Procesando estudiante: %s", req.StudentId)

	newUuid := uuid.New().String()
	qrContent := fmt.Sprintf("DERMA|%s|%s", req.StudentId, newUuid)

	// Generar Imagen QR
	png, err := qrcode.Encode(qrContent, qrcode.Medium, 256)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Error generando imagen"})
	}
	qrBase64 := base64.StdEncoding.EncodeToString(png)
	qrImageUrl := "data:image/png;base64," + qrBase64

	// Enviar a Kafka
	msg := KafkaMessage{
		StudentId:     req.StudentId,
		Symptoms:      req.Symptoms,
		AppointmentId: newUuid,
		QrData:        qrContent,
		Timestamp:     time.Now().Format(time.RFC3339),
	}
	msgBytes, _ := json.Marshal(msg)
	// producer.Produce(...)
	log.Printf("✅ Kafka Msg: %s", string(msgBytes))

	return c.JSON(IngestResponse{
		Status:        "SUCCESS",
		Message:       "Procesado Correctamente",
		AppointmentId: newUuid,
		QrData:        qrContent,
		QrImage:       qrImageUrl,
	})
}

func main() {
	app := fiber.New()

	// Configuración de Swagger
	app.Get("/swagger/*", swagger.HandlerDefault)

	// Rutas de API
	app.Post("/api/triage/ingest", ingestHandler)

	// 👇 AQUÍ ESTÁN LOS MENSAJES QUE PEDISTE (Con la sintaxis correcta de Go)
	fmt.Println("---------------------------------------------------------")
	fmt.Println("🛡️  Servidor GO (QrIngest) corriendo en puerto 3006")
	
	// Esta es la línea con el link clicable:
	log.Println("📄 Swagger UI disponible en: http://localhost:3006/swagger/")
	fmt.Println("---------------------------------------------------------")

	log.Fatal(app.Listen(":3006"))
}