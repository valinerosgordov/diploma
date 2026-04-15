# File Analysis Tool

Cross-platform Flutter application for intelligent file analysis using on-device machine learning. Classifies files, detects duplicates, scans for sensitive data, assesses security threats, and generates detailed reports in PDF/Excel.

## Features

### ML-Powered File Analysis
- **Photo Classification** — categorizes images (documents, faces, nature) using Google ML Kit Image Labeling
- **Content Classification** — determines file content type (source code, documentation, configuration, data) via text analysis with confidence scoring
- **Auto-Tagging** — generates semantic tags for images with confidence percentages
- **Duplicate Detection** — finds exact binary matches (SHA-256) and content-similar files (Levenshtein / trigram similarity)

### Security Analysis
- **Sensitive Data Detection** — scans text files for 8 types of sensitive information:
  - Email addresses, phone numbers, credit card numbers
  - IP addresses, API keys, passwords in configs
  - Private keys (PEM format), JWT tokens
  - Values are masked in output (e.g., `us***@domain.com`, `****-****-****-1234`)
  - False positive filtering (loopback IPs, example emails)
- **Threat Assessment** — evaluates each file against 7 risk criteria:
  - Executable files (exe, bat, msi) — High risk
  - Suspicious double extensions (report.pdf.exe) — Critical risk
  - Script files (sh, py, js) — Medium risk
  - Hidden files, suspicious filename keywords (crack, exploit, trojan)
  - Large binary files (>100 MB)
  - Aggregated risk score 0-100 with 5 threat levels (Safe, Low, Medium, High, Critical)

### Report Generation
- **PDF reports** — paginated, chunked generation with sections for all analysis types + security findings
- **Excel reports** — multi-sheet workbook (Summary, File Analysis, Security, Performance)
- **Report history** — save, open, share, delete previous reports
- **Threat level** — real aggregated assessment in report header

