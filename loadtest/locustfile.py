import os
import random
from locust import HttpUser, task, between

# Target host from environment variable
TARGET_HOST = os.getenv("TARGET_HOST", "http://localhost:5000")


class OrderAPIUser(HttpUser):
    host = TARGET_HOST
    wait_time = between(0, 0.1)  # Minimal think time for higher pressure

    @task(1)
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

    @task(5)
    def create_order(self):
        """Create a new order (higher frequency)"""
        customer_id = random.randint(1, 5)  # We have 5 customers in seed data
        
        # Generate 20-50 random items per order to increase write pressure
        num_items = random.randint(20, 50)
        items = []
        for _ in range(num_items):
            items.append({
                "product_id": random.randint(101, 108),
                "quantity": random.randint(1, 5),
                "unit_price": round(random.uniform(9.99, 999.99), 2)
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
