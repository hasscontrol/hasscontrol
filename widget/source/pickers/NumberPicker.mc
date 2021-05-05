using Toybox.Application;
using Toybox.Graphics;
using Toybox.WatchUi;
using Hass;

class NumberPickerDelegate extends WatchUi.PickerDelegate {
    hidden var _entityId;
    hidden var _paramName;

    function initialize(id, param) {
        PickerDelegate.initialize();
        _entityId = id;
        _paramName = param;
    }

    function onCancel() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        Hass.setEntityState(_entityId, _entityId.substring(0,_entityId.find(".")), Hass.Client.ENTITY_ACTION_TURN_ON, {_paramName => values[0]});
    }
}

class NumberPickerView extends WatchUi.Picker {
    function initialize(strRez, initVal, fVal) {
        var title = new WatchUi.Text({:text=>WatchUi.loadResource(strRez), :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
        Picker.initialize({:title=>title,
                           :pattern=>[new NumberFactory(fVal[0], fVal[1], fVal[2], null)],
                           :defaults=>[(initVal - fVal[0]) / fVal[2]]
                           });
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }
}