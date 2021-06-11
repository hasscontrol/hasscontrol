using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using EntityLayout as Lay;
using Toybox.Timer;
using Hass;

/**
* View and Delegate used for controlling of alarm panel
*/
class EntityTypeAlarmPanelDelegate extends Ui.BehaviorDelegate {
    hidden var _entityId;

    function initialize(entId) {
        BehaviorDelegate.initialize();
        _entityId = entId;
    }

    function onSelect() {
        var entitState = Hass.getEntityState(_entityId);
        if (entitState["state"].equals("disarmed")) {
            if (entitState["code_arm_required"] && entitState["code_format"] != null) {
                App.getApp().viewController.showError(Ui.loadResource(Rez.Strings.ErrAlarmCode));
                return false;
            }
            var arm_menu = new Ui.Menu();
            arm_menu.setTitle(entitState["friendly_name"]);
            arm_menu.addItem(Ui.loadResource(Rez.Strings.ArmAway), :away);
            arm_menu.addItem(Ui.loadResource(Rez.Strings.ArmHome), :home);
            WatchUi.pushView(arm_menu, new ArmMenuDelegate(_entityId), WatchUi.SLIDE_IMMEDIATE);
        } else { // includes following states: armed_xyz, pending, triggered, arming
            if (entitState["code_format"] != null) {
                App.getApp().viewController.showError(Ui.loadResource(Rez.Strings.ErrAlarmCode));
                return false;
            }
            Hass.setEntityState(_entityId, _entityId.substring(0,_entityId.find(".")), Hass.Client.ENTITY_ACTION_DISARM, null);
        }

        return true;
    }
}

class EntityTypeAlarmPanelView extends Ui.View {
    hidden var _entityId;
    hidden var _timer;

    function initialize(entId) {
        View.initialize();
        _entityId = entId;
    }

    function refreshState() {
        Hass.refreshSingleEntity(_entityId);
    }

    function onShow() {
        _timer = new Timer.Timer();
        _timer.start(method(:refreshState), 7500, true);
    }

    function onHide() {
        _timer.stop();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        Lay.drawState(dc, Hass.getEntityState(_entityId)["state"]);
        Lay.drawName(dc, Ui.loadResource(Rez.Strings.State));
    }
}

class ArmMenuDelegate extends Ui.MenuInputDelegate {
    hidden var _entityId;

    function initialize(entId) {
        MenuInputDelegate.initialize();
        _entityId = entId;
    }

    function onMenuItem(item) {
        var arm_stat = Hass.Client.ENTITY_ACTION_ARM_AWAY;
        if (item == :home) {arm_stat = Hass.Client.ENTITY_ACTION_ARM_HOME;}
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        Hass.setEntityState(_entityId, _entityId.substring(0,_entityId.find(".")), arm_stat, null);
        return true;
    }
}