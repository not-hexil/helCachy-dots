
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config 
import ".." 

StyledRect {
    id: matrixContainer

    // Increase height for a more dramatic waterfall effect.
    implicitWidth: 32
    implicitHeight: 115 
    
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: Appearance.padding.small
    Layout.bottomMargin: Appearance.padding.small

    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
    radius: 16
    
    // Clip ensures characters stay inside the pill during rotation/fall
    clip: true 

    property string chars: "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ1234567890=+-*"
    function getRandomChar() {
        return chars.charAt(Math.floor(Math.random() * chars.length));
    }

    // Primary: The leading edge of the rain.
    // onSurfaceVariant: The fading "tail" that blends into the UI.
    readonly property color headColor: Colours.palette.m3primary
    readonly property color tailColor: Colours.palette.m3onSurfaceVariant

    ColumnLayout {
        anchors.centerIn: parent
        spacing: -4
        
        StyledText { id: char1; text: "0"; opacity: 0.1; color: tailColor; font.pixelSize: 13; font.weight: Font.Medium }
        StyledText { id: char2; text: "0"; opacity: 0.2; color: tailColor; font.pixelSize: 13; font.weight: Font.Medium }
        StyledText { id: char3; text: "1"; opacity: 0.3; color: tailColor; font.pixelSize: 13; font.weight: Font.Medium }
        StyledText { id: char4; text: "A"; opacity: 0.5; color: tailColor; font.pixelSize: 13; font.weight: Font.Bold }
        StyledText { id: char5; text: "5"; opacity: 0.7; color: headColor; font.pixelSize: 13; font.weight: Font.Bold }
        StyledText { id: char6; text: "Ω"; opacity: 0.9; color: headColor; font.pixelSize: 13; font.weight: Font.ExtraBold }
        
        StyledText { id: char7; text: "X"; opacity: 1.0; color: Colours.palette.m3onPrimaryContainer; font.pixelSize: 13; font.weight: Font.Black }
    }

    Timer {
        interval: 95 // pacing
        running: true
        repeat: true
        onTriggered: {
            char1.text = getRandomChar();
            char2.text = getRandomChar();
            char3.text = getRandomChar();
            char4.text = getRandomChar();
            char5.text = getRandomChar();
            char6.text = getRandomChar();
            char7.text = getRandomChar();
        }
    }
}
