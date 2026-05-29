/* ═══════════════════════════════════════════════════════════════
 * ZoroDojo — SDDM Login Theme (QML)
 * ═══════════════════════════════════════════════════════════════ */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height

    // Background
    Image {
        id: background
        anchors.fill: parent
        source: config.background || "/usr/share/backgrounds/zorolinux/the-vow.png"
        fillMode: Image.PreserveAspectCrop

        // Dark overlay
        Rectangle {
            anchors.fill: parent
            color: "#0D1117"
            opacity: 0.6
        }
    }

    // Logo
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -80
        spacing: 16

        // Logo image
        Image {
            id: logo
            source: "/usr/share/pixmaps/zoro-linux-logo.png"
            width: 128
            height: 128
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
        }

        // Title
        Text {
            text: "⚔  Zoro Linux 10  ⚔"
            color: "#52B788"
            font.pixelSize: 28
            font.bold: true
            font.family: "Inter"
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Santoryu Edition"
            color: "#C9A84C"
            font.pixelSize: 14
            font.family: "Inter"
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Login form
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 100
        spacing: 12
        width: 320

        // Username
        TextField {
            id: userField
            width: parent.width
            height: 44
            placeholderText: "Username"
            color: "#F5F5F0"
            font.pixelSize: 14
            font.family: "Inter"
            horizontalAlignment: TextInput.AlignHCenter

            background: Rectangle {
                radius: 22
                color: Qt.rgba(0.05, 0.07, 0.09, 0.7)
                border.color: Qt.rgba(0.32, 0.72, 0.53, 0.3)
                border.width: 1
            }

            Keys.onReturnPressed: passwordField.focus = true
        }

        // Password
        TextField {
            id: passwordField
            width: parent.width
            height: 44
            placeholderText: "Password"
            echoMode: TextInput.Password
            color: "#F5F5F0"
            font.pixelSize: 14
            font.family: "Inter"
            horizontalAlignment: TextInput.AlignHCenter

            background: Rectangle {
                radius: 22
                color: Qt.rgba(0.05, 0.07, 0.09, 0.7)
                border.color: Qt.rgba(0.32, 0.72, 0.53, 0.3)
                border.width: 1
            }

            Keys.onReturnPressed: sddm.login(userField.text, passwordField.text, sessionCombo.currentIndex)
        }

        // Login button
        Button {
            id: loginButton
            width: parent.width
            height: 44
            text: "⚔  Enter the Dojo"
            font.pixelSize: 14
            font.bold: true
            font.family: "Inter"

            background: Rectangle {
                radius: 22
                color: loginButton.pressed ? "#2D6A4F" : (loginButton.hovered ? "#3E8A6A" : "#52B788")

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            contentItem: Text {
                text: loginButton.text
                font: loginButton.font
                color: "#0D1117"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: sddm.login(userField.text, passwordField.text, sessionCombo.currentIndex)
        }

        // Session selector
        ComboBox {
            id: sessionCombo
            width: parent.width
            height: 36
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
            font.pixelSize: 12
            font.family: "Inter"

            background: Rectangle {
                radius: 18
                color: Qt.rgba(0.05, 0.07, 0.09, 0.5)
                border.color: Qt.rgba(0.66, 0.71, 0.78, 0.2)
                border.width: 1
            }

            contentItem: Text {
                text: sessionCombo.displayText
                color: "#A8B5C8"
                font: sessionCombo.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // Clock
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 24
        color: "#A8B5C8"
        font.pixelSize: 16
        font.family: "Inter"
        text: Qt.formatTime(new Date(), "HH:mm")

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm")
        }
    }

    // Error message
    Text {
        id: errorMsg
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#FF5555"
        font.pixelSize: 12
        font.family: "Inter"
        text: ""
    }

    // Footer quote
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        color: Qt.rgba(0.66, 0.71, 0.78, 0.6)
        font.pixelSize: 11
        font.italic: true
        font.family: "Inter"
        text: "\"Nothing happened.\" — Roronoa Zoro"
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorMsg.text = "⚔ Authentication failed. Try again."
            passwordField.text = ""
            passwordField.focus = true
        }
        function onLoginSucceeded() {
            errorMsg.text = ""
        }
    }

    Component.onCompleted: {
        userField.focus = true
    }
}
