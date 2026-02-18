<<<<<<< HEAD
# prometheus-demo
=======
# Prometheus/Grafana Demo on AWS

A comprehensive demonstration of monitoring and observability using Prometheus and Grafana on AWS infrastructure, showcasing real-world application monitoring with various load scenarios.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Components Description](#components-description)
- [Demo Flow](#demo-flow)
- [Prerequisites](#prerequisites)
- [Step-by-Step Setup Guide](#step-by-step-setup-guide)
- [Testing Procedures](#testing-procedures)
- [Cleanup](#cleanup)

## Architecture Overview

This demo deploys 4 EC2 instances on AWS to demonstrate comprehensive monitoring and observability:

```
┌──────────────────────────────────┐
│  Load Generation Server          │
│  (Locust/Custom Python)          │
│  - Normal loading                │
│  - High read requests            │
│  - High write requests           │
│  - DB CPU stress                 │
└──────────────┬───────────────────┘
               │
               │ HTTP Requests (port 5000)
               │
               ▼
    ┌──────────────────┐         ┌──────────────────┐
    │  Web Server      │         │  Monitor Server  │
    │  (Flask App)     │◄────────│  (Prometheus &   │
    │  - Query API     │ Metrics │   Grafana)       │
    │  - Write API     │ (8000,  │                  │
    │  - Metrics       │  9100)  │  - Prometheus    │
    │   endpoints      │         │  - Grafana       │
    └────────┬─────────┘         │  - Dashboards    │
             │                   └────────┬─────────┘
             │ MySQL Query                │
             │ (port 3306)                │
             │                 Metrics    │
             │                (9100, 9104)│
             ▼                            ▼
      ┌────────────────┐
      │  MySQL DB      │
      │                │
      │  - customer    │
      │  - order       │
      │  - orderitems  │
      │  - mysqld_     │
      │    exporter    │
      │  - node_       │
      │    exporter    │
      └────────────────┘
```

### Network Architecture

- All instances deployed in a single VPC with security groups for controlled access
- Web Server: Public/Private subnet (HTTP ports 5000, 8000 for metrics)
- MySQL DB: Private subnet (Port 3306, Prometheus exporter on 9104)
- Monitor Server: Public subnet (Prometheus 9090, Grafana 3000) - monitors Web Server and DB Server only
- Load Gen Server: Public subnet (Locust 8089) - loads Web Server only

## Components Description

### 1. Web Server (Flask Application)

**Purpose**: Serves API endpoints for order management with built-in metrics collection

**Specifications**:

- Instance Type: t3.medium
- OS: Amazon Linux 2 or Ubuntu 22.04
- Application: Python 3.9+ with Flask framework
- Metrics: Prometheus client library

**Features**:

```
GET  /api/order/<order_id>        - Query order by ID
POST /api/order                     - Create new order
GET  /metrics                       - Prometheus metrics endpoint
```

**Metrics Exposed**:

- HTTP request count (by endpoint, method, status)
- HTTP request duration (histogram)
- Custom business metrics (orders processed, items written)

### 2. MySQL Database Server

**Purpose**: Persistent data storage for order management system

**Specifications**:

- Instance Type: t3.medium
- OS: Amazon Linux 2 or Ubuntu 22.04
- Database: MySQL 8.0
- Metrics Export: mysqld_exporter (Prometheus)

**Schema**:

```sql
CREATE TABLE customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    total_amount DECIMAL(10,2),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
```

**Metrics Exposed**:

- Connection count
- Query performance metrics
- Replication lag (if applicable)
- InnoDB metrics
- Table statistics

### 3. Monitor Server (Prometheus & Grafana)

**Purpose**: Centralized monitoring and visualization

**Specifications**:

- Instance Type: t3.small (expandable based on metrics volume)
- OS: Amazon Linux 2 or Ubuntu 22.04
- Prometheus: Latest stable version
- Grafana: Latest stable version

**Prometheus Targets**:

- Web Server metrics (port 8000)
- MySQL Database exporter (port 9104)
- Node exporter on all servers (port 9100)

**Grafana Dashboards** (3 main dashboards):

1. **Infrastructure Dashboard**
   - CPU utilization (Web Server and DB Server)
   - Network I/O (Web Server and DB Server)
   - Memory usage
   - Disk I/O

2. **Application Performance Dashboard**
   - 95th percentile response time for read API
   - Request latency distribution (heatmap)
   - Request count per second
   - Error rate

3. **Database Dashboard**
   - Connection count
   - Query execution time
   - Slow queries
   - InnoDB buffer pool efficiency

### 4. Load Generation Server

**Purpose**: Simulate realistic and stress-test scenarios

**Specifications**:

- Instance Type: t3.medium
- OS: Amazon Linux 2 or Ubuntu 22.04
- Load Testing: Locust (Python-based)

**Load Scenarios**:

- **Stage 1 - Normal Loading**: 10 users, steady-state for 5 minutes
- **Stage 2 - High Read Requests**: 50 concurrent users, 80% read / 20% write for 5 minutes
- **Stage 3 - High Write Requests**: 30 concurrent users, 20% read / 80% write for 5 minutes
- **Stage 4 - DB CPU Stress**: Combined 40 concurrent users + stress-ng on DB server for 10 minutes

## Demo Flow

### Phase 1: System Stabilization (5 minutes)

1. All servers operational and connected to Prometheus
2. Baseline metrics collected
3. Grafana dashboards initialized with historical data

### Phase 2: Normal Load (5 minutes)

- Load generator ramps to 10 users
- Observe steady-state metrics on Grafana
- Verify API response times (target <100ms)
- Monitor resource utilization (CPU <30%, Network <50%)

### Phase 3: High Read Load (5 minutes)

- Load increases to 50 concurrent users
- 80% read operations (query API), 20% write
- Observe response time distribution heatmap
- Monitor database connection pool
- Verify 95th percentile response time (target <300ms)

### Phase 4: High Write Load (5 minutes)

- Load changes to 30 concurrent users
- 20% read, 80% write operations
- Observe increased database write performance
- Monitor disk I/O on database server
- Check for write contention

### Phase 5: Database Stress Test (10 minutes)

- 40 concurrent users (mixed read/write)
- stress-ng adds CPU load to database (50-80% CPU)
- Observe system behavior under stress
- Verify graceful degradation
- Monitor error rates and timeout behavior

### Phase 6: Cleanup and Analysis (5 minutes)

- Gradually reduce load to zero
- Document peak metrics
- Export metrics/dashboards for analysis

## Prerequisites

### AWS Account Requirements

- IAM user with EC2, VPC, and Security Group permissions
- VPC with appropriate CIDR blocks (e.g., 10.0.0.0/16)
- At least 4 elastic IPs or public subnet access

### Local Requirements

- AWS CLI configured with appropriate credentials
- SSH client installed
- Terraform or CloudFormation (optional, for IaC)
- Basic knowledge of AWS, Linux, and networking

### Instance Requirements

- Ubuntu 22.04 LTS or Amazon Linux 2 AMI
- Minimum 2 vCPU, 4GB RAM per instance (except t3.small for monitor)
- 20GB EBS root volume

## Step-by-Step Setup Guide

### Step 1: Deploy AWS Infrastructure with Terraform

**Description**: Create foundational AWS infrastructure using the default VPC and deploy all 4 EC2 instances.

**What this step does**:

1. **Uses the default VPC** for your AWS account
2. **Selects the first available subnet** from the default VPC
3. **Creates 4 Security Groups** with proper ingress/egress rules:
   - Web Server SG: Allows SSH (from your IP), Flask API (5000 from Load Gen), Metrics (8000, 9100 from Monitor)
   - DB Server SG: Allows SSH (from your IP), MySQL (3306 from Web Server), Exporters (9100, 9104 from Monitor)
   - Monitor Server SG: Allows SSH (from your IP), Prometheus (9090 from your IP), Grafana (3000 from your IP)
   - Load Gen Server SG: Allows SSH (from your IP), Locust (8089 from your IP)

4. **Launches 4 EC2 Instances** in the selected subnet with public IP assignment:
   - **Web Server** (t3.medium): Ubuntu 22.04 LTS - Flask application host
   - **DB Server** (t3.medium): Ubuntu 22.04 LTS - MySQL database host
   - **Monitor Server** (t3.small): Ubuntu 22.04 LTS - Prometheus & Grafana host
   - **Load Gen Server** (t3.medium): Ubuntu 22.04 LTS - Locust load testing host

5. **Configures networking**:
   - All instances in the same subnet for direct connectivity
   - Public IPs automatically assigned for external access
   - Security groups enforce least-privilege access

**Terraform Files Location**: `/terraform/`

**Files Included**:

- `variables.tf` - Input variable definitions
- `main.tf` - Infrastructure code (VPC, Security Groups, EC2 Instances)
- `outputs.tf` - Connection information and resource IDs
- `terraform.tfvars` - Default configuration values
- `README.md` - Detailed Terraform setup instructions

**How to Proceed**:

1. Navigate to the terraform directory:

   ```bash
   cd terraform
   ```

2. Update `terraform.tfvars` with your IP address:

   ```hcl
   your_ip = "203.0.113.0/32"  # Replace with your actual IP
   ```

3. Review the infrastructure:

   ```bash
   terraform init
   terraform plan
   ```

4. Deploy the infrastructure:

   ```bash
   terraform apply
   ```

5. Retrieve connection information:
   ```bash
   terraform output ssh_commands
   terraform output access_urls
   ```

See `terraform/README.md` for detailed instructions, troubleshooting, and advanced configurations.

### Step 2: Setup Web Server (Flask App)

**Description**: Configure the Flask-based API server with Prometheus metrics collection.

**What this step does**:

1. Installs Python 3, pip, and virtual environment tools
2. Creates and activates a Python virtual environment
3. Installs required dependencies: Flask, Prometheus client, and PyMySQL
4. Deploys Flask application with two APIs:
   - GET `/api/order/<order_id>` - Query orders from database
   - POST `/api/order` - Create new orders with items
5. Exposes Prometheus metrics endpoint at `/metrics`
6. Implements HTTP request counting, duration histograms, and custom metrics
7. Configures systemd service for automatic Flask app startup
8. Sets environment variables for database connectivity

**Source layout**: The Flask app source lives under `src/` at the repo root (`src/app.py`, `src/requirements.txt`, `src/order-api.service`). Terraform injects these into the web server via `user_data`.

**Ask me**: "Generate Terraform and shell scripts for Step 2 to setup Web Server"

### Step 3: Setup MySQL Server

**Description**: Configure the MySQL database server with schema, data, and monitoring exporters.

**What this step does**:

1. Installs MySQL Server 8.0 and enables the service
2. Creates `orders_db` database and three tables:
   - `customer` table with customer information
   - `orders` table with order details
   - `order_items` table with individual items per order
3. Creates foreign key relationships and performance indexes on key columns
4. Creates database user `app_user` with appropriate permissions for the Flask app
5. Seeds initial test data (sample customers, orders, and items)
6. Installs and configures `mysqld_exporter` for Prometheus metrics collection
7. Creates exporter user with minimal privileges for security
8. Installs and configures `node_exporter` for system-level metrics (CPU, memory, disk, network)
9. Enables both exporters as systemd services

**Source layout**: Database schema and seed data live under `db/` at the repo root (`db/schema.sql`, `db/seed.sql`). Terraform injects these into the DB server via `user_data`.

**Ask me**: "Generate Terraform and shell scripts for Step 3 to setup MySQL Server"

### Step 4: Setup Monitor Server (Prometheus & Grafana)

**Description**: Deploy Prometheus time-series database and Grafana visualization platform for centralized monitoring.

**What this step does**:

1. Installs Prometheus with proper user permissions and directory structure
2. Configures Prometheus to scrape metrics from:
   - Web Server on port 8000 (Flask app metrics) and port 9100 (node_exporter)
   - DB Server on port 9104 (mysqld_exporter) and port 9100 (node_exporter)
   - Prometheus itself on port 9090
3. Sets up Prometheus systemd service with 15-second scrape intervals
4. Installs Grafana server and enables auto-start
5. Configures Prometheus as Grafana's primary data source
6. Sets up 3 main Grafana dashboards:
   - **Infrastructure Dashboard**: CPU, network I/O, memory, disk I/O metrics
   - **Application Performance Dashboard**: Response times, latency distribution, request rates, error rates
   - **Database Dashboard**: Connection counts, query performance, table statistics
7. Ensures Prometheus and Grafana services start automatically on reboot

**Ask me**: "Generate Terraform and shell scripts for Step 4 to setup Monitor Server"

### Step 5: Setup Load Generation Server

**Description**: Configure load generation server with Locust for simulating different traffic patterns.

**What this step does**:

1. Installs Python 3, pip, and stress-ng tools
2. Installs Locust framework for distributed load testing
3. Creates Locust test file with balanced read/write operations:
   - Read tasks: Query existing orders via GET `/api/order/<order_id>`
   - Write tasks: Create new orders with items via POST `/api/order`
   - Both operations use random data to simulate realistic behavior
4. Configures wait times between requests (1-3 seconds) to simulate user think time
5. Prepares server for different load scenarios (normal, read-heavy, write-heavy, stressed)

**Ask me**: "Generate Terraform and shell scripts for Step 5 to setup Load Generation Server"

### Step 6: Configure Grafana Dashboards

**Description**: Set up visualization dashboards in Grafana to monitor system and application metrics.

**What this step does**:

1. Adds Prometheus as a data source to Grafana
2. Creates **Infrastructure Dashboard** showing:
   - CPU utilization for Web and DB servers
   - Network I/O throughput
   - Memory and disk usage
   - Real-time system health metrics

3. Creates **Application Performance Dashboard** showing:
   - 95th percentile response time for read API
   - Response time distribution as a heatmap
   - HTTP request rate per second
   - Error rate percentage

4. Creates **Database Dashboard** showing:
   - Active database connections
   - Query execution time
   - Table-level statistics
   - InnoDB buffer pool efficiency

5. Configures appropriate refresh intervals and time ranges for real-time monitoring
6. Sets up alert thresholds for key metrics (optional)

**Ask me**: "Generate Terraform and shell scripts for Step 6 to configure Grafana Dashboards"

## Testing Procedures

### Pre-Test Verification

1. **Verify all services are running**:

```bash
# From web server
curl http://localhost:5000/health

# From db server
mysql -u root -p orders_db -e "SELECT COUNT(*) FROM orders;"
mysqld_exporter —check

# From monitor server
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
```

2. **Verify connectivity**:

```bash
# From web server to DB
nc -zv db-server-private-ip 3306

# From monitor to web/db servers
nc -zv web-server-private-ip 9100
nc -zv db-server-private-ip 9100
nc -zv db-server-private-ip 9104
```

3. **Verify data in database**:

```bash
# From web server
python3 << 'EOF'
import pymysql
conn = pymysql.connect(host='db-server-private-ip', user='app_user', password='app_password', database='orders_db')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM orders')
count = cursor.fetchone()
print(f"Orders in database: {count[0]}")
conn.close()
EOF
```

### Test Scenario 1: Normal Load (5 minutes)

Start from load gen server:

```bash
locust -f locustfile.py -H http://web-server-public-ip:5000 --headless -u 10 -r 2 -t 5m
```

Monitor on Grafana:

- Target CPU utilization: 10-20%
- Response times: 50-150ms
- Request rate: ~20 req/sec
- Error rate: <0.1%

### Test Scenario 2: High Read Load (5 minutes)

Create modified locustfile for read-heavy workload (90% read, 10% write):

```bash
locust -f locustfile_read_heavy.py -H http://web-server-public-ip:5000 --headless -u 50 -r 5 -t 5m
```

Monitor on Grafana:

- Web server CPU: 40-60%
- DB server CPU: 30-50%
- 95th percentile response time: <300ms
- Request rate: ~100 req/sec

### Test Scenario 3: High Write Load (5 minutes)

```bash
locust -f locustfile_write_heavy.py -H http://web-server-public-ip:5000 --headless -u 30 -r 3 -t 5m
```

Monitor:

- DB write operations increasing
- Disk I/O on DB server: 50-80 Mbps
- Memory usage increasing (order items buffering)
- Response times: 100-500ms

### Test Scenario 4: Database CPU Stress (10 minutes)

Start load test:

```bash
locust -f locustfile.py -H http://web-server-public-ip:5000 --headless -u 40 -r 4 -t 10m &
```

In separate session on DB server, apply stress:

```bash
sudo stress-ng --cpu 2 --cpu-load 0.8 --timeout 10m
```

Monitor:

- DB CPU usage: 80-100%
- Response times degrading: 300-1000ms
- Request queuing visible
- Error rate increasing if load too high
- Graceful degradation verification

### Validation Checklist

After each scenario:

- [ ] No error rate spikes above 5%
- [ ] Response times within acceptable bounds
- [ ] Database maintains consistency (check row counts)
- [ ] No resource exhaustion (CPU <95%, Memory <90%)
- [ ] Prometheus collecting metrics (check `/api/v1/targets`)
- [ ] Grafana dashboards updating in real-time

## Cleanup

### Remove Load Test

```bash
# On load gen server
sudo systemctl stop stress-ng
pkill -f locust
```

### Shutdown Services

```bash
# On each server
sudo systemctl stop flask-app      # Web server
sudo systemctl stop mysqld_exporter # DB server
sudo systemctl stop mysqld         # DB server
sudo systemctl stop prometheus     # Monitor server
sudo systemctl stop grafana-server # Monitor server
```

### Terminate AWS Resources

```bash
# Terminate instances
aws ec2 terminate-instances --instance-ids i-xxxxx i-xxxxx i-xxxxx i-xxxxx

# Delete security groups
aws ec2 delete-security-group --group-id sg-xxxxx

# Delete VPC
aws ec2 delete-vpc --vpc-id vpc-xxxxx
```

### Cost Analysis

- 4 x t3.medium instances: ~$0.104/hour
- 1 x t3.small instance: ~$0.052/hour
- Total: ~$0.468/hour
- 8-hour demo cost: ~$3.74

## Troubleshooting

### Flask App Not Starting

```bash
# Check logs
sudo journalctl -u flask-app -n 50

# Test database connection
python3 -c "import pymysql; pymysql.connect(host='db-ip', user='app_user', password='app_password', database='orders_db')"
```

### Prometheus Not Scraping Metrics

```bash
# Check targets
curl http://localhost:9090/api/v1/targets

# Check if exporters are running
curl http://web-server-private-ip:8000/metrics
curl http://db-server-private-ip:9104/metrics
```

### Grafana Not Showing Data

```bash
# Verify data source connection
curl http://localhost:3000/api/datasources

# Check Prometheus for data
curl 'http://localhost:9090/api/v1/query?query=up'
```

### High Latency During Load Test

- Check if DB indexes are created
- Monitor DB connection pool (max_connections)
- Check network bandwidth between servers
- Verify no other processes consuming resources

## Recommendations for Production

1. **High Availability**: Deploy in multi-AZ with RDS for database
2. **Scalability**: Use Auto Scaling Groups and load balancers
3. **Security**: Enable encryption, use private subnets, VPN for access
4. **Persistent Storage**: Use EBS volumes with snapshots
5. **Backup**: Regular database backups and disaster recovery testing
6. **Monitoring**: Setup alerting rules and escalation policies
7. **Logging**: Centralized logging with CloudWatch or ELK stack
8. **Performance**: Enable query caching, optimize slow queries

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Locust Load Testing](https://locust.io/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)

## License

MIT License - Feel free to modify and distribute

## Support

For issues or questions, please open an issue on this repository.
>>>>>>> baccbd4 (Initial commit)
