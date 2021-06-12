using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class BaseView extends Ui.View {

    // Load your resources here
    function onLayout(dc) {        
        var text = new WatchUi.Text({
            :text => "Hass Control\nTouch to continue.",
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
        setLayout([text]);
        
        App.getApp().launchInitialView();
    }
}