# src/recommender/pipeline.py
from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OrdinalEncoder, TargetEncoder
from sklearn.ensemble import HistGradientBoostingRegressor

from src.recommender.contract import HIGH_CARDINALITY


@dataclass(frozen=True)
class FeatureSpec:
    numeric: Sequence[str]
    categorical_other: Sequence[str]
    categorical_high_card: Sequence[str]


def infer_feature_spec(df: pd.DataFrame, exclude: Sequence[str]) -> FeatureSpec:
    numeric = df.select_dtypes(include=["number"]).columns.difference(exclude).tolist()
    categorical = df.select_dtypes(include=["object", "category"]).columns.difference(exclude).tolist()
    categorical_high_card = [col for col in categorical if col in HIGH_CARDINALITY]
    categorical_other = [col for col in categorical if col not in HIGH_CARDINALITY]

    return FeatureSpec(
        numeric=numeric,
        categorical_other=categorical_other,
        categorical_high_card=categorical_high_card,
    )

def build_recommender_pipeline(feature_spec: FeatureSpec) -> Pipeline:
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", "passthrough", feature_spec.numeric),
            ("cat_other", OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1), feature_spec.categorical_other),
            ("cat_high_card", TargetEncoder(), feature_spec.categorical_high_card),
        ],
        remainder="drop",
    )

    model = HistGradientBoostingRegressor()

    pipeline = Pipeline(steps=[
        ("preprocessor", preprocessor),
        ("model", model),
    ])

    return pipeline

