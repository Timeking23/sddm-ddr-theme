# sddm-ddr-theme

A DDR / rhythm-game style SDDM login screen built with Qt6 QML.

https://github.com/Timeking23/sddm-ddr-theme/releases/download/v1.0/demo.mp4

When you click **Sign in**, a DDR minigame starts. Hit the arrows as they reach the targets to authenticate — then your grade is revealed and you're logged in. A **skip** button is always available if you just want to log in instantly.

---

## Features

- Animated video background (bring your own `.mp4`)
- DDR minigame with a Touhou-inspired arrow pattern (~170 BPM)
- DFKJ key support (D=Left, F=Down, J=Up, K=Right) + arrow keys
- Timing zones: **PERFECT / GOOD / LATE / MISS**
- Combo counter that scales with your streak
- RGB rainbow spark burst on PERFECT hits
- Expanding ripple ring on every hit
- Hue-cycling rainbow judgment bar with shimmer sweep
- Screen shake on misses
- Confetti + grade reveal (S / A / B / C / D) on finish
- CRT scanlines, lane flash, bloom glow effects
- Glass-morphism login card that slides out when the game starts
- Clock and date display
- Session selector (Wayland / X11)
- Reboot / power off buttons
- Skip button for instant login

---

## Requirements

- **SDDM** with Qt6 support (`sddm-git` or SDDM ≥ 0.21 on most distros)
- Qt 6 with `QtMultimedia` and `QtQuick.Effects` (usually pulled in by `qt6-multimedia`)
- A video file for the background (`.mp4`, `.webm`, etc.)

On Arch / Manjaro:
```bash
sudo pacman -S sddm qt6-multimedia qt6-multimedia-ffmpeg
```

---

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/Timeking23/sddm-ddr-theme.git
```

### 2. Copy the theme

```bash
sudo cp -r sddm-ddr-theme /usr/share/sddm/themes/
```

### 3. Set your video background

Open `/usr/share/sddm/themes/sddm-ddr-theme/Main.qml` and find this line near the top of the file:

```qml
source: "/path/to/your/background.mp4"   // ← change this to your video file
```

Replace the path with the absolute path to your video file, e.g.:

```qml
source: "/home/yourname/Videos/background.mp4"
```

> The video plays silently and loops. Any `.mp4` or `.webm` works.
> Good source for free anime wallpaper videos: [moewalls.com](https://moewalls.com)

### 4. (Optional) Pre-fill your username

In the same file, find:

```qml
id: userField; text: ""   // pre-fill with your username if desired
```

Change `""` to your username:

```qml
id: userField; text: "yourname"
```

### 5. Apply the theme

Create or edit `/etc/sddm.conf.d/theme.conf`:

```ini
[Theme]
Current=sddm-ddr-theme
```

Or use your distro's settings app if it has an SDDM theme picker.

### 6. Test without rebooting

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-ddr-theme
```

---

## How to play

| Key | Direction |
|-----|-----------|
| `←` or `D` | Left |
| `↓` or `F` | Down |
| `↑` or `J` | Up |
| `→` or `K` | Right |

Arrows fall from top to bottom. Hit them as they cross the glowing rainbow bar at the bottom.

| Timing | Window |
|--------|--------|
| PERFECT | within ~28px of center |
| GOOD | within ~52px |
| LATE | within ~72px |
| MISS | outside zone |

### Grades

| Grade | Condition |
|-------|-----------|
| S | 100% accuracy, zero misses |
| A | ≥ 90% |
| B | ≥ 75% |
| C | ≥ 60% |
| D | below 60% |

After the pattern finishes your grade is shown for ~2 seconds, then you're logged in regardless of score. Click **skip** at any time to bypass the game entirely.

---

## Customization tips

- **Arrow pattern** — edit `arrowPattern` in `Main.qml`. Each entry is `{dir: 0-3, delay: ms}` where `0=Left 1=Down 2=Up 3=Right` and `delay` is time after the previous arrow.
- **Arrow speed** — change `arrowDuration: 1500` (milliseconds for an arrow to cross the screen). Higher = slower.
- **BPM** — adjust the delay values in `arrowPattern`. At 170 BPM: quarter=353ms, 8th=176ms, 16th=88ms.
- **Colors** — `arrowColors` holds the four lane colors in Dracula palette by default.

---

## License

MIT — do whatever you want with it.
