import pandas as pd
from sqlalchemy import create_engine

from src.config import DBConfig

def load_user_product_rating(limit: int | None = None) -> pd.DataFrame:
    cfg = DBConfig()
    url = f"mysql+pymysql://{cfg.user}:{cfg.password}@{cfg.host}:{cfg.port}/{cfg.database}"
    engine = create_engine(url)

    q = "SELECT * FROM user_product_rating"
    if limit is not None:
        q += f" LIMIT {int(limit)}"

    return pd.read_sql(q, engine)