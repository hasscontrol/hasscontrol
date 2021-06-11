using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Timer;
using ControlMenu;
using EntityLayout as Lay;
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
        _mEntities = [];
        var impEnt = Hass.getImportedEntities();

        for (var i = 0; i < impEnt.size(); i++) {
            if (_mTypes.indexOf(impEnt[i].substring(0, impEnt[i].find("."))) != -1) {
                _mEntities.add(impEnt[i]);
            }
        }

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
    * Calls toggle action or opens extended entity view
    */
    function executeCurrentEntity() {
        if (getCount() == 0) {
            return false;
        }

        var curEntId = getCurrentEntityId();

        switch(getCurrentEntityType()) {
            case Hass.ENTITY_TYPE_LIGHT:
                var col_mod = getCurrentEntityAttributes()["supported_color_modes"];
                if (col_mod[0].equals("onoff")) {break;}
                var deleg = new EntityTypeLightDelegate(curEntId);
                return Ui.pushView(new EntityTypeLightView(deleg), deleg, Ui.SLIDE_LEFT);
            case Hass.ENTITY_TYPE_ALARM_PANEL:
                return Ui.pushView(new EntityTypeAlarmPanelView(curEntId), new EntityTypeAlarmPanelDelegate(curEntId), Ui.SLIDE_LEFT);
            case Hass.ENTITY_TYPE_COVER:
                return Ui.pushView(new EntityTypeCoverView(curEntId), new EntityTypeCoverDelegate(curEntId), Ui.SLIDE_LEFT);
            default:
                break;
        }
        return Hass.toggleEntityState(curEntId, getCurrentEntityType(), getCurrentEntityAttributes()["state"]);
    }
}

class EntityListDelegate extends Ui.BehaviorDelegate {
    hidden var _mController;

    function initialize(controller) {
        BehaviorDelegate.initialize();
        _mController = controller;
    }

    function onMenu() {
        return ControlMenu.showRootMenu();
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
                drawable = state.equals(Hass.STATE_ON) ? Rez.Drawables.AutomationOn : Rez.Drawables.AutomationOff;
                break;
            case Hass.ENTITY_TYPE_BINARY_SENSOR:
                drawable = state.equals(Hass.STATE_ON) ? Rez.Drawables.CheckboxOn : Rez.Drawables.CheckboxOff;
                break;
            case Hass.ENTITY_TYPE_INPUT_BOOLEAN:
                drawable = state.equals(Hass.STATE_ON) ? Rez.Drawables.CheckboxOn : Rez.Drawables.CheckboxOff;
                break;
            case Hass.ENTITY_TYPE_LIGHT:
                drawable = state.equals(Hass.STATE_ON) ? Rez.Drawables.LightOn : Rez.Drawables.LightOff;
                break;
            case Hass.ENTITY_TYPE_LOCK:
                drawable = state.equals(Hass.STATE_LOCKED) ? Rez.Drawables.LockLocked : Rez.Drawables.LockUnlocked;
                break;
            case Hass.ENTITY_TYPE_SCENE:
                drawable = Rez.Drawables.Scene;
                break;
            case Hass.ENTITY_TYPE_SCRIPT:
                drawable = Rez.Drawables.ScriptOff;
                break;
            case Hass.ENTITY_TYPE_SWITCH:
                drawable = state.equals(Hass.STATE_ON) ? Rez.Drawables.SwitchOn : Rez.Drawables.SwitchOff;
                break;
            default:
                drawable = Rez.Drawables.Unknown;
        }

        Lay.drawIcon(dc, drawable);
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var entity = _mController.getCurrentEntityAttributes();
        var entityType = _mController.getCurrentEntityType();

        if (entity == null) {
            Lay.drawIcon(dc, Rez.Drawables.SmileySad);
            Lay.drawName(dc, Ui.loadResource(Rez.Strings.NoEntities));
            return;
        }

        if (entityType.equals("sensor")) {
            Lay.drawState(dc, entity["state"] + " " + entity["unit_of_measurement"]);
        } else {
            drawEntityIcon(dc, entity["state"], entityType);
        }
        Lay.drawName(dc, entity["friendly_name"]);
        Lay.drawScrollBarIfNeeded(dc, _mController.getCount(), _mController.getIndex());
    }
}