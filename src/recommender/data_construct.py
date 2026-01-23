from __future__ import annotations

import pandas as pd

from src.data_load import load_order_item_review_ml
from src.recommender.contract import TARGET_COL, COLS_TO_DROP


def load_training_frame(limit: int | None = None) -> pd.DataFrame:
    df = load_order_item_review_ml(limit=limit)
    return df

def construct_x_y(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.Series]:
    X = df.drop(columns=COLS_TO_DROP, errors='ignore')
    y = df[TARGET_COL].astype('float32')
    return X, y

