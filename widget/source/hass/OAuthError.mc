using Toybox.WatchUi as Ui;

(:glance)
module Hass {
    class OAuthError extends RequestError {
        var code;
        var message;
        var responseCode;

        function initialize(resCode) {
            RequestError.initialize(resCode);

            if (resCode == 400) {
                code = ERROR_TOKEN_REVOKED;
                message = Rez.Strings.Error_Auth_Revoked;
                return;
            }
            if (resCode == 404) {
                code = ERROR_SERVER_NOT_REACHABLE;
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
}