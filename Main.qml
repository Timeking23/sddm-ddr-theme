import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 2.15 as QQC2
import QtMultimedia 6.0
import QtQuick.Effects
import QtQuick.Window 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 2880
    height: 1800
    color: "black"

    // Screen shake
    transform: Translate { id: shakeTx; x: 0; y: 0 }
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeTx; property: "x"; to:  8; duration: 40 }
        NumberAnimation { target: shakeTx; property: "x"; to: -8; duration: 40 }
        NumberAnimation { target: shakeTx; property: "x"; to:  5; duration: 35 }
        NumberAnimation { target: shakeTx; property: "x"; to: -5; duration: 35 }
        NumberAnimation { target: shakeTx; property: "x"; to:  0; duration: 30 }
    }

    // ── DDR state ────────────────────────────────────────────────────
    property bool   ddrActive:     false
    property int    ddrHits:       0
    property int    ddrMisses:     0
    property int    ddrCombo:      0
    property int    ddrMaxCombo:   0
    property int    ddrPerfects:   0
    property int    ddrGoods:      0
    property int    ddrNeeded:     14
    property int    ddrMaxMisses:  5
    property bool   ddrDone:       false
    property string ddrFeedback:   ""
    property string ddrGrade:      ""
    property int    ddrAccuracy:   0
    property var    ddrArrows:     []
    property int    arrowDuration: 1500
    property int    patternIndex:  0
    property int    ddrCountdown:  0   // 3,2,1 then 0=GO
    property real   barHue:        0   // cycling 0..1 for rainbow bar

    // Original Touhou-inspired pattern (~170 BPM)
    // quarter=353ms  8th=176ms  dotted8th=265ms  16th=88ms
    // 0=L 1=D 2=U 3=R
    readonly property var arrowPattern: [
        // ── A: intro 8th-note staircase up ──
        {dir: 0, delay: 530}, {dir: 1, delay: 176}, {dir: 2, delay: 176}, {dir: 3, delay: 176},
        // ── A2: staircase down ──
        {dir: 3, delay: 353}, {dir: 2, delay: 176}, {dir: 1, delay: 176}, {dir: 0, delay: 176},
        // ── B: jack + run (very Touhou) ──
        {dir: 0, delay: 353}, {dir: 0, delay: 176},
        {dir: 1, delay: 176}, {dir: 2, delay: 176}, {dir: 3, delay: 176},
        {dir: 3, delay: 176},
        {dir: 2, delay: 176}, {dir: 1, delay: 176}, {dir: 0, delay: 176},
        // ── C: syncopated cross-hands ──
        {dir: 0, delay: 353}, {dir: 3, delay: 265},
        {dir: 1, delay: 176}, {dir: 2, delay: 265},
        {dir: 3, delay: 176}, {dir: 0, delay: 265},
        {dir: 2, delay: 176}, {dir: 1, delay: 176},
        // ── D: alternating jacks ──
        {dir: 0, delay: 353}, {dir: 0, delay: 176},
        {dir: 3, delay: 353}, {dir: 3, delay: 176},
        {dir: 1, delay: 353}, {dir: 1, delay: 176},
        {dir: 2, delay: 353}, {dir: 2, delay: 176},
        // ── E: dense 8th run ──
        {dir: 0, delay: 353}, {dir: 2, delay: 176}, {dir: 3, delay: 176}, {dir: 1, delay: 176},
        {dir: 0, delay: 176}, {dir: 3, delay: 176}, {dir: 2, delay: 176}, {dir: 1, delay: 176},
        // ── F: 16th burst finale ──
        {dir: 0, delay: 353}, {dir: 1, delay: 88},  {dir: 2, delay: 88},  {dir: 3, delay: 88},
        {dir: 2, delay: 88},  {dir: 1, delay: 88},  {dir: 0, delay: 88},  {dir: 1, delay: 88},
        {dir: 2, delay: 88},  {dir: 3, delay: 88},  {dir: 2, delay: 88},  {dir: 1, delay: 88}
    ]

    readonly property var arrowColors:  ["#ff79c6","#8be9fd","#50fa7b","#ff5555"]
    readonly property var arrowSymbols: ["←","↓","↑","→"]

    TextConstants { id: textConstants }

    // ── Video background ─────────────────────────────────────────────
    MediaPlayer {
        id: player
        source: "/path/to/your/background.mp4"   // ← change this to your video file
        loops: MediaPlayer.Infinite
        videoOutput: videoOut
        audioOutput: AudioOutput { volume: 0 }
        Component.onCompleted: play()
    }

    VideoOutput {
        id: videoOut
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    Rectangle { anchors.fill: parent; color: "#55000010" }

    // ── Clock ────────────────────────────────────────────────────────
    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.12 }
        spacing: 6

        Text {
            id: clockText
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.pixelSize: 72; font.weight: Font.Thin; font.letterSpacing: -2
            style: Text.Raised; styleColor: "#40000000"
            Timer {
                interval: 1000; repeat: true; running: true
                onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm")
            }
            Component.onCompleted: text = Qt.formatTime(new Date(), "HH:mm")
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            color: "#ccccee"; font.pixelSize: 16; font.weight: Font.Light; font.letterSpacing: 3
        }
    }

    // ── Glass card (slides out on DDR start) ─────────────────────────
    Item {
        id: card
        width: 380; height: cardCol.implicitHeight + 56
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 40
        anchors.horizontalCenterOffset: ddrActive ? -(root.width) : 0
        Behavior on anchors.horizontalCenterOffset {
            NumberAnimation { duration: 500; easing.type: Easing.InOutCubic }
        }

        ShaderEffectSource {
            id: blurSrc; sourceItem: videoOut
            sourceRect: Qt.rect(card.x, card.y, card.width, card.height)
            anchors.fill: parent; visible: false
        }

        MultiEffect {
            source: blurSrc; anchors.fill: parent
            blurEnabled: true; blur: 1.0; blurMax: 40
            layer.enabled: true; layer.smooth: true
        }

        Rectangle {
            anchors.fill: parent; radius: 20
            color: "#1affffff"; border.color: "#30ffffff"; border.width: 1
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1; leftMargin: 1; rightMargin: 1 }
                height: parent.radius; radius: parent.radius; color: "#18ffffff"
            }
        }

        Column {
            id: cardCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 }
            spacing: 0

            Rectangle {
                width: 64; height: 64; radius: 32
                color: "#30ffffff"; border.color: "#40ffffff"; border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter
                Text { anchors.centerIn: parent; text: "◉"; color: "#ccccff"; font.pixelSize: 28 }
            }

            Item { height: 20; width: 1 }

            Column {
                width: parent.width; spacing: 0
                Text { text: "USERNAME"; color: "#88aabbff"; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 2; leftPadding: 2 }
                Item { height: 6; width: 1 }
                TextInput {
                    id: userField; text: ""   // pre-fill with your username if desired
                    width: parent.width; height: 36; color: "white"
                    font.pixelSize: 15; clip: true; verticalAlignment: TextInput.AlignVCenter
                    leftPadding: 2; KeyNavigation.tab: passField
                    Text {
                        anchors { fill: parent; leftMargin: 2 }
                    verticalAlignment: Text.AlignVCenter
                        text: "Enter username"; color: "#55ffffff"; font.pixelSize: 15
                        visible: !userField.text && !userField.activeFocus
                    }
                }
                Rectangle {
                    width: parent.width; height: 1
                    color: userField.activeFocus ? "#aaaaff" : "#40ffffff"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Item { height: 22; width: 1 }

            Column {
                width: parent.width; spacing: 0
                Text { text: "PASSWORD"; color: "#88aabbff"; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 2; leftPadding: 2 }
                Item { height: 6; width: 1 }
                TextInput {
                    id: passField
                    width: parent.width; height: 36; color: "white"
                    font.pixelSize: 15; echoMode: TextInput.Password; clip: true
                    verticalAlignment: TextInput.AlignVCenter; leftPadding: 2
                    passwordCharacter: "•"; KeyNavigation.tab: loginBtn
                    Keys.onReturnPressed: doLogin(); Keys.onEnterPressed: doLogin()
                    Text {
                        anchors { fill: parent; leftMargin: 2 }
                    verticalAlignment: Text.AlignVCenter
                        text: "Enter password"; color: "#55ffffff"; font.pixelSize: 15
                        visible: !passField.text && !passField.activeFocus
                    }
                }
                Rectangle {
                    width: parent.width; height: 1
                    color: passField.activeFocus ? "#aaaaff" : "#40ffffff"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Item { height: 8; width: 1 }

            Text {
                id: errorMsg; width: parent.width; horizontalAlignment: Text.AlignHCenter
                color: "#ff7b7b"; font.pixelSize: 12; visible: text !== ""
            }

            Item { height: errorMsg.visible ? 4 : 16; width: 1 }

            Rectangle {
                id: loginBtn; width: parent.width; height: 44; radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: loginMouse.containsMouse ? "#7766ee" : "#6655dd" }
                    GradientStop { position: 1.0; color: loginMouse.containsMouse ? "#9944cc" : "#8833bb" }
                }
                Text { anchors.centerIn: parent; text: "Sign in"; color: "white"; font.pixelSize: 14; font.weight: Font.Medium; font.letterSpacing: 1 }
                MouseArea {
                    id: loginMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: doLogin()
                }
                scale: loginMouse.pressed ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
            }

            Item { height: 16; width: 1 }

            QQC2.ComboBox {
                id: sessionCombo; width: parent.width; height: 32
                model: SessionModel; textRole: "name"
                currentIndex: 0
                background: Rectangle { color: "#15ffffff"; radius: 8; border.color: "#25ffffff"; border.width: 1 }
                contentItem: Text { leftPadding: 10; text: sessionCombo.displayText; color: "#aaaacc"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter }
                indicator: Text { x: sessionCombo.width - width - 8; anchors.verticalCenter: parent.verticalCenter; text: "⌄"; color: "#aaaacc"; font.pixelSize: 14 }
                popup: QQC2.Popup {
                    y: sessionCombo.height + 2; width: sessionCombo.width; padding: 4
                    background: Rectangle { color: "#cc1a1a2e"; radius: 8; border.color: "#30ffffff"; border.width: 1 }
                    contentItem: ListView { implicitHeight: contentHeight; model: sessionCombo.popup.visible ? sessionCombo.delegateModel : null; clip: true }
                }
                delegate: QQC2.ItemDelegate {
                    width: sessionCombo.width
                    contentItem: Text { text: modelData; color: "white"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: hovered ? "#30ffffff" : "transparent"; radius: 6 }
                }
            }
        }
    }

    // ── Power buttons ────────────────────────────────────────────────
    Row {
        anchors { bottom: parent.bottom; right: parent.right; margins: 24 }
        spacing: 10
        Repeater {
            model: [
                { label: "⟳", tip: "Reboot",    action: function() { sddm.reboot() } },
                { label: "⏻", tip: "Power off", action: function() { sddm.powerOff() } }
            ]
            delegate: Rectangle {
                width: 40; height: 40; radius: 20
                color: hov.containsMouse ? "#40ffffff" : "#20ffffff"
                border.color: "#25ffffff"; border.width: 1
                Text { anchors.centerIn: parent; text: modelData.label; color: "white"; font.pixelSize: 16 }
                MouseArea {
                    id: hov; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: modelData.action()
                }
                ToolTip.visible: hov.containsMouse; ToolTip.text: modelData.tip; ToolTip.delay: 500
            }
        }
    }

    // ── Particle component ───────────────────────────────────────────
    Component {
        id: particleComp
        Item {
            id: ptcl
            property real  angle:  0
            property real  speed:  80
            property color pcolor: "white"
            width: 7; height: 7
            Rectangle { anchors.fill: parent; radius: 3.5; color: ptcl.pcolor }
            SequentialAnimation {
                running: true
                ParallelAnimation {
                    NumberAnimation { target: ptcl; property: "x"; to: ptcl.x + Math.cos(ptcl.angle) * ptcl.speed; duration: 550; easing.type: Easing.OutQuad }
                    NumberAnimation { target: ptcl; property: "y"; to: ptcl.y + Math.sin(ptcl.angle) * ptcl.speed; duration: 550; easing.type: Easing.OutQuad }
                    NumberAnimation { target: ptcl; property: "opacity"; from: 1; to: 0; duration: 550 }
                    NumberAnimation { target: ptcl; property: "scale";   from: 1; to: 0.2; duration: 550 }
                }
                ScriptAction { script: ptcl.destroy() }
            }
        }
    }

    // ── Confetti component ───────────────────────────────────────────
    Component {
        id: confettiComp
        Rectangle {
            id: piece
            property real drift: 0
            width: 10; height: 5; radius: 2
            SequentialAnimation {
                running: true
                ParallelAnimation {
                    NumberAnimation { target: piece; property: "y"; to: root.height + 30; duration: 1800 + Math.random() * 800; easing.type: Easing.InQuad }
                    NumberAnimation { target: piece; property: "x"; to: piece.x + piece.drift; duration: 1800 + Math.random() * 800 }
                    NumberAnimation { target: piece; property: "rotation"; to: 720 * (Math.random() > 0.5 ? 1 : -1); duration: 1800 + Math.random() * 800 }
                    NumberAnimation { target: piece; property: "opacity"; from: 1; to: 0; duration: 1800 + Math.random() * 800 }
                }
                ScriptAction { script: piece.destroy() }
            }
        }
    }

    // ── RGB spark component (perfect hits) ──────────────────────────
    Component {
        id: rgbSparkComp
        Item {
            id: spark
            property real  angle:      0
            property color sparkColor: "white"
            width: 12; height: 12
            Rectangle { anchors.fill: parent; radius: 6; color: spark.sparkColor }
            SequentialAnimation {
                running: true
                ParallelAnimation {
                    NumberAnimation { target: spark; property: "x"; to: spark.x + Math.cos(spark.angle) * 140; duration: 700; easing.type: Easing.OutQuad }
                    NumberAnimation { target: spark; property: "y"; to: spark.y + Math.sin(spark.angle) * 140; duration: 700; easing.type: Easing.OutQuad }
                    NumberAnimation { target: spark; property: "opacity"; from: 1; to: 0; duration: 700 }
                    NumberAnimation { target: spark; property: "scale"; from: 1.6; to: 0.1; duration: 700 }
                }
                ScriptAction { script: spark.destroy() }
            }
        }
    }

    // ── Ripple ring component (every hit) ───────────────────────────
    Component {
        id: rippleComp
        Rectangle {
            id: ripple
            property color rippleColor: "white"
            width: 10; height: 10; radius: 5
            color: "transparent"; border.color: rippleColor; border.width: 3; opacity: 0.9
            SequentialAnimation {
                running: true
                ParallelAnimation {
                    NumberAnimation { target: ripple; property: "width";  from: 10;  to: 220; duration: 600; easing.type: Easing.OutExpo }
                    NumberAnimation { target: ripple; property: "height"; from: 10;  to: 220; duration: 600; easing.type: Easing.OutExpo }
                    NumberAnimation { target: ripple; property: "x";      to: ripple.x - 105; duration: 600; easing.type: Easing.OutExpo }
                    NumberAnimation { target: ripple; property: "y";      to: ripple.y - 105; duration: 600; easing.type: Easing.OutExpo }
                    NumberAnimation { target: ripple; property: "opacity"; from: 0.9; to: 0;  duration: 600 }
                }
                ScriptAction { script: ripple.destroy() }
            }
        }
    }

    // ── DDR arrow component ──────────────────────────────────────────
    Component {
        id: arrowComp
        Item {
            id: arrowItem
            property int  dir:      0
            property bool consumed: false
            property int  travelMs: 1300
            width: 80; height: 80

            function flashHit() { hitFlash.opacity = 0.9; hitFlashAnim.restart() }

            // Bloom layer
            Text {
                anchors.centerIn: parent
                text: root.arrowSymbols[arrowItem.dir]; font.pixelSize: 48
                color: root.arrowColors[arrowItem.dir]
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 32; brightness: 0.6 }
            }
            // Sharp layer
            Text {
                anchors.centerIn: parent
                text: root.arrowSymbols[arrowItem.dir]; font.pixelSize: 44
                color: root.arrowColors[arrowItem.dir]
                style: Text.Outline; styleColor: Qt.darker(root.arrowColors[arrowItem.dir], 2.5)
            }

            Rectangle {
                id: hitFlash; anchors.fill: parent; radius: 8; color: "white"; opacity: 0
                NumberAnimation { id: hitFlashAnim; target: hitFlash; property: "opacity"; from: 0.9; to: 0; duration: 200 }
            }

            NumberAnimation on y {
                from: -80; to: ddrGameArea.height + 80; duration: arrowItem.travelMs; running: true
                onStopped: {
                    if (!arrowItem.consumed) { arrowItem.consumed = true; root.ddrOnMiss() }
                    arrowItem.destroy()
                }
            }
        }
    }

    // ── DDR overlay ──────────────────────────────────────────────────
    FocusScope {
        id: ddrOverlay
        anchors.fill: parent
        visible: ddrActive
        focus: ddrActive

        Keys.onPressed: function(event) {
            var dir = -1
            if      (event.key === Qt.Key_Left  || event.key === Qt.Key_D) dir = 0
            else if (event.key === Qt.Key_Down  || event.key === Qt.Key_F) dir = 1
            else if (event.key === Qt.Key_Up    || event.key === Qt.Key_J) dir = 2
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_K) dir = 3
            if (dir >= 0) { event.accepted = true; root.ddrKeyPress(dir) }
        }

        Rectangle { anchors.fill: parent; color: "#cc000020" }

