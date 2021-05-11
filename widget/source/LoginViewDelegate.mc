using Toybox.WatchUi as Ui;

/**
* LoginView
* Shows user notfication that login has to be
* done on the phone.
*/
class LoginDelegate extends Ui.BehaviorDelegate {
    hidden var _mHide;

    function initialize(methodHide) {
        BehaviorDelegate.initialize();
        _mHide = methodHide;
    }

    function onBack() {
        _mHide.invoke();
        return true;
    }
}

class LoginView extends Ui.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(dc.getWidth() /2 , dc.getHeight() / 2 - Graphics.getFontHeight(Graphics.FONT_LARGE),
                    Graphics.FONT_LARGE, Ui.loadResource(Rez.Strings.LogOnPhone), Graphics.TEXT_JUSTIFY_CENTER);
    }
}