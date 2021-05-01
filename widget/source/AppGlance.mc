using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Hass;

/**
* Semi working example, less than proof of concept
* Known bugs:
* - sometimes occures Illegal Access (Out of Bounds) on onWebResponse(),
*   because too much memory is used, code has to be cut down
*   especially Client.mc and its parents. When this happend in simulator
*   select File->Reset All App Data
* - is unclear when System.getDeviceSettings().isGlanceModeEnabled
*   is true. This is used to store entities states into storage
*   when onStop called, but only if glance is NOT on. Simulator
*   is working the opposite way 
*/

(:glance)
class AppGlance extends Ui.GlanceView {
    var _glanceEntity;
    var _timer;

    function initialize(glEn) {
        GlanceView.initialize();
        _glanceEntity = glEn;
    }

    function onHide() {
        if (_timer) {_timer.stop();}
    }

    function onShow() {
        if (_glanceEntity) {
            _timer = new Timer.Timer();
            _timer.start(method(:onTimerDone), 30000, true);
            onTimerDone();
        }
    }

    function onTimerDone() {
        Hass.refreshSingleEntity(_glanceEntity);
    }

    function onUpdate(dc) {
        var height = dc.getHeight();
        var font = Graphics.FONT_MEDIUM;
        var text = "HassControl";
        
        if (_glanceEntity) {
            var entityState = Hass.getEntityState(_glanceEntity);
            if (entityState != null && entityState.hasKey("state")) {text = entityState["state"];}
        }

        var textHeight = dc.getTextDimensions(text, font)[1];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(5, (height / 2) - (textHeight / 2), font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }
}