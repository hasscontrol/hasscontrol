using Toybox.WatchUi as Ui;
using EntityLayout as Lay;

class EntityTypeLightDelegate extends Ui.BehaviorDelegate {
    const PAGE_STATE = "state";
    const PAGE_BRIGHTNESS = "brightness";
    const PAGE_COLOUR_TEMP = "color_temp";

    hidden var _pages;
    hidden var _entityId;
    hidden var _pageIndex;

    function initialize(entId) {
        BehaviorDelegate.initialize();
        _entityId = entId;
        _pageIndex = 0;
        _pages = [PAGE_STATE];
        if (Hass.getEntityState(entId)["attributes"].hasKey(PAGE_BRIGHTNESS)) {
            _pages.add(PAGE_BRIGHTNESS);
        }
        if (Hass.getEntityState(entId)["attributes"].hasKey(PAGE_COLOUR_TEMP)) {
            _pages.add(PAGE_COLOUR_TEMP);
        }
    }

    /**
    * Returns entity id
    */
    function getCurrentEntityId() {
        return _entityId;
    }

    /**
    * Get total pages and current page index used in scroll bar
    */
    function getTotalAndIndex() {return [_pages.size(), _pageIndex];}

    /**
    * Returns selected page id
    */
    function getCurrentPage() {
        return _pages[_pageIndex];
    }

    function onNextPage() {
        _pageIndex = (_pageIndex + 1) % _pages.size();
        Ui.requestUpdate();
        return true;
    }

    function onPreviousPage() {
        _pageIndex--;
        if (_pageIndex < 0) {_pageIndex = _pages.size() - 1;}
        Ui.requestUpdate();
        return true;
    }

    function onSelect() {
        if (getCurrentPage() == PAGE_STATE) {
            return Hass.toggleEntityState(_entityId, _entityId.substring(0,_entityId.find(".")),
                                          Hass.getEntityState(_entityId)["state"]);
        } else if (getCurrentPage() == PAGE_BRIGHTNESS) {
            pushView(new NumberPickerView(Rez.Strings.Percentage,
                                          Hass.getEntityState(_entityId)["attributes"]["brightness"] * 100 / 255,
                                          [0, 100, 5]),
                     new NumberPickerDelegate(_entityId, "brightness_pct"), WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (getCurrentPage() == PAGE_COLOUR_TEMP) {
            var attr = Hass.getEntityState(_entityId)["attributes"];
            pushView(new NumberPickerView(Rez.Strings.Mireds,
                                          attr["color_temp"],
                                          [attr["min_mireds"],
                                           attr["max_mireds"],
                                           (attr["max_mireds"] - attr["min_mireds"]) / 20]),
                     new NumberPickerDelegate(_entityId, "color_temp"), WatchUi.SLIDE_IMMEDIATE);
            return true;
        }

        return false;
    }
}

class EntityTypeLightView extends Ui.View {
    hidden var _delegate;

    function initialize(deleg) {
        View.initialize();
        _delegate = deleg;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if (_delegate.getCurrentPage() == _delegate.PAGE_STATE) {
            Lay.drawState(dc, Hass.getEntityState(_delegate.getCurrentEntityId())["state"]);
            Lay.drawName(dc, "toggle state");
        } else if(_delegate.getCurrentPage() == _delegate.PAGE_BRIGHTNESS) {
            Lay.drawState(dc, Hass.getEntityState(_delegate.getCurrentEntityId())["attributes"]["brightness"] * 100 / 255 + " %");
            Lay.drawName(dc, "brightness");
        } else if(_delegate.getCurrentPage() == _delegate.PAGE_COLOUR_TEMP) {
            Lay.drawState(dc, Hass.getEntityState(_delegate.getCurrentEntityId())["attributes"]["color_temp"] + " " + Ui.loadResource(Rez.Strings.Mireds).toLower());
            Lay.drawName(dc, "colour temp");
        }
        Lay.drawScrollBarIfNeeded(dc, _delegate.getTotalAndIndex()[0], _delegate.getTotalAndIndex()[1]);
    }
}
