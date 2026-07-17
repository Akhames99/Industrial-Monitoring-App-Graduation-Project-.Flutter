# Industrial Monitoring App

A real-time, AI-powered industrial monitoring and automation mobile application built using **Flutter**. This system provides comprehensive quality control analytics, conveyor line hardware control, sensor health tracking, and team access management for an automated bottling production line.

---

## 📱 App Preview

Here is a look at the core interfaces of the application.

*NOTE: The images below are placeholders. You need to replace the image paths in the README with your actual screenshot files (e.g., `assets/screenshots/my_dashboard.jpeg`).*

| **1. Primary Dashboard** | **2. Hardware & Session Control** |
| :---: | :---: |
| Overview of production yield (Good/Defected/Invalid), live system state (Running/Stopped), and defection categorization. | Remote start/stop control, real-time line speed telemetry, and active current load monitoring (A). |
| ![Production Dashboard Preview](/assets/screenShots/Dashboard.jpeg) | ![Conveyor Line Control](/assets/screenShots/Control.jpeg) |

| **3. Intelligent Quality Log** | **4. Analytics & Sensor Telemetry** |
| :---: | :---: |
| Review live image captures of the bottling line, check AI inference confidence (e.g., 50%), and manually confirm or relabel logs. | Deep dive into hourly defect metrics, historical AI confidence tracking, and live sensor health diagnostics for cameras, speed, and temperature. |
| ![Live Quality Log Feed](/assets/screenShots/Qualitylog.jpeg) | ![Industrial Analytics Dashboard](/assets/screenShots/Analytics.jpeg) |

| **5. Team Management (RBAC)** | **6. User Profile & Security** |
| :---: | :---: |
| Manage roles for the production team, distinguishing between Admin (like `akhames99`), Operator (like `Helal`), and Viewer roles. | User dashboard for profile management, secure username updates, password change interfaces, and session logout. |
| ![Role Management Screen](/assets/screenShots/Settings.jpeg) | ![Profile Settings and Security](/assets/screenShots/Settingstwo.jpeg) |

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

## ⚙️ Getting Started

### Prerequisites
Make sure your development machine has the Flutter SDK correctly configured.
* Flutter SDK version: `>=3.0.0`
* Dart SDK version: `>=3.0.0`

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YourUsername/Industrial-Monitoring-App-Graduation-Project-.Flutter.git](https://github.com/YourUsername/Industrial-Monitoring-App-Graduation-Project-.Flutter.git)
   cd Industrial-Monitoring-App-Graduation-Project-.Flutter
