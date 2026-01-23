from __future__ import annotations

TARGET_COL = "review_score"

COLS_TO_DROP = [
    TARGET_COL,
    "review_creation_date",
    "review_answer_timestamp",
    "review_delay_days",
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
    "customer_city",
    "customer_state",
    "order_item_id",
    "product_id",
    "order_id",
]

HIGH_CARDINALITY = ["seller_id"]