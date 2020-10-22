using Toybox.WatchUi as Ui;

class RequestError extends Error {
    static var ERROR_NOT_FOUND = 10;
    static var ERROR_NOT_AUTHORIZED = 11;
    static var ERROR_INVALID_URL = 12;

    var code;
    var message;

    var responseCode;

    function initialize(resCode) {
        Error.initialize(resCode);

        responseCode = resCode;

        if (resCode == 401) {
            code = RequestError.ERROR_NOT_AUTHORIZED;
            message = Rez.Strings.Error_Request_NotAuthorized;
            return;
        }

        if (resCode == 404) {
            code = RequestError.ERROR_NOT_FOUND;
            message = Rez.Strings.Error_Request_NotFound;
            return;
        }

        if (resCode == RequestError.ERROR_INVALID_URL) {
            code = RequestError.ERROR_INVALID_URL;
            message = Rez.Strings.Error_Request_InvalidUrl;
            return;
        }
    }

    function toString() {
        var str = Ui.loadResource(message);
        return "RequestError: " + str + ", code=" + responseCode;
    }

    function toShortString() {
        var str = Ui.loadResource(message);
        return str;
    }
}