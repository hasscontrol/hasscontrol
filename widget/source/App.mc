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
    var glanceEntity;

    function initialize() {
        AppBase.initialize();
    }

  /*
   * TODO:
   * - Flytta all strings till xml
   * - Skapa en custom meny som man kan rendera om
   * - Ta kontroll äver view hanteringen för att bli av med blinkande views
   * - try to fix glance mode
   * - try to reduce memory by substituing entity state dictionary with symbols and filtering ignoring some params
   * - try to run app without internet, is error showing?
   * - periodically refresh entities
   * - add action to entity type light (brightness)
  */

    /**
    * Launches initial, entity list, view
    */
    function launchInitialView() {
        var viewDelegate = self.viewController.getMainViewDelegate(getStartView());
        Ui.pushView(viewDelegate[0], viewDelegate[1], Ui.SLIDE_IMMEDIATE);
        return true;
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

    /**
    * Loads stored start view from storage
    */
    function getStartView() {
        var storedStartView = App.Storage.getValue(HassControlApp.STORAGE_KEY_START_VIEW);
        var startView = HassControlApp.SCENES_VIEW;

        if (storedStartView == null) {return startView;}

        if (storedStartView.equals(HassControlApp.ENTITIES_VIEW)) {
            startView = HassControlApp.ENTITIES_VIEW;
        }

        return startView;
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
        Hass.storeGroupEntities();
    }

(:glance)
    function getGlanceView() {
        return [new AppGlance(glanceEntity)];
    }

    /**
    * Returns the initial full view of the widget.
    * On devices with glance mode on jumps directly
    * into entity list view, otherwise loads transition page.
    */
    function getInitialView() {
        self.viewController = new ViewController();

        Hass.loadGroupEntities();
        Hass.importScenesFromSettings();
        if (isLoggedIn()) {
            Hass.refreshImportedEntities(true);
        }

        var view = new BaseView();
        var delegate = new BaseDelegate();

        if (System.getDeviceSettings() has :isGlanceModeEnabled && System.getDeviceSettings().isGlanceModeEnabled) {
            var viewDelegate = self.viewController.getMainViewDelegate(getStartView());
            view = viewDelegate[0];
            delegate = viewDelegate[1];
        }

        return [view, delegate];
    }
}