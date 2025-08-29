import pytest
from app.app import app as flask_app


def test_home_route_returns_200():
    client = flask_app.test_client()
    response = client.get('/')
    assert response.status_code == 200
    assert b"<html" in response.data.lower()


