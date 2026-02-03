package main

import (
	"encoding/base64"
	"fmt"
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/skip2/go-qrcode"
)

// --- ESTRUCTURAS ---
type QrGenerationRequest struct {
	Content string `json:"content"` // El texto que irá dentro del QR
}

type QrGenerationResponse struct {
	QrBase64 string `json:"qr_image"` // La imagen en base64
}

// --- HANDLER ---
func generateHandler(c *fiber.Ctx) error {
	var req QrGenerationRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid Body"})
	}

	log.Printf("🔄 Generando QR para contenido: %s", req.Content)

	// Generar Imagen QR (Nivel Medium, 256px)
	png, err := qrcode.Encode(req.Content, qrcode.Medium, 256)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Error generando imagen QR"})
	}

	qrBase64 := base64.StdEncoding.EncodeToString(png)
	qrImageUrl := "data:image/png;base64," + qrBase64

	return c.JSON(QrGenerationResponse{
		QrBase64: qrImageUrl,
	})
}

// --- MAIN ---
func main() {
	app := fiber.New()

	// Endpoint interno para microservicios
	app.Post("/generate", generateHandler)

	fmt.Println("---------------------------------------------------------")
	fmt.Println("🛡️  Microservicio QR (Worker Mode) corriendo en puerto 8080")
	fmt.Println("---------------------------------------------------------")

	log.Fatal(app.Listen(":3006")) // Puerto interno de Docker
}
