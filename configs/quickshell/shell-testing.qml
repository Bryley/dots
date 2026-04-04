import Quickshell // for ShellRoot and PanelWindow
import QtQuick // for Text

ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }

        color: "transparent"

        implicitHeight: 30

        // Rectangle {
        //     anchors.fill: parent
        //
        //     color: "#222222"
        //
        //     Text {
        //         // center the bar in its parent component (the window)
        //         anchors.centerIn: parent
        //
        //         text: "hello world"
        //     }
        // }

        Canvas {
            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d");
                const w = width, h = height;
                const r = h / 2;            // corner radius = half bar height

                // start with a fully opaque mask
                ctx.clearRect(0, 0, w, h);
                ctx.fillStyle = "#222222";
                ctx.fillRect(0, 0, w, h);

                // carve out the inner rect‑fg shape
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                // left edge
                ctx.moveTo(0, h);
                ctx.lineTo(0, r);
                // top‑left rounded corner
                ctx.arcTo(0, 0, r, 0, r);
                // top edge
                ctx.lineTo(w - r, 0);
                // top‑right rounded corner
                ctx.arcTo(w, 0, w, r, r);
                // right edge
                ctx.lineTo(w, h);
                ctx.closePath();
                ctx.fill();
                ctx.globalCompositeOperation = "source-over";
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
    }
}
