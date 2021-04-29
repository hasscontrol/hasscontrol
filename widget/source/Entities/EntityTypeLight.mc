using Toybox.Application as App;
using Toybox.WatchUi as Ui;


class EntityTypeLightDelegate extends Ui.BehaviorDelegate {
    hidden var _entityId;
    
    function initialize(entId) {
        BehaviorDelegate.initialize();
        _entityId = entId;
    }
}

class EntityTypeLightView extends Ui.View {
    hidden var _entityId;
    
    function initialize(entId) {
        View.initialize();
        _entityId = entId;
    }
    
    function onUpdate(dc) {    
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.drawText(120, 120, Graphics.FONT_TINY, Hass.getEntityState(_entityId)["state"], Graphics.TEXT_JUSTIFY_CENTER);
    }
}
