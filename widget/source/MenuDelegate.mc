using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.System;

class MenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        if (item.getId().equals("logout")) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            App.getApp().logout();
            return true;
        }
        if (item.getId().equals("login")) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            App.getApp().login(null);
            return true;
        }
        if (item.getId().equals("back")) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            return true;
        }
    }
}