Text {
            id: ddrTitle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: parent.height * 0.12
            text: "AUTHENTICATE"; color: "#cc99ff"
            font.pixelSize: 24; font.weight: Font.Bold; font.letterSpacing: 6
            style: Text.Raised; styleColor: "#60000000"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: ddrTitle.bottom; anchors.topMargin: 4
            text: "press the arrows as they reach the targets"
            color: "#88aabbff"; font.pixelSize: 12; font.letterSpacing: 1
        }

        // Countdown overlay
        Item {
            anchors.fill: parent
            visible: ddrCountdown > 0

            Text {
                id: countdownNum
                anchors.centerIn: parent
                text: ddrCountdown
                font.pixelSize: 160; font.weight: Font.Bold
                color: ddrCountdown === 1 ? "#50fa7b" : ddrCountdown === 2 ? "#ffaa44" : "#ff5555"
                style: Text.Outline; styleColor: Qt.darker(countdownNum.color, 3)
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.9; blurMax: 40; brightness: 0.8 }

                onTextChanged: {
                    countdownNum.scale = 1.5
                    countdownPop.restart()
                }
                NumberAnimation {
                    id: countdownPop; target: countdownNum; property: "scale"
                    from: 1.5; to: 1.0; duration: 300; easing.type: Easing.OutBack
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: countdownNum.bottom; anchors.topMargin: -20
                text: ddrCountdown === 1 ? "GET READY" : ""
                color: "#aaaacc"; font.pixelSize: 16; font.letterSpacing: 4
            }
        }

        // Combo counter
        Text {
            anchors.right: ddrGameArea.right
            anchors.bottom: ddrGameArea.top; anchors.bottomMargin: 6
            visible: ddrCombo >= 3
            text: ddrCombo + "x COMBO"
            font.pixelSize: Math.min(14 + ddrCombo, 30); font.weight: Font.Bold; font.letterSpacing: 2
            color: ddrCombo >= 8 ? "#ffe066" : (ddrCombo >= 5 ? "#ff79c6" : "#8be9fd")
            style: Text.Outline; styleColor: "#60000000"
            Behavior on font.pixelSize { NumberAnimation { duration: 100 } }
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 0.6; blurMax: 16; brightness: 0.4 }
        }

        // ── Game area ────────────────────────────────────────────────
        Item {
            id: ddrGameArea
            width: 320
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            clip: false

            // Lane backgrounds
            Repeater {
                model: 4
                Rectangle {
                    x: index * 80; y: 0; width: 80; height: ddrGameArea.height
                    color: index % 2 === 0 ? "#0affffff" : "#05ffffff"
                    border.color: "#10ffffff"; border.width: 1
                }
            }

            // Lane hit flash
            Repeater {
                id: laneFlashRep
                model: 4
                Rectangle {
                    id: laneFlashRect
                    x: index * 80; y: 0; width: 80; height: ddrGameArea.height
                    color: root.arrowColors[index]; opacity: 0
                    function flash() { laneFlashAnim.restart() }
                    NumberAnimation {
                        id: laneFlashAnim; target: laneFlashRect; property: "opacity"
                        from: 0.30; to: 0; duration: 220
                    }
                }
            }

            // CRT scanlines (dynamic count based on height)
            Item {
                anchors.fill: parent; z: 10
                Repeater {
                    model: Math.ceil(ddrGameArea.height / 4)
                    Rectangle { x: 0; y: index * 4; width: ddrGameArea.width; height: 1; color: "#1a000000" }
                }
            }

            // Judgment bar — animated rainbow with shimmer sweep
            Item {
                x: 0; y: ddrGameArea.height - 121
                width: ddrGameArea.width; height: 5
                clip: true

                Rectangle {
                    anchors.fill: parent; radius: 2
                    color: Qt.hsva(barHue, 0.85, 1.0, 0.80)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true; blur: 0.8; blurMax: 22; brightness: 0.9
                    }
                }

                // Moving shimmer highlight
                Rectangle {
                    y: 0; width: 70; height: parent.height; radius: 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: "#99ffffff" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        NumberAnimation { from: -70; to: ddrGameArea.width + 10; duration: 1100; easing.type: Easing.InOutSine }
                        PauseAnimation { duration: 350 }
                    }
                }
            }

            // Target arrows
            Repeater {
                id: targetRep
                model: 4
                Item {
                    id: targetItem
                    property bool flash: false
                    x: index * 80 + 10
                    y: ddrGameArea.height - 150
                    width: 60; height: 60

                    function triggerFlash() { flash = true; flashTimer.restart() }
                    Timer { id: flashTimer; interval: 150; onTriggered: targetItem.flash = false }

                    Rectangle {
                        anchors.fill: parent; radius: 8; color: "transparent"
                        border.color: targetItem.flash ? root.arrowColors[index] : "#40ffffff"
                        border.width: targetItem.flash ? 3 : 2
                        Behavior on border.color { ColorAnimation { duration: 60 } }
                    }
                    // Bloom on flash
                    Text {
                        anchors.centerIn: parent; text: root.arrowSymbols[index]; font.pixelSize: 52
                        color: root.arrowColors[index]; visible: targetItem.flash
                        layer.enabled: true
                        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 40; brightness: 0.8 }
                    }
                    Text {
                        anchors.centerIn: parent; text: root.arrowSymbols[index]; font.pixelSize: 44
                        color: targetItem.flash ? root.arrowColors[index] : "#30ffffff"
                        style: targetItem.flash ? Text.Outline : Text.Normal
                        styleColor: Qt.darker(root.arrowColors[index], 2)
                        Behavior on color { ColorAnimation { duration: 60 } }
                    }
                }
            }
        }

        // Skip button
        Rectangle {
            anchors { bottom: parent.bottom; right: parent.right; margins: 20 }
            width: 80; height: 30; radius: 8
            color: skipMouse.containsMouse ? "#40ffffff" : "#20ffffff"
            border.color: "#30ffffff"; border.width: 1
            Text { anchors.centerIn: parent; text: "skip"; color: "#88ffffff"; font.pixelSize: 12; font.letterSpacing: 1 }
            MouseArea {
                id: skipMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    ddrCleanup()
                    ddrActive = false
                    sddm.login(userField.text, passField.text, Math.max(0, sessionCombo.currentIndex))
                }
            }
        }

        // Feedback text
        Text {
            id: ddrFeedbackText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: ddrGameArea.bottom; anchors.topMargin: 10
            text: ddrFeedback
            font.pixelSize: ddrFeedback === "PERFECT!" ? 30 : 22
            font.weight: Font.Bold; font.letterSpacing: 3
            color: {
                if (ddrFeedback === "PERFECT!")               return "#ffe066"
                if (ddrFeedback === "HIT!" || ddrFeedback === "GOOD") return "#50fa7b"
                if (ddrFeedback === "LATE")                   return "#ffaa44"
                return "#ff5555"
            }
            style: Text.Raised; styleColor: "#40000000"
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 0.8; blurMax: 20; brightness: 0.5 }
            Behavior on font.pixelSize { NumberAnimation { duration: 80 } }
            onTextChanged: {
                if (text === "PERFECT!") { ddrFeedbackText.scale = 1.5; feedbackScalePop.restart() }
                else { ddrFeedbackText.scale = 1.0 }
            }
            NumberAnimation { id: feedbackScalePop; target: ddrFeedbackText; property: "scale"; from: 1.5; to: 1.0; duration: 350; easing.type: Easing.OutBack }
        }

        // Progress + health bars
        // Hit progress (hits out of total pattern arrows)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: ddrFeedbackText.bottom; anchors.topMargin: 8
            width: 320; height: 6; radius: 3; color: "#20ffffff"
            Rectangle {
                width: parent.width * Math.min(ddrHits / arrowPattern.length, 1.0)
                height: parent.height; radius: 3; color: "#50fa7b"
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }

        // Grade reveal (shown on win, before logging in)
        Rectangle {
            id: gradeOverlay
            anchors.fill: parent; color: "#dd000015"
            visible: false; opacity: 0
            NumberAnimation { id: gradeOverlayFadeIn; target: gradeOverlay; property: "opacity"; from: 0; to: 1; duration: 500 }

            Text {
                id: gradeLetter
                anchors.centerIn: parent; anchors.verticalCenterOffset: -30
                text: ddrGrade; font.pixelSize: 120; font.weight: Font.Bold
                color: {
                    if (ddrGrade === "S") return "#ffe066"
                    if (ddrGrade === "A") return "#50fa7b"
                    if (ddrGrade === "B") return "#8be9fd"
                    if (ddrGrade === "C") return "#ff79c6"
                    return "#ff5555"
                }
                style: Text.Outline; styleColor: Qt.darker(gradeLetter.color, 3)
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.9; blurMax: 30; brightness: 0.7 }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter; anchors.topMargin: 50
                text: ddrAccuracy + "% accuracy"
                color: "white"; font.pixelSize: 18; font.letterSpacing: 2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter; anchors.topMargin: 78
                text: "best combo: " + ddrMaxCombo + "x"
                color: "#aaaacc"; font.pixelSize: 14; font.letterSpacing: 1
            }
        }
    }

    // ── Timers ───────────────────────────────────────────────────────
    // Rainbow judgment bar hue cycle
    Timer { interval: 30; repeat: true; running: ddrActive; onTriggered: barHue = (barHue + 0.007) % 1.0 }

    Timer {
        id: countdownTimer; interval: 1000; repeat: true
        onTriggered: {
            ddrCountdown--
            if (ddrCountdown <= 0) {
                stop()
                patternTimer.interval = arrowPattern[0].delay
                patternTimer.start()
            }
        }
    }

    Timer {
        id: patternTimer; repeat: false; running: false
        onTriggered: {
            if (ddrDone) return
            var entry = arrowPattern[patternIndex]
            var arrow = arrowComp.createObject(ddrGameArea, { dir: entry.dir, x: entry.dir * 80, travelMs: root.arrowDuration })
            var arr = ddrArrows; arr.push(arrow); ddrArrows = arr
            patternIndex++
            if (patternIndex >= arrowPattern.length) {
                // All arrows spawned — wait for last one to land then finish
                patternEndTimer.interval = arrowDuration + 400
                patternEndTimer.start()
            } else {
                patternTimer.interval = arrowPattern[patternIndex].delay
                patternTimer.restart()
            }
        }
    }

    Timer {
        id: patternEndTimer; repeat: false
        onTriggered: {
            if (ddrDone) return
            ddrDone = true
            calcGrade()
            spawnConfetti()
            ddrFeedback = ""
            gradeOverlay.visible = true
            gradeOverlayFadeIn.start()
            ddrGradeTimer.start()
        }
    }

    // Real-time miss detection — fires as soon as arrow passes the late zone
    Timer {
        id: missCheckTimer; interval: 32; repeat: true; running: ddrActive && !ddrDone
        onTriggered: {
            var missLine = ddrGameArea.height - 120 + 72   // hitCenter + lateZone
            for (var i = 0; i < ddrArrows.length; i++) {
                var a = ddrArrows[i]
                if (!a || a.consumed) continue
                if (a.y > missLine) {
                    a.consumed = true
                    root.ddrOnMiss()
                }
            }
        }
    }

    Timer {
        id: ddrFeedbackClear; interval: 500
        onTriggered: if (ddrFeedback !== "PERFECT!" && ddrFeedback !== "FAILED!") ddrFeedback = ""
    }

    Timer {
        id: ddrGradeTimer; interval: 2200
        onTriggered: {
            gradeOverlay.visible = false
            ddrActive = false
            ddrCleanup()
            sddm.login(userField.text, passField.text, Math.max(0, sessionCombo.currentIndex))
        }
    }


    // ── DDR logic ────────────────────────────────────────────────────
    function calcGrade() {
        var total = ddrHits + ddrMisses
        var acc = total === 0 ? 100 : Math.round((ddrHits / total) * 100)
        ddrAccuracy = acc
        if (acc === 100 && ddrMisses === 0) ddrGrade = "S"
        else if (acc >= 90)                 ddrGrade = "A"
        else if (acc >= 75)                 ddrGrade = "B"
        else if (acc >= 60)                 ddrGrade = "C"
        else                                ddrGrade = "D"
    }

    function spawnParticles(px, py, col) {
        for (var i = 0; i < 10; i++) {
            var angle = (i / 10) * 2 * Math.PI + Math.random() * 0.4
            particleComp.createObject(ddrGameArea, {
                x: px, y: py, angle: angle,
                speed: 50 + Math.random() * 60, pcolor: col
            })
        }
    }

    function spawnConfetti() {
        var cols = ["#ff79c6","#8be9fd","#50fa7b","#ff5555","#ffe066","#cc88ff"]
        for (var i = 0; i < 55; i++) {
            confettiComp.createObject(root, {
                x: Math.random() * root.width,
                y: -15 - Math.random() * 80,
                color: cols[Math.floor(Math.random() * cols.length)],
                drift: (Math.random() - 0.5) * 180
            })
        }
    }

    function spawnRgbSparks(px, py) {
        var count = 16
        for (var i = 0; i < count; i++) {
            var hue = i / count
            var col = Qt.hsva(hue, 1.0, 1.0, 1.0)
            var angle = (i / count) * 2 * Math.PI
            rgbSparkComp.createObject(ddrGameArea, { x: px - 6, y: py - 6, angle: angle, sparkColor: col })
        }
    }

    function spawnRipple(dir) {
        rippleComp.createObject(ddrGameArea, {
            x: dir * 80 + 35,
            y: ddrGameArea.height - 125,
            rippleColor: arrowColors[dir]
        })
    }

