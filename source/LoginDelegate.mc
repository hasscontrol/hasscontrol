using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class LoginDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        return true;
    }

    function onBack() {
        // App.getApp().removeError();
        System.println("Should go back!");
        return true;
    }
}