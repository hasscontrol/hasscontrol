using Toybox.WatchUi as Ui;

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