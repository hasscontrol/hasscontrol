using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;

class HassClient {
    hidden var _hassUrl;
    hidden var _hostIsValid;
    hidden var _auth;
    hidden var _sceneToActivate;
    hidden var _callbacks;

    static var ERROR_UNKNOWN = 0;
    static var ERROR_SERVER_NOT_REACHABLE = 1;
    static var ERROR_NOT_AUTHORIZED = 2;
    static var ERROR_RESOURCE_NOT_FOUND = 3;
    static var ERROR_TOKEN_REVOKED = 4;
    static var ERROR_PHONE_NOT_CONNECTED = 5;
    static var ERROR_INVALID_HOST = 6;

    static var REQUEST_TYPE_ACTIVATE_SCENE = "activateScene";

    function initialize() {
        _hassUrl = Application.Properties.getValue("host");
        _hostIsValid = false;

        _auth = new HassAuthClient(_hassUrl);
        _sceneToActivate = null;

        _callbacks = {
            "activateScene" => null
        };
    }

    function _addCallback(type, callback) {
        _callbacks[type] = callback;
    }

    function _addErrorCallback(type, callback) {
        _callbacks[type] = callback;
    }

    function onSettingsChanged() {
        var host = Application.Properties.getValue("host");

        var chars = host.toCharArray();

        // strip potential trailing slash
        if (chars[chars.size() - 1] == '/') {
            chars = chars.slice(0, chars.size() - 1);
        }

        // verify that host is starting with "https://"
        if (StringUtil.charArrayToString(chars.slice(0, 8)).equals("https://")) {
            _hostIsValid = true;
        } else {
            _hostIsValid = false;
        }

        System.println("Setting new host url: " + _hassUrl);

        _hassUrl = StringUtil.charArrayToString(chars);

        _auth.setHost(_hassUrl);
    }

    function onRequestCompleted(responseCode, data, context) {
        var error = null;

        if (responseCode == 401) {
            error = { "errorCode" => ERROR_NOT_AUTHORIZED };
            _auth.setAccessToken(null);
            _auth.setExpires(null);
        } else if (responseCode == 404 && data != null) {
            error = { "errorCode" => ERROR_RESOURCE_NOT_FOUND };
        } else if (responseCode == 404) {
            error = { "errorCode" => ERROR_SERVER_NOT_REACHABLE };
        } else if (responseCode != 200) {
            error = { "errorCode" => ERROR_UNKNOWN };
        }

        if (error != null) {
            error["responseCode"] = responseCode;
            error["type"] = context["type"];
            System.println("Failed to complete request, status " + responseCode);
        }

        context["cb"].invoke(error, data);
    }

    function doActivateScenes(callback) {
        if (_sceneToActivate == null) {
            return;
        }

        var url = _hassUrl + "/api/services/scene/turn_on";

        var accessToken = _auth.getAccessToken();

        var params = {
            "entity_id" => "scene." + _sceneToActivate
        };
        System.println("Send activate scene request");
        Comm.makeWebRequest(
            url,
            params,
            {
                :method => Comm.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + accessToken
                },
                :context => {
                    "cb" => callback,
                    "type" => REQUEST_TYPE_ACTIVATE_SCENE
                }
            },
            method(:onRequestCompleted)
        );
    }

    function onAuthComplete(err, context) {
        if (err != null) {
            var error = { "errorCode" => ERROR_UNKNOWN };

            if (err["errorCode"] == HassAuthClient.ERROR_SERVER_NOT_REACHABLE) {
                error = { "errorCode" => ERROR_SERVER_NOT_REACHABLE };
            } else if (err["errorCode"] == HassAuthClient.ERROR_NOT_AUTHORIZED) {
                error = { "errorCode" => ERROR_NOT_AUTHORIZED };
            } else if (err["errorCode"] == HassAuthClient.ERROR_TOKEN_REVOKED) {
                error = { "errorCode" => ERROR_TOKEN_REVOKED };
            }

            error["responseCode"] = err["responseCode"];
            error["type"] = err["type"];


            context["cb"].invoke(error, null);

            return;
        }

        context["fn"].invoke(context["cb"]);
    }

    function activateScene(sceneId, cb) {
        _sceneToActivate = sceneId;

        if (!System.getDeviceSettings().phoneConnected) {
            var error = {
                "errorCode" => ERROR_PHONE_NOT_CONNECTED,
                "responseCode" => null,
                "type" => REQUEST_TYPE_ACTIVATE_SCENE
            };
            cb.invoke(error, null);

            return;
        }

        if (!_hostIsValid) {
            var error = {
                "errorCode" => ERROR_INVALID_HOST,
                "responseCode" => null,
                "type" => REQUEST_TYPE_ACTIVATE_SCENE
            };
            cb.invoke(error, null);

            return;
        }

        _auth.addTokenCallback(method(:onAuthComplete), {
            "fn" => method(:doActivateScenes),
            "cb" => cb
        });

        _auth.refreshToken(false);
    }
}
