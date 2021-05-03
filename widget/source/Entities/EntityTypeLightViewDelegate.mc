using Toybox.WatchUi as Ui;
using EntityLayout as Lay;

class EntityTypeLightDelegate extends Ui.BehaviorDelegate {
    const PAGE_STATE = "state";
    const PAGE_BRIGHTNESS = "brightness";

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
        // TODO run action
        System.print("run action for:");
        System.println(_pages[_pageIndex]);
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
        }
        Lay.drawScrollBarIfNeeded(dc, _delegate.getTotalAndIndex()[0], _delegate.getTotalAndIndex()[1]);
    }
}
