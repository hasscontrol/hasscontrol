using Toybox.WatchUi as Ui;

class Error {
    static var ERROR_UNKNOWN = 0;
    static var ERROR_PHONE_NOT_CONNECTED = 1;

    var code;
    var message;
    var context;

    function initialize(errorCode) {
        if (errorCode == Error.ERROR_PHONE_NOT_CONNECTED) {
            code = Error.ERROR_PHONE_NOT_CONNECTED;
            message = Rez.Strings.Error_PhoneNotConnected;
            return;
        }

        code = OAuthError.ERROR_UNKNOWN;
        message = Rez.Strings.Error_Unknown;
        context = null;
    }

    function setContext(ctx) {
        context = ctx;
    }

    function toString() {
        var str = Ui.loadResource(message);
        var string = "Error: " + str;

        if (context != null) {
            string += " ctx=" + context;
        }
        return string;
    }

    function toShortString() {
        var str = Ui.loadResource(message);
        return str;
    }
}