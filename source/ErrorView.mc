using Toybox.WatchUi as Ui;

class ErrorView extends Ui.View {
    hidden var _message;
    hidden var _isActive;
    function initialize() {
        View.initialize();
        _isActive = false;
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.ErrorLayout(dc));
    }

    function setMessage(message) {
        _message = message;
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

    function onUpdate(dc) {
        var titleEl = View.findDrawableById("Title");
        var messageEl = View.findDrawableById("Message");

        titleEl.setText("Failed");
        messageEl.setText(_message.toString());

        View.onUpdate(dc);
    }
}