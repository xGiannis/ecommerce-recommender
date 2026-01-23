from __future__ import annotations

import joblib
import pandas as pd


def predict_one(
    model_path: str,
    input_data: dict,
    expected_cols : list[str]
) -> float:


    model = joblib.load(model_path)

    X= pd.DataFrame([input_data])

    
    if expected_cols is not None:
        missing = [c for c in expected_cols if c not in X.columns]
        if missing:
            raise ValueError(f"Faltan columnas requeridas: {missing}")
        X = X[expected_cols]



    return float(model.predict(X)[0])