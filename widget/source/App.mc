using Toybox.Application;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;

class App extends Application.AppBase {
  var hassClient;
  var sceneController;
  var viewController;
  hidden var _sceneView;
  hidden var _sceneDelegate;

  function initialize() {
    AppBase.initialize();
    hassClient = new HassClient();
    sceneController = new SceneController(hassClient);
    viewController = new ViewController();
    _sceneView = new SceneView(sceneController);
    _sceneDelegate = new SceneDelegate(sceneController);
  }

  /*
   * TODO:
   * - ny logga
   * - glance view = base view
   * - Konvertera error response till en klass
   * - Meny med logga ut
   *
  */

  function launchSceneView() {
    Ui.pushView(
        _sceneView,
        _sceneDelegate,
        Ui.SLIDE_IMMEDIATE
    );
  }

  function onSettingsChanged() {
    hassClient.onSettingsChanged();
    sceneController.onSettingsChanged();

    Ui.requestUpdate();
  }

  function logout() {
    hassClient.logout();
  }

  function login(callback) {
    hassClient.login(callback);
  }

  function isLoggedIn() {
    return hassClient.isLoggedIn();
  }

  function onStart(state) {}

  function onStop(state) {}

  // Return the initial view of your application here
  function getInitialView() {
    return [
      new BaseView(sceneController),
      new BaseDelegate()
    ];
  }
}