using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.Time;
using Hass;

/**
* ViewController shows and hides overlay views
* like error, loader, login
*/
class ViewController {
    hidden var _errorView;
    hidden var _loginView;
    hidden var _loaderActive;

    function initialize() {
        _errorView = new ErrorView();
        _loginView = new LoginView();
        _loaderActive = null;
    }

  function getSceneView() {
    var controller = new EntityListController(
      [
//      Hass.TYPE_SCENE
      ]
    );

    return [
      new EntityListView(controller),
      new EntityListDelegate(controller)
    ];
  }

  function getEntityView() {
    var controller = new EntityListController(
      [
//        Hass.TYPE_LIGHT,
//        Hass.TYPE_SWITCH,
//        Hass.TYPE_AUTOMATION,
//        Hass.TYPE_SCRIPT,
//        Hass.TYPE_LOCK
      ]
    );

    return [
      new EntityListView(controller),
      new EntityListDelegate(controller)
    ];
  }

  function pushSceneView() {
    var view = getSceneView();

    Ui.pushView(
      view[0],
      view[1],
      Ui.SLIDE_IMMEDIATE
    );
  }

  function switchSceneView() {
    var view = getSceneView();

    Ui.switchToView(
      view[0],
      view[1],
      Ui.SLIDE_IMMEDIATE
    );
  }

  function pushEntityView() {
    var view = getEntityView();

    Ui.pushView(
      view[0],
      view[1],
      Ui.SLIDE_IMMEDIATE
    );
  }

  function switchEntityView() {
    var view = getEntityView();

    Ui.switchToView(
      view[0],
      view[1],
      Ui.SLIDE_IMMEDIATE
    );
  }

  function showLoginView(show) {
    System.println("Show login? " + show);
    if (!_loginView.isActive() && show == true) {
      Ui.pushView(_loginView, new LoginDelegate(), Ui.SLIDE_IMMEDIATE);

      Ui.requestUpdate();
    }

    if (_loginView.isActive() && show == false) {
      Ui.popView(Ui.SLIDE_IMMEDIATE);

      Ui.requestUpdate();
    }

  }

    /**
    * Returns state of loader
    * Since the progress bar is not a normal view,
    * We need to work around that it doesnt have onHide and onShow
    */
    function isShowingLoader() {
        return _loaderActive != null && !_errorView.isActive() && !_loginView.isActive();
    }

    /**
    * Shows immediatelly a loader with custom msg
    * @param rezString: identifier to string from xml
    */ 
    function showLoader(rezString) {
        if (isShowingLoader()) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
        }
        _loaderActive = Time.now();
        Ui.pushView(new Ui.ProgressBar(Ui.loadResource(rezString), null), null, Ui.SLIDE_BLINK);
    }

    /**
    * Direct call to remove loader view
    */
    function _removeLoaderImmediate() {
        if (isShowingLoader()) {
            Ui.popView(Ui.SLIDE_BLINK);
        }
        _loaderActive = null;
    }

    /**
    * Calls remove loader only if some checks are passed
    */
    function removeLoader() {
        if (isShowingLoader()) {
            // if loader is about to close too soon, we need to delay it
            if (Time.now().add(new Time.Duration(-1)).lessThan(_loaderActive)) {
                var loaderTimer = new Timer.Timer();
                loaderTimer.start(method(:_removeLoaderImmediate), 500, false);
                return;
            }
        }
        _removeLoaderImmediate();
    }

  function showError(error) {
    _removeLoaderImmediate();

    var message = "Unknown Error";

    if (error instanceof Error) {
      message = error.toShortString();

      if (error.code == Error.ERROR_UNKNOWN && error.responseCode != null) {
        message += "\ncode ";
        message += error.responseCode;

        if (error instanceof Hass.OAuthError) {
          message += "\nauth ";
        }
      }

      if (error.context != null) {
        message += "\n" + error.context;
      }
    } else if (error instanceof String) {
      message = error;
    }

    if (_errorView.isActive()) {
      Ui.popView(Ui.SLIDE_IMMEDIATE);
    }

    _errorView.setMessage(message);

    Ui.pushView(_errorView, new ErrorDelegate(), Ui.SLIDE_IMMEDIATE);

    System.println(error);
    Ui.requestUpdate();
  }

  function removeError() {
    if (_errorView.isActive()) {
      Ui.popView(Ui.SLIDE_IMMEDIATE);
    }
  }
}