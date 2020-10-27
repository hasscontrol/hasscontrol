using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;


class HassControlApp extends App.AppBase {
  static const SCENES_VIEW = "scenes";
  static const ENTITIES_VIEW = "entities";
  static const STORAGE_KEY_START_VIEW = "start_view";

  var hassClient;
  var hassController;
  var viewController;
  var menu;

  function initialize() {
    AppBase.initialize();
  }

  /*
   * TODO:
   * - glance view = base view
   * - Initiera saker i onAppStart som inte behövs i glance view
   * - Flytta all strings till xml
   * - Skapa en custom meny som man kan rendera om
   * - Ta kontroll äver view hanteringen för att bli av med blinkande views
   *
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
    hassClient.onSettingsChanged();
    hassController.loadEntities();

    viewController.refresh();

    Ui.requestUpdate();
  }

  function logout() {
    hassClient.logout();
  }

  function login(callback) {
    hassClient.login(callback);
  }

  function getStartView() {
    var startView = App.Storage.getValue(HassControlApp.STORAGE_KEY_START_VIEW);
    System.println("loaded startview: " + startView);
    if (startView == null && startView.equals(HassControlApp.SCENES_VIEW)) {
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
      throw new InvalidValueException("unknown start view");
    }
  }

  function isLoggedIn() {
    return hassClient.isLoggedIn();
  }

  function onStart(state) {}

  function onStop(state) {}


  function getGlanceView() {
    return [
      new AppGlance()
    ];
  }

  // Return the initial view of your application here
  function getInitialView() {
    hassClient = new HassClient();
    hassController = new HassController(hassClient);
    viewController = new ViewController(hassController);
    menu = new MenuController();

    return [
      new BaseView(),
      new BaseDelegate()
    ];
  }
}