### UI
- Dark theme (#0D0D14 background, #E94F4F accent)
- Interactive pie chart for file type distribution
- Expandable file cards with analysis details and security indicators
- Search and filter by filename
- Configurable file type mappings
- Progress tracking during analysis
- Warning system with UI notifications

---

## Installation & Setup

### Step 1 — Install Flutter SDK

**Windows:**
1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows/mobile
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to system PATH:
   - Win+R -> `sysdm.cpl` -> Advanced -> Environment Variables
   - Edit `Path` in System variables -> Add `C:\flutter\bin`
4. Restart terminal

**macOS:**
```bash
brew install flutter
```

**Linux:**
```bash
sudo snap install flutter --classic
```

Verify installation:
```bash
flutter --version
```

### Step 2 — Install Android SDK

**Option A — Android Studio (recommended):**
1. Download from https://developer.android.com/studio
2. Run installer, check "Android SDK" during setup
3. Open Android Studio -> Settings -> SDK Manager
4. Install Android SDK 34 (or latest)
5. Install Android SDK Build-Tools, Android SDK Platform-Tools

**Option B — Command-line only:**
```bash
# Download command-line tools from https://developer.android.com/studio#command-line-tools-only
# Set ANDROID_HOME environment variable
# Then:
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### Step 3 — Accept Android licenses

```bash
flutter doctor --android-licenses
```
Accept all licenses with `y`.

### Step 4 — Verify everything

```bash
flutter doctor
```

Expected output — all green checkmarks:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
[✓] VS Code / Connected device
```

Warnings about Chrome/Linux/macOS/Windows toolchains are fine if you only target Android.

### Step 5 — Clone and run

```bash
# Clone
git clone https://github.com/valinerosgordov/diploma.git
cd diploma

# Install dependencies
flutter pub get

# Connect a device or start an emulator, then:
flutter run
```

---

## Running the App

### On a physical Android device
1. Enable Developer Options on the phone (Settings -> About -> tap Build Number 7 times)
2. Enable USB Debugging in Developer Options
3. Connect phone via USB, allow debugging when prompted
4. Run:
```bash
flutter run
```

### On Android Emulator
1. Open Android Studio -> Device Manager -> Create Device
2. Select a device (e.g., Pixel 7), download a system image (API 34)
3. Start the emulator
4. Run:
```bash
flutter run
```

### Build APK for distribution
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

APK will be at `build/app/outputs/flutter-apk/app-release.apk`

---

## How to Use

1. **Open the app** — you see the main screen with stats cards (0 files, 0 MB)
2. **Tap "Analyze Directory"** (floating button) — select files from your device
3. **Wait for analysis** — progress bar shows file count, ML processing runs on each file
4. **Review results:**
   - Pie chart shows file type distribution
   - Expand file groups to see individual files
   - Expand a file to see:
     - Photo classification (for images)
     - Content classification (for documents/text)
     - Duplicate detection status
     - Auto-generated tags (for images)
     - Sensitive data findings (emails, passwords, API keys found)
     - Threat assessment (risk score, findings)
5. **Generate report** — tap the download icon in the header
   - Choose Excel or PDF format
   - Tap "Export" — report saves to Downloads
   - Share via any app or view in report history
6. **Settings** — tap the gear icon to edit file type mappings (add/remove extensions)
7. **History** — tap the clock icon to view/open/delete previous reports

---

## Architecture

```
lib/
  main.dart                              # Entry point, Provider setup, theme
  models/
    app_colors.dart                      # Dark theme color palette
    file_type_mappings.dart              # File extension -> type mappings
    report_data.dart                     # Typed models (ReportData, FileAnalysisResult)
    report_history.dart                  # Report history model
  providers/
    file_analysis_provider.dart          # ChangeNotifier — state management
  services/
    photo_classifier_service.dart        # ML Kit image labeling
    file_content_classifier_service.dart # Text extraction + content classification
    auto_tagging_service.dart            # ML Kit auto-tagging
    duplicate_detection_service.dart     # SHA-256 hashing + similarity
    sensitive_data_service.dart          # Regex-based sensitive data scanning
    threat_assessment_service.dart       # File threat evaluation
    report_history_service.dart          # SharedPreferences persistence
  pages/
    home_page.dart                       # Main screen
    report_generation_screen.dart        # PDF/Excel export
    report_history_screen.dart           # Report management
  widgets/
    header_widget.dart                   # App bar with search
    stats_widget.dart                    # File count, size, categories
    distribution_chart.dart              # Pie chart
    file_list_widget.dart                # Grouped file list
    file_type_editor.dart                # Extension editor
    file_type_icon.dart                  # File type icons
    analysis_widgets.dart                # Photo, content, duplicate, tag displays
    security_widgets.dart                # Sensitive data + threat displays
    expanded_button.dart                 # Reusable button
```

**State management:** Provider + ChangeNotifier  
**Typed data flow:** `FileAnalysisResult` -> `ReportData` (no `Map<String, dynamic>`)

## Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.6+, Dart |
| ML | Google ML Kit (Image Labeling, Text Recognition) |
| State | Provider |
| PDF generation | `pdf` package |
| Excel generation | `excel` package |
| PDF text extraction | Syncfusion Flutter PDF |
| Hashing | `crypto` (SHA-256, stream-based) |
| Storage | SharedPreferences |
| File picking | file_picker |
| Charts | pie_chart |

## Tests

```bash
flutter test
```

| Test file | What it covers |
|-----------|---------------|
| `widget_test.dart` | App renders, stats cards, empty state |
| `file_type_mappings_test.dart` | Extension mapping, static methods, case insensitivity |
| `report_data_test.dart` | Model construction, factory, MatchType enum |
| `sensitive_data_test.dart` | All 8 regex patterns, false positive filtering, masking |
| `threat_assessment_test.dart` | Severity ordering, aggregation, threat types |

## Performance Optimizations

- **Stream-based SHA-256** — files hashed via stream, no full file in memory
- **Levenshtein optimization** — single-row algorithm O(min(n,m)) memory, trigram fallback for texts >2000 chars
- **Text comparison cap** — truncated to 10K characters to prevent OOM
- **File limit** — max 200 files per analysis session
- **Chunked PDF** — paginated generation to manage memory
- **Batch processing** — files processed in batches of 3 with UI updates between batches

## Android Permissions

| Permission | Why |
|------------|-----|
| `MANAGE_EXTERNAL_STORAGE` | Save reports to Downloads folder |
| `READ_EXTERNAL_STORAGE` | Access selected files for analysis |
| `INTERNET` | Not used — all ML runs on-device |

## Troubleshooting

**`flutter pub get` fails:**
```bash
flutter clean
flutter pub get
```

**ML Kit crash on emulator:**
Google ML Kit requires Google Play Services. Use a Google APIs emulator image, not a plain AOSP one.

**Permission denied when saving reports:**
On Android 11+, the app requests `MANAGE_EXTERNAL_STORAGE`. If denied, go to Settings -> Apps -> File Analysis Tool -> Permissions -> allow storage access.

**Build fails with Gradle errors:**
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

## License

This project is part of a diploma thesis and is not licensed for commercial use.
