using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

class EntityView extends WatchUi.View {
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
        setLayout(Rez.Layouts.EntityLayout(dc));
    }

    function onShow() {
        _controller.refreshEntities();
    }

    // Update the view
    function onUpdate(dc) {
        var previousEntity = _controller.getPreviousEntity();
        var activeEntity = _controller.getFocusedEntity();
        var nextEntity = _controller.getNextEntity();

        var activeDrawable = View.findDrawableById("FocusedEntity");

        if (previousEntity != null) {
            View.findDrawableById("PreviousEntity").setText(previousEntity.getName());
        } else {
            View.findDrawableById("PreviousEntity").setText("");
        }
        if (activeEntity != null) {
            activeDrawable.setText(activeEntity.getName());
        } else {
            activeDrawable.setText("");
        }
        if (nextEntity != null) {
            View.findDrawableById("NextEntity").setText(nextEntity.getName());
        } else {
            View.findDrawableById("NextEntity").setText("");
        }

        View.onUpdate(dc);

        if (activeEntity != null) {
            var drawable = null;
            var type = activeEntity.getType();
            var state = activeEntity.getState();

            System.println(activeEntity);
            System.println(state);

            if (type == Entity.TYPE_LIGHT) {
                if (state == Entity.STATE_ON) {
                    drawable = WatchUi.loadResource(Rez.Drawables.LightOn);
                } else if (state == Entity.STATE_OFF) {
                    drawable = WatchUi.loadResource(Rez.Drawables.LightOff);
                }
            } else if (type == Entity.TYPE_SWITCH) {
                if (state == Entity.STATE_ON) {
                    drawable = WatchUi.loadResource(Rez.Drawables.SwitchOn);
                } else if (state == Entity.STATE_OFF) {
                    drawable = WatchUi.loadResource(Rez.Drawables.SwitchOff);
                }
            }

            if (drawable == null) {
                drawable = WatchUi.loadResource(Rez.Drawables.Unknown);
            }

            var drawableHeight = drawable.getHeight();
            var drawableWidth = drawable.getWidth();
            var screenHeigh = dc.getHeight();
            var screenWidth = dc.getWidth();

            var y = (screenHeigh / 2) - (drawableHeight / 2);
            var x = ((screenWidth / 100) * 12) - (drawableWidth / 2);

            dc.drawBitmap(2, y, drawable);


        }
    }

    function onHide() {}
}
