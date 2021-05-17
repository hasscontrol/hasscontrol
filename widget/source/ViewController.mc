using Toybox.Attention as Attention;
using Toybox.Timer;
using Toybox.Time;
using Toybox.WatchUi as Ui;
using Hass;

/**
* ViewController shows and hides overlay views
* like error, loader, login
*/
class ViewController {
    hidden var _errorViewActive;
    hidden var _loginViewActive;
    hidden var _loaderActive;

    function initialize() {
        _errorViewActive = false;
        _loginViewActive = false;
        _loaderActive = null;
    }

    function getSceneView() {
        var controller = new EntityListController([Hass.ENTITY_TYPE_SCENE]);

        return [
            new EntityListView(controller),
            new EntityListDelegate(controller)
        ];
    }

    function getEntityView() {
        var controller = new EntityListController([
            Hass.ENTITY_TYPE_ALARM_PANEL,
            Hass.ENTITY_TYPE_AUTOMATION,
            Hass.ENTITY_TYPE_BINARY_SENSOR,
            Hass.ENTITY_TYPE_COVER,
            Hass.ENTITY_TYPE_INPUT_BOOLEAN,
            Hass.ENTITY_TYPE_LIGHT,
            Hass.ENTITY_TYPE_LOCK,
            Hass.ENTITY_TYPE_SCRIPT,
            Hass.ENTITY_TYPE_SENSOR,
            Hass.ENTITY_TYPE_SWITCH]);

        return [
            new EntityListView(controller),
            new EntityListDelegate(controller)
        ];
    }

    /**
    * Returns view and delegate of main view
    */
    function getMainViewDelegate(viewId) {
        var view = getSceneView();
        if (viewId.equals(HassControlApp.ENTITIES_VIEW)) {
            view = getEntityView();
        }

        return view;
    }

    /**
    * Shows login on phone view
    */
    function showLoginView() {
        Ui.pushView(new LoginView(), new LoginDelegate(method(:removeLoginView)), Ui.SLIDE_IMMEDIATE);
        _loginViewActive = true;
    }

    /**
    * Removes login on phone view
    */
    function removeLoginView() {
        if (_loginViewActive) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
        }
        _loginViewActive = false;
    }

    /**
    * Returns state of loader
    * Since the progress bar is not a normal view,
    * We need to work around that it doesnt have onHide and onShow
    */
    function isShowingLoader() {
        return _loaderActive != null && !_errorViewActive && !_loginViewActive;
    }

    /**
    * Shows immediatelly a loader with custom msg
    * if device supports vibration, executes short puls
    * @param rezString: identifier to string from xml
    */
    function showLoader(rezString) {
        if (isShowingLoader()) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
        }
        _loaderActive = Time.now();
        Ui.pushView(new Ui.ProgressBar(Ui.loadResource(rezString), null), null, Ui.SLIDE_BLINK);
        if (Attention has :vibrate) {Attention.vibrate([new Attention.VibeProfile(50, 100)]);}
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

    /**
    * Shows error view
    * @param error: error class object or simple string
    */
    function showError(error) {
        _removeLoaderImmediate();
        var message = Ui.loadResource(Rez.Strings.ErrUnknown);

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

        System.println(error);

        if (_errorViewActive) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
        }

        Ui.pushView(new ErrorView(message), new ErrorDelegate(), Ui.SLIDE_IMMEDIATE);
        _errorViewActive = true;
    }

    /**
    * Removes error view
    */
    function removeError() {
        if (_errorViewActive) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
        }
        _errorViewActive = false;
    }
}