# Prometheus Demo - Project Status

**Last Updated**: February 18, 2026 - End of Day

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
- **Find**: What are the actual `endpoint` label values?
- **Expected**: Might be `/api/order/<int:order_id>` instead of `/api/order/[id]`
- **Status**: Not started

### Task 2: Update dashboard queries

- **Location**: `monitoring/dashboards/prometheus-demo-dashboard.json`
- **Current Issue**: GET /order and POST /order queries have no data
- **Action**: Update endpoint filters to match actual labels from Prometheus
- **Panels to fix**:
  - Panel ID 4: GET /order - 95th Percentile Response Time
  - Panel ID 5: POST /order - 95th Percentile Response Time
  - Panel ID 6: GET /order - Response Time Heatmap
  - Panel ID 7: POST /order - Response Time Heatmap
- **Status**: Blocked on Task 1

### Task 3: Start Locust load test

- **URL**: `http://<loadgen_ip>:8089`
- **Settings**: 10 users, 1-2 spawn rate
- **Duration**: Run for 2-3 minutes to generate data
- **Purpose**: Generate traffic to populate dashboard metrics
- **Status**: Not started

### Task 4: Verify dashboard displays metrics

- **Check**: All panels show data after load test runs
  - CPU utilization (all servers)
  - Network IO (RX/TX for all servers)
  - 95th percentile response times (GET and POST)
  - Heatmaps (response time distribution overtime)
- **Status**: Blocked on Tasks 1-3

### Task 5: Discuss improvements

- **Topics**: How to enhance the demo
- **Possible ideas**:
  - Additional dashboards
  - Error rate tracking
  - Database query metrics
  - Any user preferences
- **Status**: After Tasks 1-4 complete

## 📊 Current Infrastructure Status

**All Services Running:**

- Web Server: Flask app + node_exporter + order-api systemd service
- DB Server: MariaDB + mysqld_exporter + node_exporter
- Monitor Server: Prometheus + Grafana (with provisioned dashboard)
- Load Generator: Locust web UI

**Access URLs** (from terraform output):

- Prometheus: `http://<monitor_ip>:9090`
- Grafana: `http://<monitor_ip>:3000` (admin/admin)
- Locust: `http://<loadgen_ip>:8089`

## 🔍 Known Issues

1. **Dashboard metrics not showing**
   - Cause: Endpoint label mismatch in queries
   - Impact: GET/POST response time panels blank
   - Severity: High - blocks dashboard verification

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

1. Mark Task 1 as in-progress
2. Check Prometheus endpoint labels
3. Report findings
4. I'll update dashboard queries
5. Run Tasks 3-5 in sequence

---

**Questions for tomorrow?** Check this file first!
