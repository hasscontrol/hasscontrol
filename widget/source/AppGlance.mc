using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Hass;

/**
* Semi working example, less than proof of concept
* Known bugs:
* - sometimes occures Illegal Access (Out of Bounds),
*   because too much memory is used
* - Ui refreshing is currently done using timer,
*   this has to be transformed into refreshSingleEntity callback
*/

(:glance)
class AppGlance extends Ui.GlanceView {
    var _glanceEntity;

    function initialize(glEn) {
        GlanceView.initialize();
        _glanceEntity = glEn;
        var _timer = new Timer.Timer();
        _timer.start(method(:onTimerDone), 5000, false);
    }

    function onShow() {
        if (_glanceEntity != null) {
            Hass.refreshSingleEntity(_glanceEntity);
        }
    }
    
    function onTimerDone() {
        Ui.requestUpdate();
    }

    function onUpdate(dc) {
        var height = dc.getHeight();
        var font = Graphics.FONT_MEDIUM;
        var text = "HassControl";
        
        if (_glanceEntity != null) {
            var entityState = Hass.getEntityState(_glanceEntity);
            if (entityState != null && entityState.hasKey("state")) {
                text = entityState["state"];
            }
        }

        var textHeight = dc.getTextDimensions(text, font)[1];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(5, (height / 2) - (textHeight / 2), font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }
}