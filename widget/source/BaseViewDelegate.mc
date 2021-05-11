using Toybox.Application as App;
using Toybox.WatchUi as Ui;

/**
* BaseViewDelegate
* This is the first showed view after the widget is started.
* Because its not possible to scroll up or down on this view,
* we have to use it as transition to the real view.
*/
class BaseDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        App.getApp().launchInitialView();
    }
}

class BaseView extends Ui.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(dc.getWidth() /2 , dc.getHeight() / 2 - Graphics.getFontHeight(Graphics.FONT_LARGE) / 2,
                    Graphics.FONT_LARGE, Ui.loadResource(Rez.Strings.AppName), Graphics.TEXT_JUSTIFY_CENTER);
    }
}