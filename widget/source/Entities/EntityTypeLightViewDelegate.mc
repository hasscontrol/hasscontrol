using Toybox.WatchUi as Ui;
using EntityLayout as Lay;

/**
* View and Delegate shows and sets attributes of entity type light
*/
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
        _pages = [PAGE_STATE, PAGE_BRIGHTNESS];
        var col_mods = Hass.getEntityState(entId)["attributes"]["supported_color_modes"];
        if (col_mods.indexOf(PAGE_COLOUR_TEMP) != -1) {
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
    * @returns: array with number of pages and current page
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
        var entitState = Hass.getEntityState(_entityId);
        if (getCurrentPage() == PAGE_STATE) {
            return Hass.toggleEntityState(_entityId, _entityId.substring(0,_entityId.find(".")),
                                          entitState["state"]);
        } else if (getCurrentPage() == PAGE_BRIGHTNESS) {
            pushView(new NumberPickerView(Rez.Strings.Percentage,
                                          entitState["attributes"].hasKey("brightness") ? entitState["attributes"]["brightness"] * 100 / 255 : 0,
                                          [0, 100, 5]),
                     new NumberPickerDelegate(_entityId, "brightness_pct"), WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (getCurrentPage() == PAGE_COLOUR_TEMP) {
            var attr = entitState["attributes"];
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
        var entityState = Hass.getEntityState(_delegate.getCurrentEntityId());
        var currPage = _delegate.getCurrentPage();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if (currPage == _delegate.PAGE_STATE) {
            Lay.drawState(dc, entityState["state"]);
            Lay.drawName(dc, Ui.loadResource(Rez.Strings.State));
        } else if(currPage == _delegate.PAGE_BRIGHTNESS) {
            var val = entityState["attributes"].hasKey("brightness") ? entityState["attributes"]["brightness"] * 100 / 255 : 0;
            Lay.drawState(dc, val + " %");
            Lay.drawName(dc, Ui.loadResource(Rez.Strings.Brightness));
        } else if(currPage == _delegate.PAGE_COLOUR_TEMP) {
            // temperature needs to be checked with real hardware, the values could be provided only if the light is on
            Lay.drawState(dc, entityState["attributes"]["color_temp"] + " " + Ui.loadResource(Rez.Strings.Mireds).toLower());
            Lay.drawName(dc, Ui.loadResource(Rez.Strings.Colour) + " " + Ui.loadResource(Rez.Strings.Temperature).toLower());
        }
        Lay.drawScrollBarIfNeeded(dc, _delegate.getTotalAndIndex()[0], _delegate.getTotalAndIndex()[1]);
    }
}
