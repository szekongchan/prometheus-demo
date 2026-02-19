# Prometheus Demo - Project Status

**Last Updated**: February 19, 2026

## ✅ Completed

- **Step 1**: Terraform infrastructure (4 EC2 instances, security groups, SSH keys)
- **Step 2**: Web server with Flask app, node_exporter, database connectivity
- **Step 3**: DB server with MariaDB, mysqld_exporter, node_exporter, schema, seed data
- **Step 4**: Monitor server with Prometheus and Grafana (dashboard provisioned)
- **Step 5**: Load generator server with Locust

## 🔄 In Progress - TODO for Tomorrow

### Task 1: Verify endpoint labels in Prometheus

- **Action**: Go to Prometheus `http://<monitor_ip>:9090` → Graph tab
- **Query**: `http_request_duration_seconds_bucket`
- **Find**: Confirmed endpoint label normalization is `/api/order/:id`
- **Status**: Completed

### Task 2: Update dashboard queries

- **Location**: `monitoring/dashboards/prometheus-demo-dashboard.json`
- **Current Issue**: GET /order and POST /order queries had no data due to label mismatch
- **Action**: Updated endpoint filters to match app labels (`/api/order/:id`, `/api/order`)
- **Panels to fix**:
  - Panel ID 4: GET /order - 95th Percentile Response Time
  - Panel ID 5: POST /order - 95th Percentile Response Time
  - Panel ID 6: GET /order - Response Time Heatmap
  - Panel ID 7: POST /order - Response Time Heatmap
- **Status**: Completed

### Task 3: Start Locust load test

- **URL**: `http://<loadgen_ip>:8089`
- **Settings**: 10 users, 1-2 spawn rate
- **Duration**: Run for 2-3 minutes to generate data
- **Purpose**: Generate traffic to populate dashboard metrics
- **Run executed**: 2 minutes headless (`-u 10 -r 2 -t 2m`) from load-generator
- **Result**: 590 requests, 0 failures
- **Status**: Completed

### Task 4: Verify dashboard displays metrics

- **Check**: All panels show data after load test runs
  - CPU utilization (all servers)
  - Network IO (RX/TX for all servers)
  - 95th percentile response times (GET and POST)
  - Heatmaps (response time distribution overtime)
- **Validation done**: Prometheus queries used by panels return non-empty series; Grafana visual check completed (GET p95 ~9.44ms, POST p95 ~13ms, other panels rendering)
- **Status**: Completed

### Task 5: Discuss improvements

- **Topics**: How to enhance the demo
- **Possible ideas**:
  - Additional dashboards
  - Error rate tracking
  - Database query metrics
  - Any user preferences
- **Status**: Next

### Task 6: Run API + metrics smoke test

- **When**: After services are up again (AWS or local)
- **Scope**:
  - `GET /health`
  - `POST /api/order` (verify create path)
  - `GET /api/order/<id>` (verify customer details in response)
  - Check `/metrics` for `http_requests_total` and `http_request_duration_seconds`
- **Purpose**: Confirm end-to-end behavior after latest code/dashboard updates
- **Result**:
  - `GET /health` = 200
  - `POST /api/order` = 201 (created order_id 163)
  - `GET /api/order/163` = 200 (includes customer details)
  - `/metrics` contains `http_requests_total` and `http_request_duration_seconds`
- **Status**: Completed

## 📊 Current Infrastructure Status

**Current state:** Services are running on AWS.

**When running, services expected:**

- Web Server: Flask app + node_exporter + order-api systemd service
- DB Server: MariaDB + mysqld_exporter + node_exporter
- Monitor Server: Prometheus + Grafana (with provisioned dashboard)
- Load Generator: Locust web UI

**Access URLs** (from terraform output):

- Prometheus: `http://<monitor_ip>:9090`
- Grafana: `http://<monitor_ip>:3000` (admin/admin)
- Locust: `http://<loadgen_ip>:8089`

## 🔍 Known Issues

1. **No active blocking issues**

- Dashboard endpoint label mismatch is fixed.
- Load generation, dashboard verification, and smoke test all passed.

## 📁 File Structure

```
prometheus-demo/
├── src/
│   ├── app.py
│   └── requirements.txt
├── db/
│   ├── schema.sql
│   └── seed.sql
├── services/
│   ├── order-api.service
│   ├── mysqld_exporter.service
│   ├── node_exporter.service
│   ├── prometheus.service
│   └── locust.service
├── monitoring/
│   ├── prometheus.yml
│   ├── grafana-datasource.yaml
│   └── dashboards/
│       └── prometheus-demo-dashboard.json
├── loadtest/
│   └── locustfile.py
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars
    └── user-data/
        ├── web_server.sh.tftpl
        ├── db_server.sh.tftpl
        ├── monitor_server.sh.tftpl
        └── loadgenerator.sh.tftpl
```

## 🚀 Next Session Workflow

1. Proceed to Task 5 improvements discussion
2. Optional: run longer/stress scenarios and set alert thresholds

---

**Questions for tomorrow?** Check this file first!
