# MedRhythms Project

## 🧠 Overview

The **MedRhythms Project** is a cross-platform mobile application designed to support sensor-based music therapy for neurological rehabilitation. Built in collaboration with MedRhythms and developed as part of a Northeastern University course, this project integrates real-time step tracking, user session monitoring, and dynamic music playback via the Spotify SDK to provide personalized therapy sessions. It leverages mobile sensors and health APIs to analyze user movement and provide actionable insights.

---

## 🚀 Features

- 🎵 **Music-Driven Therapy**: Syncs music playback to user steps using Spotify SDK.
- 🦶 **Step Detection**: Uses Google Health API for accurate step tracking.
- 📊 **Session Management**: Tracks workout sessions, stores and syncs data to the cloud.
- 🌐 **Firebase Integration**: Utilizes Firestore for secure, real-time cloud storage.
- 💾 **Local + Cloud Sync**: Ensures data integrity even when offline.
- 🔒 **Privacy Focused**: Stores no personally identifiable information (PII).
- 🛠️ **Cross-Platform Ready**: Built using Flutter for Android and iOS support.

---

## 🧱 Architecture

### Frontend
- **Flutter** (Dart)
- **Real-time UI updates** for step tracking and playback controls

### Backend
- **Firebase Functions** (Node.js / Typescript)
- **Google Cloud Firestore** for session data
- **Scheduled Functions** for daily backups and session packaging
- **Spotify Web API** for controlling playback and fetching user track data

### Sensor & API Integration
- **Google Fit / Apple HealthKit** (Platform-specific step data)
- **Device IMEI** (For anonymous user tracking)
- **Session Tracker**: Custom logic to handle passive and active sessions

---

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (`>=3.0.0`)
- Android Studio or Xcode (depending on platform)
- Firebase Project
- Spotify Developer Account (for API access)

### 1. Clone the Repository
```bash
git clone (https://github.com/Srinivas142000/DT-MedRhythm.git)
cd medrhythms-project
```

Development Code Branch: DEV
QA Tests Branch : QA
Documentation : main


Class Diagram:

![Class Diagram](https://github.com/Srinivas142000/DT-MedRhythm/blob/classdiagram/medrhythms_dcdg.svg?raw=true)
