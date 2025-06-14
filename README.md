# 💰 Personal Finance Manager App

A work-in-progress cross-platform mobile application built with **Flutter** and **Firebase**, designed to help users track income, expenses, and savings. The goal is to provide users with a clean interface and meaningful insights into their financial habits.

---

## 🚧 Project Status

This project is currently under active development. Several core features and screens have already been implemented.

---

## 🛠 Tech Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Provider (State Management)
- fl_chart (for future data visualizations)
- Intl (Date formatting)

---

## 📱 Screens

1. **Splash Screen**  
   - Initial loading screen *(if implemented)*

2. **AuthWrapper**  
   - Routes user to login or home based on auth state

3. **Login Screen**  
   - Sign in using email and password

4. **Signup Screen**  
   - User registration with Firebase auth

5. **Home Screen**  
   - Displays balance, income & expenses summary  
   - Quick access to add transaction, view reports

6. **Reports Screen**  
   - Monthly financial summary  
   - Bar chart for income vs expense  
   - Transaction list by month/year

7. **Add Transaction Screen** *(Planned)*  
   - To add new income or expense entries

---

## 🧩 Planned Features

- Category filtering and budgeting
- Dashboard insights and visualizations
- Notifications/reminders
- Export as PDF/Excel
- Dark mode toggle

---

## 🚀 Getting Started

```bash
git clone https://github.com/AishaAli1543/Personal-finance-Manager.git
cd Personal-finance-Manager
flutter pub get
flutter run
