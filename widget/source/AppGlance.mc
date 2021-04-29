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
* - Hass.initClient() should be initialized somewhere else,
*   using one call for both modes (glance, non-glance)
*/

(:glance)
class AppGlance extends Ui.GlanceView {
    var _glanceEntity;

    function initialize(glEn) {
        GlanceView.initialize();
        Hass.initClient();	// THIS SHOULD BE MAYBE PLACED SOMEWHERE ELSE
        _glanceEntity = glEn;
        var _timer = new Timer.Timer();
        _timer.start(method(:onTimerDone), 1000, false);
    }

    function onShow() {
        Hass.refreshSingleEntity(_glanceEntity);
    }
    
    function onTimerDone() {
        Ui.requestUpdate();
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