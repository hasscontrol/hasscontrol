using Toybox.Application as App;
using Toybox.System as System;
using Toybox.WatchUi as Ui;
using Hass;

/**
* General delegate for menu with its various submenus
*/
class MenuDelegate extends Ui.Menu2InputDelegate {
    hidden var parentMenuItem;

    function initialize(p) {
        Menu2InputDelegate.initialize();
        parentMenuItem = p;
    }

    function onSelect(item) {
        var itemId = item.getId();

        if (itemId == ControlMenu.MENU_SWITCH_TO_ENTITIES) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);

            var viewDeleg = App.getApp().viewController.getMainViewDelegate(HassControlApp.ENTITIES_VIEW);
            Ui.switchToView(viewDeleg[0], viewDeleg[1], Ui.SLIDE_IMMEDIATE);
            return true;
        }
        if (itemId == ControlMenu.MENU_SWITCH_TO_SCENES) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);

            var viewDeleg = App.getApp().viewController.getMainViewDelegate(HassControlApp.SCENES_VIEW);
            Ui.switchToView(viewDeleg[0], viewDeleg[1], Ui.SLIDE_IMMEDIATE);
            return true;
        }
        if (itemId == ControlMenu.MENU_LOGOUT) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            App.getApp().logout();
            return true;
        }
        if (itemId == ControlMenu.MENU_LOGIN) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            App.getApp().login(null);
            return true;
        }
        if (itemId == ControlMenu.MENU_ENTER_SETTINGS) {
            ControlMenu.showSettingsMenu();
            return true;
        }
        /* Submenu SETTINGS */
        if (itemId == ControlMenu.MENU_SELECT_START_VIEW) {
            ControlMenu.showSelectStartViewMenu(item);
            return true;
        }
        if (itemId == ControlMenu.MENU_REFRESH_ENTITIES) {
            Hass.importGroupEntities();
            return true;
        }
        if (itemId == ControlMenu.MENU_SET_GLANCE_ENTITY) {
            if (Hass.getImportedEntities().size() < 1) {
                return false;
            }
            ControlMenu.showSelectGlanceEntity(item);
            return true;
        }

        if (itemId == ControlMenu.MENU_SELECT_START_VIEW_ENTITIES) {
            App.Storage.setValue(HassControlApp.STORAGE_KEY_START_VIEW, HassControlApp.ENTITIES_VIEW);

            parentMenuItem.setSubLabel(HassControlApp.ENTITIES_VIEW);
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            return true;
        }
        if (itemId == ControlMenu.MENU_SELECT_START_VIEW_SCENES) {
            App.Storage.setValue(HassControlApp.STORAGE_KEY_START_VIEW, HassControlApp.SCENES_VIEW);

            parentMenuItem.setSubLabel(HassControlApp.SCENES_VIEW);
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            return true;
        }

        /*
        * GLOBAL MENU OPTIONS
        */
        if (itemId == ControlMenu.MENU_BACK) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            return true;
        }

        return false;
    }
}

/**
* Delegate for glance submenu
* Used for choosing entity which will be shown on glance view
*/
class SubmenuGlanceDelegate extends Ui.Menu2InputDelegate {
    hidden var parentMenuItem;

    function initialize(p) {
        Menu2InputDelegate.initialize();
        parentMenuItem = p;
    }

    function onSelect(item) {
        var itemId = item.getId();
        App.getApp().glanceEntity = itemId;
        App.Storage.setValue("glance_entity", itemId);

        parentMenuItem.setSubLabel(itemId);
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        return true;
    }
}

/**
* Control Menu module
*/
module ControlMenu {
    enum {
        MENU_SWITCH_TO_SCENES,
        MENU_SWITCH_TO_ENTITIES,
        MENU_ENTER_SETTINGS,
        MENU_LOGIN,
        MENU_SELECT_START_VIEW,
        MENU_REFRESH_ENTITIES,
        MENU_SET_GLANCE_ENTITY,
        MENU_LOGOUT,
        MENU_SELECT_START_VIEW_ENTITIES,
        MENU_SELECT_START_VIEW_SCENES,
        MENU_BACK
    }

