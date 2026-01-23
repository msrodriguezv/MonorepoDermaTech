import pytest
from main import app

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_health_check(client):
    """Functional test for health endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    assert response.json["status"] == "AI Agent Running"

def test_analyze_endpoint(client):
    """Functional test for analysis endpoint"""
    response = client.post('/analyze')
    assert response.status_code == 200
    assert "diagnosis" in response.json