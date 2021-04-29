using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.Lang;
using Hass;

class EntityListController {
    hidden var _mEntities;
    hidden var _mTypes;
    hidden var _mIndex;

    function initialize(types) {
        _mTypes = types;
        _mIndex = 0;
        refreshEntities();
    }

    /**
    * Returns index of focused entity/page
    */
    function getIndex() {
        return _mIndex;
    }

    /**
    * Returns number of all imported entities
    */
    function getCount() {
        return _mEntities.size();
    }

    /**
    * Loads imported entity ids from HASS 
    */
    function refreshEntities() {
        _mEntities = Hass.getImportedEntities();

        if (_mIndex >= getCount()) {
            _mIndex = 0;
        }
    }
    
    /**
    * Returns current entity id
    */
    function getCurrentEntityId() {
        return _mEntities[_mIndex];
    }

    /**
    * Returns current entity type
    */    
    function getCurrentEntityType() {
    	if (getCount() == 0) {return null;}
        return _mEntities[_mIndex].substring(0, _mEntities[_mIndex].find("."));
    }

    /**
    * Returns attributes of current entity
    */
    function getCurrentEntityAttributes() {
        if (getCount() == 0) {return null;}
        return Hass.getEntityState(_mEntities[_mIndex]);
    }
    
    /**
    * Sets next entity index, rollover is handled
    */
    function setNextPage() {
        _mIndex += 1;
        if (_mIndex > getCount() - 1) {_mIndex = 0;}
    }
    
    /**
    * Sets previous entity index, rollover is handled
    */
    function setPreviousPage() {
        _mIndex -= 1;
        if (_mIndex < 0) {_mIndex = getCount() - 1;}
    }

    /**
    *
    */
    function executeCurrentEntity() {
    //TODO ADD open extended view or just toggle
        if (getCount() == 0) {
            return false;
        }
System.println(_mEntities[_mIndex]);
        return Hass.toggleEntityState(_mEntities[_mIndex], getCurrentEntityType(), getCurrentEntityAttributes()["state"]);
    }
}

class EntityListDelegate extends Ui.BehaviorDelegate {
    hidden var _mController;

    function initialize(controller) {
        BehaviorDelegate.initialize();
        _mController = controller;
    }

    function onMenu() {
        return App.getApp().menu.showRootMenu();
    }

    function onSelect() {
        return _mController.executeCurrentEntity();
    }

    function onNextPage() {
        _mController.setNextPage();
        Ui.requestUpdate();
        return true;
    }

    function onPreviousPage() {
        _mController.setPreviousPage();
        Ui.requestUpdate();
        return true;
    }
}

class EntityListView extends Ui.View {
    hidden var _mController;
    hidden var _mLastIndex;
    hidden var _mTimerScrollBar;
    hidden var _mTimerScrollBarActive;
    hidden var _mShowScrollBar;

    function initialize(controller) {
        View.initialize();
        _mController = controller;
        _mLastIndex = null;
        _mTimerScrollBar = new Timer.Timer();
        _mTimerScrollBarActive = false;
        _mShowScrollBar = false;
    }

    function onShow() {
        _mController.refreshEntities();
    }

    /**
    * Draws entity icon based on its state
    */
    function drawEntityIcon(dc, state, type) {
        var vh = dc.getHeight();
        var vw = dc.getWidth();
        var cvw = vw / 2;
        var drawable = null;

        switch(type) {
            case Hass.ENTITY_TYPE_AUTOMATION:
                drawable = WatchUi.loadResource(state.equals(Hass.STATE_ON) ? Rez.Drawables.AutomationOn : Rez.Drawables.AutomationOff);
                break;
            case Hass.ENTITY_TYPE_BINARY_SENSOR:
                drawable = WatchUi.loadResource(state.equals(Hass.STATE_ON) ? Rez.Drawables.CheckboxOn : Rez.Drawables.CheckboxOff);
                break;
            case Hass.ENTITY_TYPE_INPUT_BOOLEAN:
                drawable = WatchUi.loadResource(state.equals(Hass.STATE_ON) ? Rez.Drawables.CheckboxOn : Rez.Drawables.CheckboxOff);
                break;
            case Hass.ENTITY_TYPE_LIGHT:
                drawable = WatchUi.loadResource(state.equals(Hass.STATE_ON) ? Rez.Drawables.LightOn : Rez.Drawables.LightOff);
                break;
            case Hass.ENTITY_TYPE_LOCK:
                drawable = WatchUi.loadResource(state.equals(Hass.STATE_LOCKED) ? Rez.Drawables.LockLocked : Rez.Drawables.LockUnlocked);
                break;
            case Hass.ENTITY_TYPE_SCENE:
                drawable = WatchUi.loadResource(Rez.Drawables.Scene);
                break;
            case Hass.ENTITY_TYPE_SCRIPT:
                drawable = WatchUi.loadResource(Rez.Drawables.ScriptOff);
                break;
            case Hass.ENTITY_TYPE_SWITCH:
                drawable = WatchUi.loadResource(state.equals(Hass.STATE_ON) ? Rez.Drawables.SwitchOn : Rez.Drawables.SwitchOff);
                break;
            default:
                drawable = WatchUi.loadResource(Rez.Drawables.Unknown);
        }
        
        dc.drawBitmap(cvw - (drawable.getHeight() / 2), (vh * 0.3) - (drawable.getHeight() / 2), drawable);
    }

