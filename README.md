# 🚑 Ambulance Ordering and Tracking App

A Flutter-based mobile application designed to simplify the process of booking and tracking ambulances for non-emergency medical transportation. This project connects patients with nearby ambulance drivers in real-time, offering live location tracking, driver-user communication, and efficient dispatch management.

---

## 📱 Features

- User and Driver authentication using Firebase Authentication
- Location selection using Google Maps API (current or custom location)
- Real-time nearby ambulance discovery based on user location
- Ambulance booking and driver request notifications via Firebase Cloud Messaging (FCM)
- Driver-side Active/Inactive status management
- Live ambulance tracking on user side with driver details and distance updates
- Driver acceptance/rejection flow for incoming service requests
- Journey completion workflow
- Admin functionality for user and driver management (optional)

---

## 🛠️ Technologies Used

- **Flutter (Dart)**
- **Firebase Authentication**
- **Firebase Realtime Database**
- **Firebase Cloud Messaging (FCM)**
- **Google Maps API**
- **Geolocator**
- **URL Launcher (for driver contact call)**
- **.env (dotenv) for API key security**

---

## 📍 App Workflow Overview

1. **User Flow:**
   - Sign Up / Login
   - Select pickup location
   - View nearby ambulances
   - Send request to a selected driver
   - Track ambulance after acceptance
   - Contact driver if needed
   - Complete journey flow

2. **Driver Flow:**
   - Login
   - Set Active / Inactive status
   - Receive incoming ambulance requests
   - Accept / Reject user requests
   - Navigate to user's location
   - End journey after drop-off

---

## 📸 Screenshots

<p float="left">
  <img src="https://github.com/user-attachments/assets/ade0c193-c6ec-43f3-bce1-e8eb6783df20" width="16%" />
  <img src="https://github.com/user-attachments/assets/72b1822b-225c-44bd-8e41-4afe461fd719" width="16%" />
  <img src="https://github.com/user-attachments/assets/8d178c53-a619-469e-ab7f-d2a8f9dc1f17" width="16%" />
  <img src="https://github.com/user-attachments/assets/a8011896-be77-4d81-bb3d-6d87105c6d0e" width="16%" />
  <img src="https://github.com/user-attachments/assets/79e6039f-4835-4a33-bf55-3b44a679a5ce" width="16%" />
  <img src="https://github.com/user-attachments/assets/897575a1-d232-488f-8213-bd840d806e43" width="16%" />
  
  
</p>

<p float="left">
  <img src="https://github.com/user-attachments/assets/13de4f8d-8ce6-48a1-b9f0-f9dfb8f4b14a" width="16%" />
  <img src="https://github.com/user-attachments/assets/e1b4bfac-c256-4d62-80cd-0021624e0fe4" width="16%" />
  <img src="https://github.com/user-attachments/assets/27064df1-ecc3-4269-b45c-37a6e3d6ab0a" width="16%" />
  <img src="https://github.com/user-attachments/assets/7e9cef90-5f43-45f5-95b1-1baefd38307c" width="16%" />
  <img src="https://github.com/user-attachments/assets/94201343-f59e-4512-834c-c8c4d8b5c6bd" width="16%" />
  <img src="https://github.com/user-attachments/assets/3c661b42-3854-471d-ba38-12ef345ed8bd" width="16%" />
</p>

<p float="left">
  <img src="https://github.com/user-attachments/assets/031d31db-77d0-4f17-a02b-edf61e70b64a" width="16%" />
  <img src="https://github.com/user-attachments/assets/3955527f-5a68-4d59-acf9-5e56d11ef449" width="16%" />
  <img src="https://github.com/user-attachments/assets/a4f594de-2959-405a-a7ba-0b2d58ab0934" width="16%" />
  <img src="https://github.com/user-attachments/assets/0d301b4c-61f2-4584-8de3-1236ac6af53a" width="16%" />
  <img src="https://github.com/user-attachments/assets/ddf512a1-9b5d-42a5-b061-e4d17528b9fb" width="16%" />
  <img src="https://github.com/user-attachments/assets/9bf57f94-7fa8-4cb1-af72-a66c65192991" width="16%" />
</p>

## 👨‍💻 Authors

- **Alfred Antony**
- **Anabel George**
- **Fabiya Philomina M J**

---
