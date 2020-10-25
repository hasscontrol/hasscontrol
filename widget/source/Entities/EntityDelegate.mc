using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Time;

class EntityDelegate extends Ui.BehaviorDelegate {
    hidden var _controller;

    function initialize(controller) {
        BehaviorDelegate.initialize();
        _controller = controller;
    }

    function onMenu() {
        App.getApp().menu.showRootMenu();
        return false;
    }

    function onNextPage() {
        _controller.focusNextEntity();
        Ui.requestUpdate();
        return true;
    }

    function onPreviousPage() {
        _controller.focusPreviousEntity();
        Ui.requestUpdate();
        return true;
    }

    function onSelect() {
        _controller.toggleFocusedEntity();
        return true;
    }
}