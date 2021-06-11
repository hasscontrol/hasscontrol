using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using EntityLayout as Lay;
using Toybox.Timer;
using Hass;

/**
* View and Delegate used for controlling of alarm panel
*/
class EntityTypeCoverDelegate extends Ui.BehaviorDelegate {
    hidden var _entityId;

    function initialize(entId) {
        BehaviorDelegate.initialize();
        _entityId = entId;
    }

    function onSelect() {
        var entitState = Hass.getEntityState(_entityId);
        var openCloseMenu = new Ui.Menu();

        openCloseMenu.setTitle(entitState["friendly_name"]);
        if (entitState["state"].equals("opening") || entitState["state"].equals("open")) {
            openCloseMenu.addItem(Ui.loadResource(Rez.Strings.Close), :close);
        } else {  //closing, closed
            openCloseMenu.addItem(Ui.loadResource(Rez.Strings.Open), :open);
        }
        openCloseMenu.addItem(Ui.loadResource(Rez.Strings.Stop), :stop);
        Ui.pushView(openCloseMenu, new OpenCloseMenuDelegate(_entityId), WatchUi.SLIDE_IMMEDIATE);

        return true;
    }
}

class EntityTypeCoverView extends Ui.View {
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

class OpenCloseMenuDelegate extends Ui.MenuInputDelegate {
    hidden var _entityId;

    function initialize(entId) {
        MenuInputDelegate.initialize();
        _entityId = entId;
    }

    function onMenuItem(item) {
        var action = Hass.Client.ENTITY_ACTION_STOP;
        if (item == :close) {
            action = Hass.Client.ENTITY_ACTION_CLOSE;
        } else if(item == :open) {
            action = Hass.Client.ENTITY_ACTION_OPEN;
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        Hass.setEntityState(_entityId, _entityId.substring(0,_entityId.find(".")), action, null);
        return true;
    }
}