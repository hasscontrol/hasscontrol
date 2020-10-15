using Toybox.WatchUi as Ui;
using Toybox.Time;

class SceneDelegate extends Ui.BehaviorDelegate {
    hidden var _controller;

    function initialize(controller) {
        BehaviorDelegate.initialize();
        _controller = controller;
    }

    function onNextPage() {
        _controller.focusNextScene();
        Ui.requestUpdate();
        return true;
    }

    function onPreviousPage() {
        _controller.focusPreviousScene();
        Ui.requestUpdate();
        return true;
    }

    function onSelect() {
        _controller.activateFocusedScene();
        return true;
    }
}