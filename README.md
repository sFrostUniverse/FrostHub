
# FrostHub

FrostHub is a **student collaboration and study app** designed to help learners connect, ask doubts, join groups, and access a personalized dashboard. It streamlines study group management and makes learning more interactive and efficient.

---

## Features

- **Google Sign-In Authentication** – secure and fast login.
- **Group Management** – join existing study groups or create new ones.
- **Doubt Posting** – ask questions and attach images to get answers from your group.
- **Personalized Dashboard** – access relevant information and updates based on your group and activity.
- **Animated Splash Screen** – smooth fade + slide animation with app logo and MIT license claim.
- **Cross-Platform** – runs on Android and iOS using Flutter.

---

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: FrostCore API
- **Local Storage**: SharedPreferences (for token persistence)
- **Authentication**: Google Sign-In
- **Image Uploads**: Handled via multipart requests

---

## Installation

### Prerequisites

- Flutter 3.0+  
- Dart SDK  
- Node.js (optional, for local FrostCore backend testing)  
- A connected device or emulator

### Steps

1. Clone the repository:

```bash
git clone https://github.com/yourusername/frosthub.git
cd frosthub
```

2. Install dependencies:

```bash
flutter pub get
```

3. Add required assets:

- Place your app logo at `assets/images/logo.png`  
- Ensure it is listed in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/logo.png
```

4. Run the app:

```bash
flutter run
```

---

## Project Structure

```
frosthub/
│
├─ lib/
│   ├─ api/                 # FrostCore API calls
│   ├─ features/
│   │   ├─ auth/            # Authentication screens
│   │   ├─ group/           # Group management screens
│   │   └─ main/            # Dashboard and main screens
│   └─ main.dart
│
├─ assets/                  # Images and other static files
├─ pubspec.yaml             # Flutter configuration
└─ README.md
```

---

## Usage

- Open the app → Splash screen appears with logo and MIT license claim.  
- Login via Google Sign-In.  
- If you haven’t joined a group, select or create a study group.  
- Access the dashboard to see updates and post doubts.  
- Post doubts with optional images and answer questions from group members.  

---

## License

This project is licensed under the **MIT License**.  
© 2025 FrostHub

See [LICENSE](LICENSE) for full license details.

---

## Contact

**Frost**  
Email: your-email@example.com  
Website: [https://frosthub.com](https://frosthub.com)
