package main

import (
	"bytes"
	"encoding/json"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gofiber/fiber/v2"
)

// TestIngestHandlerSuccess verifica el "Camino Feliz" (Happy Path)
func TestIngestHandlerSuccess(t *testing.T) {
	// 1. Configuramos una App de Fiber temporal (falsa)
	app := fiber.New()
	app.Post("/api/triage/ingest", ingestHandler)

	// 2. Preparamos los datos de prueba (JSON)
	payload := []byte(`{
		"studentId": "EST-TEST-UNITARIO",
		"symptoms": ["test", "automatizado"]
	}`)

	// 3. Creamos una petición HTTP falsa (Mock Request)
	req := httptest.NewRequest("POST", "/api/triage/ingest", bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")

	// 4. Ejecutamos la petición en nuestra App falsa
	resp, err := app.Test(req, -1) // -1 desactiva el timeout para pruebas

	// 5. VERIFICACIONES (ASSERTS)

	// A) Verificar que no hubo error técnico al llamar
	if err != nil {
		t.Fatalf("Error al realizar la petición: %v", err)
	}

	// B) Verificar que el código HTTP sea 200 OK
	if resp.StatusCode != 200 {
		t.Errorf("Se esperaba código 200, pero se recibió %d", resp.StatusCode)
	}

	// C) Verificar el contenido del cuerpo (Body)
	// Decodificamos el JSON de respuesta
	var responseBody IngestResponse
	if err := json.NewDecoder(resp.Body).Decode(&responseBody); err != nil {
		t.Fatalf("No se pudo decodificar la respuesta JSON: %v", err)
	}

	// D) Validar campos específicos
	if responseBody.Status != "SUCCESS" {
		t.Errorf("Se esperaba status 'SUCCESS', recibido '%s'", responseBody.Status)
	}

	// E) Verificar que SÍ nos devolvió una imagen
	if !strings.HasPrefix(responseBody.QrImage, "data:image/png;base64") {
		t.Error("La respuesta no contiene una imagen base64 válida en 'qr_image'")
	}

	// F) Verificar que generó un UUID
	if len(responseBody.AppointmentId) == 0 {
		t.Error("El AppointmentId vino vacío")
	}
}

// TestIngestHandlerBadRequest verifica qué pasa si enviamos basura
func TestIngestHandlerBadRequest(t *testing.T) {
	app := fiber.New()
	app.Post("/api/triage/ingest", ingestHandler)

	// Enviamos un JSON roto (falta una llave)
	payload := []byte(`{ "studentId": "ERROR" `) 

	req := httptest.NewRequest("POST", "/api/triage/ingest", bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")

	resp, _ := app.Test(req, -1)

	// Debería fallar con 400 Bad Request
	if resp.StatusCode != 400 {
		t.Errorf("Se esperaba código 400 por JSON inválido, pero se recibió %d", resp.StatusCode)
	}
}
