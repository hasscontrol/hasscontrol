using Toybox.Communications as Comm;

const AUTH_ENDPOINT = "/auth/authorize";
const TOKEN_ENDPOINT = "/auth/token";

class HassClient extends OAuthClient {
    hidden var _baseUrl;
    hidden var _baseUrlIsValid;

    function initialize() {
        refreshBaseUrl();

        OAuthClient.initialize({
            :authUrl => _baseUrl + AUTH_ENDPOINT,
            :tokenUrl => _baseUrl + TOKEN_ENDPOINT,
            :clientId => "https://hasscontrol",
            :redirectUrl => "https://hasscontrol/hass/auth_callback"
        });
    }

    function refreshBaseUrl() {
        var newUrl = Application.Properties.getValue("host");
        var chars = newUrl.toCharArray();

        if (chars.size() < 8) {
            _baseUrlIsValid = false;
            return;
        }

        // strip potential trailing slash
        if (chars[chars.size() - 1] == '/') {
            chars = chars.slice(0, chars.size() - 1);
        }

        // verify that host is starting with "https://"
        if (StringUtil.charArrayToString(chars.slice(0, 8)).equals("https://")) {
            _baseUrlIsValid = true;
        } else {
            _baseUrlIsValid = false;
        }

        _baseUrl = StringUtil.charArrayToString(chars);
    }

    function onSettingsChanged() {
        refreshBaseUrl();

        setAuthUrl(_baseUrl + AUTH_ENDPOINT);
        setTokenUrl(_baseUrl + TOKEN_ENDPOINT);
    }

    function validateSettings(errorCallback) {
        var error = null;

        if (!System.getDeviceSettings().phoneConnected) {
            error = new Error(OAuthError.ERROR_PHONE_NOT_CONNECTED);
        }

        if (!_baseUrlIsValid) {
            error = new RequestError(RequestError.ERROR_INVALID_URL);
        }

        if (error != null && errorCallback != null) {
            errorCallback.invoke(error, null);
        }

        return error;
    }


    function activateScene(sceneId, callback) {
        if (validateSettings(callback) != null) {
            return;
        }

        System.println("Send activate scene request");

        makeAuthenticatedWebRequest(
            _baseUrl + "/api/services/scene/turn_on",
            {
                "entity_id" => "scene." + sceneId
            },
            {
                :method => Comm.HTTP_REQUEST_METHOD_POST
            },
            callback
        );
    }

    function getEntity(entityId, callback) {
        if (validateSettings(callback) != null) {
            return;
        }

        makeAuthenticatedWebRequest(
            _baseUrl + "/api/states/" + entityId,
            {},
            {},
            callback
        );
    }

}