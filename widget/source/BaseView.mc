using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class BaseView extends Ui.View {
    hidden var _firstLoad;

    function initialize() {
        View.initialize();
        _firstLoad = true;
    }

    function onShow() {
    }

    // Load your resources here
    function onLayout(dc) {
        var scene = new Ui.Text({
            :text => "HassControl",
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_LARGE,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
        setLayout([scene]);
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
    }
}