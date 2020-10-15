using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class ErrorDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        App.getApp().viewController.removeError();
        return true;
    }

    function onBack() {
        App.getApp().viewController.removeError();
        return true;
    }
}