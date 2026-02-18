import os
import random
from locust import HttpUser, task, between

# Target host from environment variable
TARGET_HOST = os.getenv("TARGET_HOST", "http://localhost:5000")


class OrderAPIUser(HttpUser):
    host = TARGET_HOST
    wait_time = between(1, 3)  # Wait 1-3 seconds between requests

    @task(3)
    def get_order(self):
        """Retrieve an existing order (higher frequency)"""
        order_id = random.randint(1, 8)  # We have 8 orders in seed data
        with self.client.get(
            f"/api/order/{order_id}",
            catch_response=True,
            name="/api/order/[id]"
        ) as response:
            if response.status_code == 200:
                response.success()
            elif response.status_code == 404:
                response.failure("Order not found")
            else:
                response.failure(f"Unexpected status: {response.status_code}")

    @task(1)
    def create_order(self):
        """Create a new order (lower frequency)"""
        customer_id = random.randint(1, 5)  # We have 5 customers in seed data
        
        # Generate 1-3 random items per order
        num_items = random.randint(1, 3)
        items = []
        for _ in range(num_items):
            items.append({
                "product_name": random.choice([
                    "Laptop", "Mouse", "Keyboard", "Monitor", "Headphones",
                    "Webcam", "USB Cable", "Dock Station", "SSD Drive"
                ]),
                "quantity": random.randint(1, 5),
                "price": round(random.uniform(9.99, 999.99), 2)
            })
        
        payload = {
            "customer_id": customer_id,
            "items": items
        }
        
        with self.client.post(
            "/api/order",
            json=payload,
            catch_response=True,
            name="/api/order"
        ) as response:
            if response.status_code == 201:
                response.success()
            else:
                response.failure(f"Failed to create order: {response.status_code}")
