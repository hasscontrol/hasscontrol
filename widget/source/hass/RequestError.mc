using Toybox.WatchUi as Ui;
using Toybox.System;

(:glance)
module Hass {
    class RequestError extends Error {
        var code;
        var message;

        var responseCode;

        function initialize(resCode) {
            Error.initialize(resCode);

            responseCode = resCode;

            if (resCode == 401) {
                code = ERROR_NOT_AUTHORIZED;
                message = Rez.Strings.Error_Request_NotAuthorized;
                return;
            }

            if (resCode == 404) {
                code = ERROR_NOT_FOUND;
                message = Rez.Strings.Error_Request_NotFound;
                return;
            }

            if (resCode == ERROR_INVALID_URL) {
                code = ERROR_INVALID_URL;
                message = Rez.Strings.Error_Request_InvalidUrl;
                return;
            }
        }

        function toString() {
            var str = Ui.loadResource(message);
            var string = "RequestError: " + str + ", code=" + responseCode;

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
}