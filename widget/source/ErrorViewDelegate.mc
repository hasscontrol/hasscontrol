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

class ErrorView extends Ui.View {
    hidden var _message;
    
    function initialize(message) {
        View.initialize();
        _message = message;
    }

    function onUpdate(dc) {
        var vw = dc.getWidth();
    	var vh = dc.getHeight();
 
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(vw /2 , vh * 0.25, Graphics.FONT_LARGE, Ui.loadResource(Rez.Strings.ErrTitle), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(vw /2 , vh * 0.45, Graphics.FONT_LARGE, _message, Graphics.TEXT_JUSTIFY_CENTER);
    }
}