# Online Code Compiler App

A cross-platform code compilation application built with **Flutter**, powered by a self-hosted **Flask and Docker backend**. 

This app allows you to run code in 8 different programming languages instantly, without needing to install any language binaries, compilers, or interpreters on your local system.

---

## Key Features

*   **Multi-Language Execution:** Full execution support for:
    - C
    - C++
    - Java
    - Python
    - Rust
    - Ruby
    - JavaScript (Node.js)
    - Julia.
*   **Secure Code Sandbox:** Every execution spins up an isolated, temporary Docker container with restricted CPU, RAM, and zero network access. The container is destroyed immediately after execution.
*   **Basic Code Suggestions:** Syntax-guided editing powered by `flutter_code_editor` and highlight themes.
*   **Adaptive UI:** Tailored layout optimizations for desktop environments (side-by-side editor/console) and mobile screens (stacked editor/console).

---

## Architecture

```
                    ┌─────────────────────────┐
                    │       Flutter App       │
                    │ (Windows, Mobile, Web)  │
                    └────────────┬────────────┘
                                 │
                            HTTP POST /compile
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │      Flask Backend      │
                    │   (compiler-backend)    │
                    └────────────┬────────────┘
                                 │
                    Spawns disposable Docker container
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │  Isolated Runtime Env   │
                    │ (compiler-python, etc.) │
                    └─────────────────────────┘
```

---


## Setting Up Custom Backend

By default, the Flutter application is configured to run against the production endpoint: `https://compiler.arilak.live/compile`. 

If you want to host your own backend instance on your local machine or a homelab server, follow this guide:

### 1. Launch Your Local Backend
Clone [`compiler_backend`](https://github.com/lakshya076/compiler_backend) repository.

```bash
cd backend

# Build the main server & compile all runners
docker compose build api
docker compose --profile build-only build

# Start the API gateway
docker compose up -d api
```
*For detailed setup details, consult the backend repo [`README.md`](https://github.com/lakshya076/compiler_backend#code-compiler--backend).*

### 2. Point Flutter to Your Custom Backend
To direct your Flutter application to your new backend server, modify the global backend URL:

1. Open `lib/Screens/compiler.dart`
2. Locate and replace the backendUrl from:
   ```dart
   const String backendUrl = 'https://compiler.arilak.live/compile';
   ```
   to
   
   ```dart
   const String backendUrl = 'http://<YOUR-SERVER-IP>:5000/compile';
   ```
   *Note: For testing locally on the same machine running the Flutter app, use `http://localhost:5000/compile`.* 
   
   > Note: [ngrok](https://ngrok.com/) can be used to create a public URL for your local server.

---

## Running the Flutter Client Locally

Ensure you have the Flutter SDK installed (`^3.7.2`).

### 1. Get Dependencies
```bash
flutter pub get
```

### 2. Run the App
Launch the compiler app on your connected device or emulator:
```bash
flutter run
```

---

## Security Sandbox Profile
For safety, each container execution utilizes strict constraints:
*   `--network none` - Zero internet access within runtimes.
*   `--memory 128m` - Maximum 128 MB RAM.
*   `--cpus 0.5` - Maximum 0.5 CPU core availability.
*   `--pids-limit 64` - Mitigates fork bombs.
*   `read-only mount` - Code files are mounted read-only (`ro`) to prevent runner filesystem persistence.
