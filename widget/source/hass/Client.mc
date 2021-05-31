using Toybox.Communications as Comm;
using Toybox.Application as App;
using Toybox.StringUtil;
using Hass;

(:glance)
module Hass {
    const AUTH_ENDPOINT = "/auth/authorize";
    const TOKEN_ENDPOINT = "/auth/token";
(:glance)
    class Client extends Hass.OAuthClient {
        static enum {
            ENTITY_ACTION_TURN_ON,
            ENTITY_ACTION_TURN_OFF,
            ENTITY_ACTION_LOCK,
            ENTITY_ACTION_UNLOCK,
            ENTITY_ACTION_DISARM,
            ENTITY_ACTION_ARM_AWAY,
            ENTITY_ACTION_ARM_HOME,
            ENTITY_ACTION_OPEN,
            ENTITY_ACTION_CLOSE,
            ENTITY_ACTION_STOP
        }

        hidden var _baseUrl;
        hidden var _baseUrlIsValid;

        function initialize() {
            _refreshBaseUrl();

            OAuthClient.initialize({
                :authUrl => _baseUrl + AUTH_ENDPOINT,
                :tokenUrl => _baseUrl + TOKEN_ENDPOINT,
                :clientId => "https://hasscontrol",
                :redirectUrl => "https://hasscontrol/hass/auth_callback"
            });
        }

        function _refreshBaseUrl() {
            var newUrl = App.Properties.getValue("host");
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
            _refreshBaseUrl();

            OAuthClient.onSettingsChanged();

            setAuthUrl(_baseUrl + AUTH_ENDPOINT);
            setTokenUrl(_baseUrl + TOKEN_ENDPOINT);
        }

        function _validateSettings(errorCallback) {
            var error = null;

            if (!System.getDeviceSettings().phoneConnected) {
                error = new Error(OAuthError.ERROR_PHONE_NOT_CONNECTED);
            }

            if (!_baseUrlIsValid) {
                error = new RequestError(ERROR_INVALID_URL);
            }

            if (error != null && errorCallback != null) {
                errorCallback.invoke(error, null);
            }

            return error;
        }

        function getEntity(entityId, context, callback) {
            if (_validateSettings(callback) != null) {
                return;
            }

            if (context == null) {
                context = {};
            }

            if (context[:resource] == null) {
                context[:resource] = entityId;
            }

            makeAuthenticatedWebRequest(
                _baseUrl + "/api/states/" + entityId,
                {},
                {
                    :context => context
                },
                callback
            );
        }

        function setEntityState(entityId, entityType, action, callback, extraParams) {
            if (_validateSettings(callback) != null) {
                return;
            }

            var service = "scene";
            var serviceAction = "turn_on";
            var newState = "on";

            if (action == Client.ENTITY_ACTION_TURN_ON) {
                serviceAction = "turn_on";
                newState = "on";
            } else if (action == Client.ENTITY_ACTION_TURN_OFF) {
                serviceAction = "turn_off";
                newState = "off";
            } else if (action == Client.ENTITY_ACTION_LOCK) {
                serviceAction = "lock";
                newState = "locked";
            } else if (action == Client.ENTITY_ACTION_UNLOCK) {
                serviceAction = "unlock";
                newState = "unlocked";
            } else if (action == Client.ENTITY_ACTION_DISARM) {
                serviceAction = "alarm_disarm";
            } else if (action == Client.ENTITY_ACTION_ARM_AWAY) {
                serviceAction = "alarm_arm_away";
            } else if (action == Client.ENTITY_ACTION_ARM_HOME) {
                serviceAction = "alarm_arm_home";
            } else if (action == Client.ENTITY_ACTION_OPEN) {
                serviceAction = "open_cover";
            } else if (action == Client.ENTITY_ACTION_CLOSE) {
                serviceAction = "close_cover";
            } else if (action == Client.ENTITY_ACTION_STOP) {
                serviceAction = "stop_cover";
            }

            var parameters = {"entity_id" => entityId};
            if (extraParams != null) {
                parameters = extraParams;
                parameters.put("entity_id", entityId);
            }

            makeAuthenticatedWebRequest(
                _baseUrl + "/api/services/" + entityType + "/" + serviceAction,
                parameters,
                {
                    :method => Comm.HTTP_REQUEST_METHOD_POST,
                    :context => {
                        :entityId => entityId,
                        :state => newState,
                    }
                },
                callback
            );
        }

    }
}