using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

class SceneView extends WatchUi.View {
    hidden var _controller;

    hidden var _prevText;
    hidden var _focusText;
    hidden var _nextText;

    function initialize(controller) {
        View.initialize();
        _controller = controller;
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.SceneLayout(dc));
    }

    function onShow() {
        _controller.refreshScenes();
    }

    // Update the view
    function onUpdate(dc) {
        var previousScene = _controller.getPreviousScene();
        var activeScene = _controller.getFocusedScene();
        var nextScene = _controller.getNextScene();

        if (previousScene) {
            View.findDrawableById("PreviousScene").setText(previousScene.getName());
        } else {
            View.findDrawableById("PreviousScene").setText("");
        }
        if (activeScene) {
            View.findDrawableById("FocusedScene").setText(activeScene.getName());
        } else {
            View.findDrawableById("FocusedScene").setText("");
        }
        if (nextScene) {
            View.findDrawableById("NextScene").setText(nextScene.getName());
        } else {
            View.findDrawableById("NextScene").setText("");
        }

        View.onUpdate(dc);
    }

    function onHide() {}
}
