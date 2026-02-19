import os
import time
from decimal import Decimal

from flask import Flask, jsonify, request
import pymysql
from prometheus_client import Counter, Histogram, start_http_server

APP_HOST = "0.0.0.0"
APP_PORT = 5000
METRICS_PORT = 8000

DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "app_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "orders_db")
DEMO_DELAY_MS = int(os.getenv("DEMO_DELAY_MS", "0"))

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "http_status"],
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"],
)

def _db_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=False,
    )

def _endpoint_label():
    path = request.path
    if request.method == "GET" and path.startswith("/api/order/"):
        return "/api/order/:id"
    return path

@app.before_request
def _before_request():
    request._start_time = time.time()
    if DEMO_DELAY_MS > 0 and request.path.startswith("/api/order"):
        time.sleep(DEMO_DELAY_MS / 1000)


@app.after_request
def _after_request(response):
    elapsed = time.time() - getattr(request, "_start_time", time.time())
    endpoint = _endpoint_label()
    REQUEST_LATENCY.labels(request.method, endpoint).observe(elapsed)
    REQUEST_COUNT.labels(request.method, endpoint, response.status_code).inc()
    return response


@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "ok"}), 200


@app.route("/api/order/<int:order_id>", methods=["GET"])
def get_order(order_id):
    conn = _db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT o.order_id, o.customer_id, o.total_amount, o.status, o.created_at, "
                "c.name AS customer_name, c.email AS customer_email "
                "FROM orders o "
                "LEFT JOIN customer c ON o.customer_id = c.customer_id "
                "WHERE o.order_id = %s",
                (order_id,),
            )
            order = cursor.fetchone()
            if not order:
                return jsonify({"error": "order not found"}), 404

            cursor.execute(
                "SELECT item_id, product_id, quantity, unit_price "
                "FROM order_items WHERE order_id = %s",
                (order_id,),
            )
            items = cursor.fetchall()

        order["customer"] = {
            "customer_id": order["customer_id"],
            "name": order.pop("customer_name"),
            "email": order.pop("customer_email"),
        }
        order["items"] = items
        return jsonify(order), 200
    finally:
        conn.close()


@app.route("/api/order", methods=["POST"])
def create_order():
    payload = request.get_json(silent=True) or {}
    customer_id = payload.get("customer_id")
    customer_payload = payload.get("customer") or {}
    items = payload.get("items", [])

    if not customer_id or not isinstance(items, list) or not items:
        return jsonify({"error": "customer_id and items are required"}), 400

    try:
        total_amount = sum(
            Decimal(str(item.get("quantity", 0)))
            * Decimal(str(item.get("unit_price", 0)))
            for item in items
        )
    except Exception:
        return jsonify({"error": "invalid item payload"}), 400

    conn = _db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT customer_id FROM customer WHERE customer_id = %s",
                (customer_id,),
            )
            customer = cursor.fetchone()
            if not customer:
                customer_name = customer_payload.get("name") or f"Customer {customer_id}"
                customer_email = customer_payload.get("email") or f"customer{customer_id}@example.com"
                cursor.execute(
                    "INSERT INTO customer (customer_id, name, email) VALUES (%s, %s, %s)",
                    (customer_id, customer_name, customer_email),
                )

            cursor.execute(
                "INSERT INTO orders (customer_id, total_amount, status) "
                "VALUES (%s, %s, %s)",
                (customer_id, total_amount, "created"),
            )
            order_id = cursor.lastrowid

            order_item_values = []
            for item in items:
                order_item_values.append(
                    (
                        order_id,
                        item.get("product_id"),
                        item.get("quantity"),
                        item.get("unit_price"),
                    )
                )

            cursor.executemany(
                "INSERT INTO order_items (order_id, product_id, quantity, unit_price) "
                "VALUES (%s, %s, %s, %s)",
                order_item_values,
            )

        conn.commit()
    except Exception as exc:
        conn.rollback()
        return jsonify({"error": "database error", "detail": str(exc)}), 500
    finally:
        conn.close()

    return jsonify({"order_id": order_id, "total_amount": str(total_amount)}), 201


if __name__ == "__main__":
    start_http_server(METRICS_PORT)
    app.run(host=APP_HOST, port=APP_PORT)
