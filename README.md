# Industrial Monitoring App

A real-time, AI-powered industrial monitoring and automation mobile application built using **Flutter**. This system provides comprehensive quality control analytics, conveyor line hardware control, sensor health tracking, and team access management for an automated bottling production line.

---

## 🚀 Key Features

### 1. Real-Time Production Dashboard
* **Production Yield Tracking:** Live monitoring of manufacturing outputs categorized by product state (**Good**, **Defected**, and **Invalid**).
* **Defection Categorization:** Granular defect classification utilizing computer vision targeting specific issues:
  * `No_cap`
  * `Crooked_cap`
  * `Empty_bottle`
  * `No_label`
* **Active Alerts System:** Instant visual safety status indicators ("System Operates Normally" or triggered error flags).

### 2. Intelligent Quality Logs & Human-in-the-Loop
* **Real-Time Inspection Feed:** Logs every individual item evaluated by the inspection camera (`CAM_01`).
* **AI Inference Audit:** Displays confidence scoring percentages for classifications.
* **Verification Workflow:** Operators and Admins can interact directly with the data feed to **Confirm**, **Relabel**, or **Edit** logs to correct anomaly detection records.

### 3. Advanced Industrial Analytics
* **Hourly Defect Metrics:** Time-series charts mapping out peak error windows during production shifts.
* **AI Confidence Metrics:** Aggregate statistical dashboards tracking confidence patterns across 7, 14, and 30-day timeframes to gauge model stability over time.

### 4. Telemetry & Sensor Integration
Live status switches and threshold range alerts for essential manufacturing hardware:
* **Visual Feed:** Camera peripherals (`CAM_01`).
* **Conveyor Dynamics:** Speed tracking (M/S).
* **Thermals:** Machine and environmental temperature diagnostics (°C).
* **Mechanical Stress:** Vibration analysis telemetry indicators (`Vib_01`).

### 5. Hardware Session Control
* **Session Management:** Remote control actions to safely **Start** or **Stop** production lines directly from the app.
* **Line Speed Throttle:** Precision adjustments through a Target Speed UI slider (0% to 100%).
* **Electrical Diagnostics:** Active current monitoring displaying electrical loads measured in Amperes (A).

### 6. Team & Security Protocols
* **Role-Based Access Control (RBAC):** Tiered operational profiles managing specific privileges:
  * `Admin` — Full configuration, verification overrides, and team additions.
  * `Operator` — Controls active sessions and line throughput.
  * `Viewer` — Read-only observation profiles.
* **Security Management:** Secure authentication gateways including interactive password modifications, profile updating, and explicit session timeouts.

---

## 🛠️ Tech Stack

* **Frontend Framework:** Flutter & Dart
* **Relational Database (Users, Roles, Logs):** PostgreSQL
* **Time-Series Database (Sensor Telemetry & Metrics):** InfluxDB

---
