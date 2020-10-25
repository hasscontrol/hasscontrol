using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Time;

class SceneDelegate extends Ui.BehaviorDelegate {
    hidden var _controller;

    function initialize(controller) {
        BehaviorDelegate.initialize();
        _controller = controller;
    }

    function onMenu() {
        App.getApp().menu.showRootMenu();
        // var menu = new Ui.Menu2({:title=>"HassControl"});
        // var delegate;

        // var isLoggedIn = App.getApp().isLoggedIn();

        // if (isLoggedIn) {
        //     menu.addItem(
        //         new MenuItem(
        //             "Logout",
        //             "",
        //             "logout",
        //             {}
        //         )
        //     );
        // } else {
        //     menu.addItem(
        //         new MenuItem(
        //             "Login",
        //             "",
        //             "login",
        //             {}
        //         )
        //     );
        // }
        // // menu.addItem(
        // //     new MenuItem(
        // //         "Refresh Entities",
        // //         "",
        // //         "refresh",
        // //         {}
        // //     )
        // // );
        // menu.addItem(
        //     new MenuItem(
        //         "Back",
        //         "",
        //         "back",
        //         {}
        //     )
        // );
        // delegate = new MenuDelegate();
        // Ui.pushView(menu, delegate, Ui.SLIDE_IMMEDIATE);
        // // System.println("Menu clicked!");

        return false;
    }

    function onNextPage() {
        _controller.focusNextScene();
        Ui.requestUpdate();
        return true;
    }

    function onPreviousPage() {
        _controller.focusPreviousScene();
        Ui.requestUpdate();
        return true;
    }

    function onSelect() {
        _controller.activateFocusedScene();
        return true;
    }
}