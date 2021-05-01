using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Lang;
using Hass;


class HassControlApp extends App.AppBase {
  static const SCENES_VIEW = "scenes";
  static const ENTITIES_VIEW = "entities";
  static const STORAGE_KEY_START_VIEW = "start_view";
    var viewController;
    var menu;
    var glanceEntity = null;

    function initialize() {
        AppBase.initialize();
    }

  /*
   * TODO:
   * - Flytta all strings till xml
   * - Skapa en custom meny som man kan rendera om
   * - Ta kontroll äver view hanteringen för att bli av med blinkande views
   * - try to fix glance mode
   * - glance mode refresh entity state every 10min
   * - try to reduce memory by substituing entity state dictionary with symbols and filtering ignoring some params
   * - create global module with "layout" text, icon drawing
   * - add short vibrate when send entity control request to hass
   * - try to run app without internet, is error showing?
   * - test refreshing on real watch, showing no entities imported at first
   * - add scrollbar for not circle displays
  */

  function launchInitialView() {
    var initialView = getStartView();

    if (initialView.equals(HassControlApp.ENTITIES_VIEW)) {
      return viewController.pushEntityView();
    }
    if (initialView.equals(HassControlApp.SCENES_VIEW)) {
      return viewController.pushSceneView();
    }

    return viewController.pushSceneView();
  }

    function onSettingsChanged() {
        Hass.importScenesFromSettings();
        Hass.client.onSettingsChanged();
        Ui.requestUpdate();
    }

  function logout() {
    Hass.client.logout();
  }

  function login(callback) {
    Hass.client.login(callback);
  }

  function getStartView() {
    var startView = App.Storage.getValue(HassControlApp.STORAGE_KEY_START_VIEW);

    if (startView != null && startView.equals(HassControlApp.SCENES_VIEW)) {
      return HassControlApp.SCENES_VIEW;
    } else if (startView != null && startView.equals(HassControlApp.ENTITIES_VIEW)) {
      return HassControlApp.ENTITIES_VIEW;
    }

    return HassControlApp.SCENES_VIEW;
  }

  function setStartView(newStartView) {
    if (newStartView.equals(HassControlApp.ENTITIES_VIEW)) {
      App.Storage.setValue(
        HassControlApp.STORAGE_KEY_START_VIEW,
        HassControlApp.ENTITIES_VIEW
      );
    } else if (newStartView.equals(HassControlApp.SCENES_VIEW)) {
      App.Storage.setValue(
        HassControlApp.STORAGE_KEY_START_VIEW,
        HassControlApp.SCENES_VIEW
      );
    } else {
      throw new Lang.InvalidValueException();
    }
  }
  
    function isLoggedIn() {
        return Hass.client.isLoggedIn();
    }

    function onStart(state) {
        if (System.getDeviceSettings() has :isGlanceModeEnabled) {
            glanceEntity = App.Storage.getValue("glance_entity");
        }
        Hass.initClient();
    }

    function onStop(state) {
        if (System.getDeviceSettings() has :isGlanceModeEnabled) {
            App.Storage.setValue("glance_entity", glanceEntity);
            if (System.getDeviceSettings().isGlanceModeEnabled) {
            //TODO IS UNCLEAR WHEN THIS IS TRUE
                // on devices with glance mode store only if glance mode off
                Hass.storeGroupEntities();
            }
        } else {
            // on devices without glance mode store everytime
            Hass.storeGroupEntities();
        }
    }

(:glance)
    function getGlanceView() {
        return [new AppGlance(glanceEntity)];
    }

    // Return the initial view of your application here
    function getInitialView() {
        viewController = new ViewController();
        menu = new MenuController();
    
        Hass.loadGroupEntities();
        Hass.importScenesFromSettings();
        if (isLoggedIn()) {
            Hass.refreshImportedEntities(true);
        }

        var view = null;
        var delegate = null;

        if (System.getDeviceSettings() has :isGlanceModeEnabled) {
            if (System.getDeviceSettings().isGlanceModeEnabled) {
                //IS THIS EVEN CALLED??? IF GLANCEMODEENABLED THAT LOADS DIFFERENT VIEW
                var initialView = getStartView();

                if (initialView.equals(HassControlApp.ENTITIES_VIEW)) {
                    var entityView = viewController.getEntityView();
                    view = entityView[0];
                    delegate = entityView[1];
                }
                if (initialView.equals(HassControlApp.SCENES_VIEW)) {
                    var sceneView = viewController.getSceneView();
                    view = sceneView[0];
                    delegate = sceneView[1];
                }
            }
        }

        if (view == null || delegate == null) {
            view = new BaseView();
            delegate = new BaseDelegate();
        }

        return [
            view,
            delegate
        ];
    }
}