function ddrKeyPress(dir) {
        if (ddrDone) return

        var hitCenter   = ddrGameArea.height - 120   // center of target zone
        var perfectZone = 28
        var goodZone    = 52
        var lateZone    = 72
        var bestArrow   = null
        var bestDist    = lateZone + 1

        for (var i = 0; i < ddrArrows.length; i++) {
            var a = ddrArrows[i]
            if (!a || a.consumed || a.dir !== dir) continue
            var dist = Math.abs(a.y - hitCenter)
            if (dist <= lateZone && dist < bestDist) { bestDist = dist; bestArrow = a }
        }

        if (bestArrow) {
            bestArrow.consumed = true
            bestArrow.flashHit()
            targetRep.itemAt(dir).triggerFlash()
            laneFlashRep.itemAt(dir).flash()
            spawnParticles(bestArrow.x + 40, bestArrow.y + 40, arrowColors[dir])

            ddrHits++; ddrCombo++
            if (ddrCombo > ddrMaxCombo) ddrMaxCombo = ddrCombo

            arrowDuration = Math.max(1100, 1500 - ddrCombo * 15)

            if      (bestDist < perfectZone) { ddrPerfects++; ddrFeedback = "PERFECT!"; spawnRgbSparks(bestArrow.x + 40, bestArrow.y + 40) }
            else if (bestDist < goodZone)    { ddrGoods++;    ddrFeedback = "GOOD" }
            else                             {                ddrFeedback = "LATE" }
            spawnRipple(dir)
            ddrFeedbackClear.restart()

        } else {
            ddrCombo = 0; ddrMisses++
            ddrFeedback = "MISS!"; shakeAnim.restart(); ddrFeedbackClear.restart()
        }
    }

    function ddrOnMiss() {
        if (ddrDone) return
        ddrCombo = 0; ddrMisses++
        ddrFeedback = "MISS!"; shakeAnim.restart(); ddrFeedbackClear.restart()
    }

    function ddrCleanup() {
        countdownTimer.stop(); patternTimer.stop(); patternEndTimer.stop(); ddrGradeTimer.stop(); missCheckTimer.stop(); ddrFeedbackClear.stop()
        ddrHits = 0; ddrMisses = 0; ddrCombo = 0; ddrMaxCombo = 0
        ddrPerfects = 0; ddrGoods = 0; ddrDone = false
        ddrFeedback = ""; ddrGrade = ""; ddrAccuracy = 0
        arrowDuration = 1500; patternIndex = 0; ddrCountdown = 0
        gradeOverlay.visible = false
        var arr = ddrArrows
        for (var i = 0; i < arr.length; i++) {
            try { if (arr[i]) { arr[i].consumed = true; arr[i].destroy() } } catch(e) {}
        }
        ddrArrows = []
    }

    // ── Login ────────────────────────────────────────────────────────
    function doLogin() {
        if (ddrActive) return
        errorMsg.text = ""
        ddrCleanup()
        ddrActive = true
        ddrCountdown = 3
        ddrOverlay.forceActiveFocus()
        countdownTimer.start()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorMsg.text = "Incorrect credentials"
            passField.text = ""; passField.forceActiveFocus()
        }
    }

    Component.onCompleted: userField.forceActiveFocus()
}
