using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class BaseView extends Ui.View {
    hidden var _sceneController;
    hidden var _firstLoad;

    function initialize(sceneController) {
        View.initialize();
        _sceneController = sceneController;
        _firstLoad = true;
    }

    function onShow() {
    }

    // Load your resources here
    function onLayout(dc) {
        var scene = new WatchUi.Text({
            :text => "HassControl",
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_LARGE,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
        setLayout([scene]);

        App.getApp().launchSceneView();
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
    }
}