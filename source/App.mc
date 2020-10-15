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

  // TODO: Check if app is connected
  // TODO: Show login window

  function launchSceneView() {
    Ui.pushView(
        _sceneView,
        _sceneDelegate,
        Ui.SLIDE_IMMEDIATE
    );
  }

  function onStart(state) {}

  // onStop() is called when your application is exiting
  function onStop(state) {

  }

  // Return the initial view of your application here
  function getInitialView() {
    return [
      new BaseView(sceneController),
      new BaseDelegate()
    ];
  }
}