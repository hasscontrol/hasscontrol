using Toybox.WatchUi as Ui;

class OAuthError extends RequestError {
    static var ERROR_TOKEN_REVOKED = 21;
    static var ERROR_SERVER_NOT_REACHABLE = 22;

    var code;
    var message;
    var responseCode;

    function initialize(resCode) {
        RequestError.initialize(resCode);

        if (resCode == 400) {
            code = OAuthError.ERROR_TOKEN_REVOKED;
            message = Rez.Strings.Error_Auth_Revoked;
            return;
        }
        if (resCode == 404) {
            code = OAuthError.ERROR_SERVER_NOT_REACHABLE;
            message = Rez.Strings.Error_Auth_NotReachable;
            return;
        }
    }

    function toString() {
        var str = Ui.loadResource(message);
        return "OAuthError: " + str;
    }

    function toShortString() {
        var str = Ui.loadResource(message);
        return str;
    }
}