    /**
    * Shows root menu
    */
    function showRootMenu() {
        var menu = new Ui.Menu2({
            :title => Ui.loadResource(Rez.Strings.AppName)
        });

        if (App.getApp().isLoggedIn()) {
            menu.addItem(new Ui.MenuItem(
                Ui.loadResource(Rez.Strings.Scenes),
                null,
                ControlMenu.MENU_SWITCH_TO_SCENES,
                null
            ));
            menu.addItem(new Ui.MenuItem(
                Ui.loadResource(Rez.Strings.Entities),
                null,
                ControlMenu.MENU_SWITCH_TO_ENTITIES,
                null
            ));
            menu.addItem(new Ui.MenuItem(
                Ui.loadResource(Rez.Strings.Settings),
                null,
                ControlMenu.MENU_ENTER_SETTINGS,
                null
            ));
        } else {
            menu.addItem(new Ui.MenuItem(
                Ui.loadResource(Rez.Strings.Login),
                null,
                ControlMenu.MENU_LOGIN,
                null
            ));
        }

        return Ui.pushView(menu, new MenuDelegate(null), Ui.SLIDE_IMMEDIATE);
        }

    /**
    * Shows settings submenu
    */
    function showSettingsMenu() {
        var menu = new Ui.Menu2({
            :title => Ui.loadResource(Rez.Strings.Settings)
        });

        menu.addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.StartView),
            App.getApp().getStartView(),
            ControlMenu.MENU_SELECT_START_VIEW,
            null
        ));
        menu.addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.RefreshEntities),
            Hass.getGroup(),
            ControlMenu.MENU_REFRESH_ENTITIES,
            null
        ));
        if (System.getDeviceSettings() has :isGlanceModeEnabled) {
            menu.addItem(new Ui.MenuItem(
                Ui.loadResource(Rez.Strings.MenuGlanceEntity),
                Hass.getImportedEntities().size() > 0 ? (App.getApp().glanceEntity == null ? Ui.loadResource(Rez.Strings.MenuNoEntities) : App.getApp().glanceEntity) : Ui.loadResource(Rez.Strings.MenuNoEntities),
                ControlMenu.MENU_SET_GLANCE_ENTITY,
                null
            ));
        }
        menu.addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.Logout),
            null,
            ControlMenu.MENU_LOGOUT,
            null
        ));

        Ui.pushView(menu, new MenuDelegate(null), Ui.SLIDE_IMMEDIATE);
    }

    /**
    * Shows subsubmenu settings -> select start view
    */
    function showSelectStartViewMenu(parentMenuItem) {
        var menu = new Ui.Menu2({
            :title => Ui.loadResource(Rez.Strings.StartView)
        });

        var currentStartView = App.getApp().getStartView();
        var entitiesSubtitle = null;
        var scenesSubtitle = null;

        if (currentStartView == HassControlApp.SCENES_VIEW) {
            scenesSubtitle = Ui.loadResource(Rez.Strings.Selected);
        }

        if (currentStartView == HassControlApp.ENTITIES_VIEW) {
            entitiesSubtitle = Ui.loadResource(Rez.Strings.Selected);
        }

        menu.addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.Entities),
            entitiesSubtitle,
            ControlMenu.MENU_SELECT_START_VIEW_ENTITIES,
            null
        ));

        menu.addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.Scenes),
            scenesSubtitle,
            ControlMenu.MENU_SELECT_START_VIEW_SCENES,
            null
        ));

        menu.addItem(new Ui.MenuItem(
            Ui.loadResource(Rez.Strings.Back),
            null,
            ControlMenu.MENU_BACK,
            null
        ));

        Ui.pushView(menu, new MenuDelegate(parentMenuItem), Ui.SLIDE_IMMEDIATE);
    }

    /**
    * Shows subsubmenu settings -> select glance entity
    */
    function showSelectGlanceEntity(parentMenuItem) {
        var glanceMenu = new Ui.Menu2({
            :title => Ui.loadResource(Rez.Strings.MenuGlanceEntity)
        });

        var impEnt = Hass.getImportedEntities();
        for (var i = 0; i < impEnt.size(); i++) {
            glanceMenu.addItem(new Ui.MenuItem(
            impEnt[i],
            impEnt[i].equals(App.getApp().glanceEntity) ? Ui.loadResource(Rez.Strings.Selected) : null,
            impEnt[i],
            null
        ));
        }

        Ui.pushView(glanceMenu, new SubmenuGlanceDelegate(parentMenuItem), Ui.SLIDE_IMMEDIATE);
    }
}