    /**
    * Common draw text function
    */
    function _drawText(dc, text, hP, fonts) {
        var vh = dc.getHeight();
        var vw = dc.getWidth();
        var cvh = vh / 2;
        var cvw = vw / 2;
        var fontHeight = vh * 0.3;
        var fontWidth = vw * 0.80;
        var font = fonts[0];

        for (var i = 0; i < fonts.size(); i++) {
            var truncate = i == fonts.size() - 1;
            var tempText = Graphics.fitTextToArea(text, fonts[i], fontWidth, fontHeight, truncate);

            if (tempText != null) {
                text = tempText;
                font = fonts[i];
                break;
            }
        }

        dc.drawText(cvw, cvh * hP, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    /**
    * Draws entity state instead of icon
    */
    function drawEntityState(dc, text) {
        _drawText(dc, text, 0.5, [Graphics.FONT_MEDIUM, Graphics.FONT_TINY, Graphics.FONT_XTINY]);
    }

    /**
    * Draws entity name
    */
    function drawEntityName(dc, text) {
        _drawText(dc, text, 1.1, [Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_TINY]);
    }

    /**
    * Draws no entity icon and text
    */
    function drawNoEntityIconText(dc) {
        var vh = dc.getHeight();
        var vw = dc.getWidth();
        var cvh = vh / 2;
        var cvw = vw / 2;
        var SmileySad = Ui.loadResource(Rez.Drawables.SmileySad);

        dc.drawBitmap(cvw - (SmileySad.getHeight() / 2), (vh * 0.3) - (SmileySad.getHeight() / 2), SmileySad);

        var font = Graphics.FONT_MEDIUM;
        var text = Ui.loadResource(Rez.Strings.NoEntities);
        text = Graphics.fitTextToArea(text, font, vw * 0.9, vh * 0.9, true);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(cvw, cvh, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    /**
    * Draws scroll bar
    */
    function drawScrollBar(dc) {
        var vh = dc.getHeight();
        var vw = dc.getWidth();
        var cvh = vh / 2;
        var cvw = vw / 2;
        
        var radius = cvh - 10;
        var padding = 1;
        var topDegreeStart = 130;
        var bottomDegreeEnd = 230;
        var numEntities = _mController.getCount();
        var currentIndex = _mController.getIndex();
        var barSize = ((bottomDegreeEnd - padding) - (topDegreeStart + padding)) / numEntities;
        var barStart = (topDegreeStart + padding) + (barSize * currentIndex);

        var attr = Graphics.ARC_COUNTER_CLOCKWISE;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setPenWidth(10);
        dc.drawArc(cvw, cvh, radius, attr, topDegreeStart, bottomDegreeEnd);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.setPenWidth(6);
        dc.drawArc(cvw, cvh, radius, attr, barStart, barStart + barSize);
    }

    /**
    * Hides scroll bar when timer expires
    */
    function onTimerDone() {
        _mTimerScrollBarActive = false;
        _mShowScrollBar = false;
        Ui.requestUpdate();
    }

    /**
    * Checks if scroll bar should be showed and draws it
    */
    function drawScrollBarIfNeeded(dc) {
        var index = _mController.getIndex();

        if (_mTimerScrollBarActive && _mShowScrollBar == true) {
            return;
        }

        if (_mLastIndex != index) {
            if (_mTimerScrollBarActive) {
                _mTimerScrollBar.stop();
            }
            _mShowScrollBar = true;
            drawScrollBar(dc);
            _mTimerScrollBar.start(method(:onTimerDone), 1000, false);
        }

        _mLastIndex = index;
    }

    function onUpdate(dc) {    
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        var entity = _mController.getCurrentEntityAttributes();
        var entityType = _mController.getCurrentEntityType();
        
        if (entity == null) {
            drawNoEntityIconText(dc);
            return;
        }
    
        if (entityType.equals("sensor")) {
            drawEntityState(dc, entity["state"] + " " + entity["attributes"]["unit_of_measurement"]);
        } else {
            drawEntityIcon(dc, entity["state"], entityType);
        }
        drawEntityName(dc, entity["attributes"]["friendly_name"]);
        drawScrollBarIfNeeded(dc);
    }
}