# Tests básicos para CloudEdu Services


def test_imports():
    """Test que las importaciones funcionan"""
    try:
        from flask import Flask
        import json
        import datetime

        assert True
    except ImportError as e:
        assert False, f"Import failed: {e}"


def test_basic_app_creation():
    """Test básico de creación de la app"""
    from flask import Flask

    app = Flask(__name__)
    assert app is not None
    assert app.name == "__main__"


def test_path_exists():
    """Test que el módulo de pathlib funciona"""
    from pathlib import Path

    test_path = Path(".")
    assert test_path.exists()


def test_json_operations():
    """Test operaciones JSON básicas"""
    import json

    test_data = {"test": "value", "number": 123}
    json_string = json.dumps(test_data)
    parsed = json.loads(json_string)
    assert parsed["test"] == "value"
    assert parsed["number"] == 123
