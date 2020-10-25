using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class BaseDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        App.getApp().launchInitialView();
        return true;
    }
}