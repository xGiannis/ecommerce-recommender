from __future__ import annotations

from src.recommender.train import train

import json
from pathlib import Path

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from src.recommender.predict import predict_one


# Ruta robusta: models/ al lado de la raíz del repo 
PROJECT_ROOT = Path(__file__).resolve().parents[2]
MODELS_DIR = PROJECT_ROOT / "models"


app = FastAPI(title="Review Score Predictor")

class RetrainRequest(BaseModel):
    limit: int | None = None   

@app.post("/retrain")
def retrain(req: RetrainRequest):
    try:
        result = train(limit=req.limit,out_dir=str(MODELS_DIR))
        return result  # {model_path, meta_path, metrics}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



def get_latest_model() -> tuple[str, list[str] | None]:
    model_files = sorted(MODELS_DIR.glob("review_score_pipe_*.joblib")) #devuelve el modelo mas reciente, glob agarra todos los archivos que cumplen"
    if not model_files:                                                 #review_score_pipe_...joblib. luego, sorted los ordena
        raise FileNotFoundError("No hay modelos en /models. Entrene primero.")

    latest = model_files[-1]
    meta = Path(str(latest).replace(".joblib", ".meta.json"))
    expected_cols = None
    if meta.exists():
        expected_columns = json.loads(meta.read_text(encoding="utf-8")).get("training_columns")

    return str(latest), expected_cols


class PredictRequest(BaseModel):
    record: dict


@app.post("/predict")
def predict(req: PredictRequest):
    try:
        model_path, expected_cols = get_latest_model()
        pred = predict_one(model_path, req.record, expected_cols=expected_cols)
        return {"prediction": pred, "model": model_path}
    except FileNotFoundError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {e}")