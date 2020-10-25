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
        App.getApp().viewController.showLoginView(false);
        return true;
    }
}

class LoginView extends Ui.View {
    hidden var _isActive;

    function initialize() {
        View.initialize();

        _isActive = false;
    }

    function onShow() {
        _isActive = true;
    }

    function onHide() {
        _isActive = false;
    }

    function isActive() {
        return _isActive;
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.LoginLayout(dc));
    }
}