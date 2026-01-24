# Olist Review Score Predictor (MySQL → Training → FastAPI)

Entrené un modelo que predice el puntaje de una review (1–5) usando datos del dataset Olist almacenados en **MySQL**.  
El proyecto está pensado como “mini-producto”: el entrenamiento se ejecuta contra una **base funcional** (no archivos parquet) y el modelo se expone como una **API**.

## Qué hice (resumen)
- Construí una fuente de entrenamiento en MySQL (`order_item_review_ml`) consolidando señales de producto, pagos, envío y estado del pedido.
- Entrené un **pipeline de scikit-learn** con:
  - Target Encoding para alta cardinalidad (`seller_id`)
  - Ordinal Encoding para el resto de categóricas
  - HistGradientBoostingRegressor para regresión del score
- Implementé una API en **FastAPI** con:
  - `/retrain`: reentrena desde MySQL y versiona artefactos
  - `/predict`: predice usando el último modelo entrenado

## Trabajo de SQL (vistas y feature store dentro de MySQL)
La preparación de datos no vive en notebooks: está modelada en SQL sobre MySQL.  
Definí vistas agregadas y una vista final orientada a ML:

- Vistas agregadas (ej.: pagos por orden, resumen de reviews, etc.)
- Vista final: `order_item_review_ml`  
  (concentra features numéricas y categóricas + `review_score` como target)

Esto permite que el entrenamiento se ejecute siempre sobre la **misma interfaz estable** (la vista), aunque los datos subyacentes cambien.
Estas implementaciones se encuentran en la carpeta sql\

## Entrenamiento desde MySQL
El endpoint `/retrain` ejecuta un `SELECT * FROM order_item_review_ml`, entrena y guarda:
- `models/review_score_pipe_<timestamp>.joblib` (pipeline completo)
- `models/review_score_pipe_<timestamp>.meta.json` (métricas + contrato de columnas)

## Resultados (baseline)
Métricas registradas en el `.meta.json` del último entrenamiento:
- MAE: ~0.90
- RMSE: ~1.16
- Accuracy exacta (redondeo 1–5): ~0.28
- Error > 1 estrella: ~0.13

## API (demo)
- `POST /retrain` → entrena desde MySQL y devuelve métricas + paths
- `POST /predict` → recibe un `record` con las columnas de `training_columns` y devuelve una predicción continua

> Nota: `training_columns` y `feature_spec` quedan documentados en el `.meta.json` generado automáticamente.