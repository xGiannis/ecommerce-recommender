from __future__ import annotations

import json
from dataclasses import asdict
from datetime import datetime
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error

from src.recommender.data_construct import load_training_frame, construct_x_y
from src.recommender.pipeline import infer_feature_spec, build_recommender_pipeline, FeatureSpec



def train(
    limit : int | None = None,
    out_dir: str = "models",
    random_state: int = 42,
) -> None:

    df = load_training_frame(limit=limit)
    X, y = construct_x_y(df)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=random_state
    )

    feature_spec = infer_feature_spec(X_train, exclude=[])

    pipeline = build_recommender_pipeline(feature_spec)

    pipeline.fit(X_train, y_train)


    y_pred = pipeline.predict(X_test)


    #stats
    mae = mean_absolute_error(y_test, y_pred)
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    y_pred_round = np.clip(np.rint(y_pred), 1, 5).astype(int)
    y_test_int = y_test.astype(int).to_numpy()

    accuracy = float((y_pred_round == y_test_int).mean())
    off_by_more_than1 = float((np.abs(y_pred_round - y_test_int) > 1).mean())


    #guardo el modelo
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    model_path = out / f"review_score_pipe_{stamp}.joblib"
    meta_path = out / f"review_score_pipe_{stamp}.meta.json"

    joblib.dump(pipeline, model_path)

    meta = {
        "trained_at": stamp,
        "limit": limit,
        "metrics": {
            "mae": mae,
            "rmse": rmse,
            "accuracy_exact": accuracy,
            "off_by_more_than1": off_by_more_than1,
        },
        "feature_spec": asdict(feature_spec),
        "training_columns": list(X_train.columns),
        "target": "review_score",
    }

    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")



    return {
        "model_path": str(model_path),
        "meta_path": str(meta_path),
        "metrics": meta["metrics"],
    }