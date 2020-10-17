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

    function onShow() {}

    // Update the view
    function onUpdate(dc) {
        var previousSceneText = _controller.getPreviousScene();
        var activeSceneText = _controller.getFocusedScene();
        var nextSceneText = _controller.getNextScene();

        if (previousSceneText) {
            View.findDrawableById("PreviousScene").setText(previousSceneText);
        } else {
            View.findDrawableById("PreviousScene").setText("");
        }
        if (activeSceneText) {
            View.findDrawableById("FocusedScene").setText(activeSceneText);
        } else {
            View.findDrawableById("FocusedScene").setText("");
        }
        if (nextSceneText) {
            View.findDrawableById("NextScene").setText(nextSceneText);
        } else {
            View.findDrawableById("NextScene").setText("");
        }

        View.onUpdate(dc);
    }

    function onHide() {}
}
