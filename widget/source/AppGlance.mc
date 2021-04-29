using Toybox.WatchUi as Ui;
using Hass;

(:glance)
class AppGlance extends Ui.GlanceView {
    var _glanceEntity;

    function initialize(glEn) {
        GlanceView.initialize();
        _glanceEntity = glEn;
    }

    function onShow() {
        Hass.refreshSingleEntity(_glanceEntity);
    }

    function onUpdate(dc) {
        var height = dc.getHeight();
        var font = Graphics.FONT_MEDIUM;
        var text = "HassControl";
        var entityState = Hass.getEntityState(_glanceEntity);
  
        if (entityState != null && entityState.hasKey("state")) {
            text = entityState["state"];
        }

        var textDimensions = dc.getTextDimensions(text, font);
        var textHeight = textDimensions[1];

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(5, (height / 2) - (textHeight / 2), font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }
}