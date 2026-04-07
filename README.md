<div align="center">

<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=40&pause=1000&color=ff79c6&center=true&vCenter=true&width=600&height=60&lines=sddm-ddr-theme" />

<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=16&pause=1000&color=8be9fd&center=true&vCenter=true&width=600&height=30&lines=DDR+rhythm+game+SDDM+login+screen+%7C+Qt6+QML" />

<br>

![](https://img.shields.io/badge/SDDM-Qt6-ff79c6?style=for-the-badge&logo=qt&logoColor=white)
![](https://img.shields.io/badge/Arch-Linux-8be9fd?style=for-the-badge&logo=archlinux&logoColor=white)
![](https://img.shields.io/badge/Wayland-50fa7b?style=for-the-badge&logo=wayland&logoColor=black)
![](https://img.shields.io/badge/license-MIT-ff5555?style=for-the-badge)

<br>

<a href="#installation"><kbd> <br> Installation <br> </kbd></a>&ensp;
<a href="#how-to-play"><kbd> <br> How to Play <br> </kbd></a>&ensp;
<a href="#customization"><kbd> <br> Customization <br> </kbd></a>&ensp;
<a href="#requirements"><kbd> <br> Requirements <br> </kbd></a>

</div>

<br>

https://github.com/user-attachments/assets/e35ab443-79a6-4489-87d6-098b7acb1605

<br>

When you click **Sign in**, a DDR minigame starts. Hit the arrows as they reach the targets to authenticate — your grade is revealed and you're logged in. A **skip** button is always available if you just want to log in instantly.

---

<a id="features"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=ff79c6&vCenter=true&width=435&height=25&lines=FEATURES" width="435"/>

---

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

<div align="right">
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

---

<a id="requirements"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=ff79c6&vCenter=true&width=435&height=25&lines=REQUIREMENTS" width="435"/>

---

- **SDDM** with Qt6 support (`sddm-git` or SDDM ≥ 0.21)
- Qt6 with `QtMultimedia` and `QtQuick.Effects`
- A video file for the background (`.mp4`, `.webm`, etc.)

On Arch / Manjaro:
```bash
sudo pacman -S sddm qt6-multimedia qt6-multimedia-ffmpeg
```

<div align="right">
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

---

<a id="installation"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=ff79c6&vCenter=true&width=435&height=25&lines=INSTALLATION" width="435"/>

---

**1. Clone the repo**
```bash
git clone https://github.com/Timeking23/sddm-ddr-theme.git
```

**2. Copy the theme**
```bash
sudo cp -r sddm-ddr-theme /usr/share/sddm/themes/
```

**3. Set your video background**

Open `/usr/share/sddm/themes/sddm-ddr-theme/Main.qml` and find:
```qml
source: "/path/to/your/background.mp4"   // ← change this to your video file
```
Replace it with the absolute path to your video, e.g.:
```qml
source: "/home/yourname/Videos/background.mp4"
```
> The video plays silently on loop. Any `.mp4` or `.webm` works.
> Free anime wallpaper videos: [moewalls.com](https://moewalls.com)

**4. (Optional) Pre-fill your username**

In the same file, find:
```qml
id: userField; text: ""   // pre-fill with your username if desired
```
Change `""` to your username:
```qml
id: userField; text: "yourname"
```

**5. Apply the theme**

Create or edit `/etc/sddm.conf.d/theme.conf`:
```ini
[Theme]
Current=sddm-ddr-theme
```

**6. Test without rebooting**
```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-ddr-theme
```

<div align="right">
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

---

<a id="how-to-play"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=ff79c6&vCenter=true&width=435&height=25&lines=HOW+TO+PLAY" width="435"/>

---

<div align="center">

| Key | Direction |
|:---:|:---------:|
| `←` or `D` | Left |
| `↓` or `F` | Down |
| `↑` or `J` | Up |
| `→` or `K` | Right |

</div>

Arrows fall from top to bottom. Hit them as they cross the glowing rainbow bar.

<div align="center">

| Timing | Window |
|:------:|:------:|
| **PERFECT** | within ~28px of center |
| **GOOD** | within ~52px |
| **LATE** | within ~72px |
| **MISS** | outside zone |

</div>

**Grades**

<div align="center">

| Grade | Condition |
|:-----:|:---------:|
| **S** | 100% accuracy, zero misses |
| **A** | ≥ 90% |
| **B** | ≥ 75% |
| **C** | ≥ 60% |
| **D** | below 60% |

</div>

After the pattern finishes your grade is shown for ~2 seconds, then you're logged in regardless of score. Click **skip** at any time to bypass the game entirely.

<div align="right">
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

---

<a id="customization"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=ff79c6&vCenter=true&width=435&height=25&lines=CUSTOMIZATION" width="435"/>

---

- **Arrow pattern** — edit `arrowPattern` in `Main.qml`. Each entry is `{dir: 0-3, delay: ms}` where `0=Left 1=Down 2=Up 3=Right` and `delay` is time after the previous arrow.
- **Arrow speed** — change `arrowDuration: 1500` (ms for an arrow to travel the full screen). Higher = slower.
- **BPM** — adjust delays in `arrowPattern`. At 170 BPM: quarter=353ms, 8th=176ms, 16th=88ms.
- **Colors** — `arrowColors` holds the four lane colors (Dracula palette by default).

<div align="right">
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

---

<div align="center">
<sub>MIT license — do whatever you want with it.</sub>
</div>
