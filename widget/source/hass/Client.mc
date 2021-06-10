using Toybox.Communications as Comm;
using Toybox.Application as App;
using Toybox.StringUtil;
using Toybox.Time;

(:glance)
module Hass {
    class Client {
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
        hidden var _tokenCallbacks;

        hidden var _isLoggingIn;
        hidden var _isFetchingAccessToken;

        hidden var _refreshToken;
        hidden var _accessToken;
        hidden var _expires;
        hidden var _fixedAccessToken;

        hidden var _baseUrl;
        hidden var _baseUrlIsValid;

        function initialize() {
            Comm.registerForOAuthMessages(method(:_onReceivedAuthCode));

            _tokenCallbacks = new [0];
            _isLoggingIn = false;
            _isFetchingAccessToken = false;
            _fixedAccessToken = false;
            me.onSettingsChanged();
        }

        function onSettingsChanged() {
            var accessToken;
            var chars;
            var newUrl;
            var newBaseUrl;

            /* extracted refreshBaseUrl() */
            // verify that host is starting with "https://", this also checks its length
            newUrl = App.Properties.getValue("host");
            if (newUrl.substring(0,8).equals("https://")) {
                chars = newUrl.toCharArray();
                if (chars[chars.size() - 1] == '/') {
                    chars = chars.slice(0, chars.size() - 1);
                }
                newBaseUrl = StringUtil.charArrayToString(chars);

                _baseUrlIsValid = true;
            } else {
                _baseUrlIsValid = false;
                return;
            }
            /* end refreshBaseUrl() */

            if (!newBaseUrl.equals(_baseUrl)) {
                if (_baseUrl != null) {logout();}
                _baseUrl = newBaseUrl;
            }

            /* extracted loadLongLivedToken() */
            accessToken = App.Properties.getValue("accessToken");
            if (accessToken.length() > 0 ) {
                _fixedAccessToken = true;
                _accessToken = accessToken;
            } else {
                _fixedAccessToken = false;
                _accessToken = null;
            }
            /* end loadLongLivedToken() */
        }

        function _fireTokenCallbacks(error) {
            for( var i = 0; i < _tokenCallbacks.size(); i++ ) {
                var callbackObject = _tokenCallbacks[i];

                callbackObject[:callback].invoke(error, callbackObject[:context]);

                _tokenCallbacks.remove(callbackObject);
            }
        }

        function _setIsLoggingIn(isLoggingIn) {
            _isLoggingIn = isLoggingIn;
            if (isLoggingIn) {
                App.getApp().viewController.showLoginView();
            } else {
                App.getApp().viewController.removeLoginView();
            }
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

        /**
        * Checks if user is successfully done login process
        * or is using long lived token
        */
        function isLoggedIn() {
            if (_fixedAccessToken == true || getRefreshToken() != null) {
                return true;
            }

            return false;
        }

        /**
        * Callback when both or only access token is returened from HASS
        */
        function _onReceivedTokens(code, data) {
            _setIsLoggingIn(false);

            _isFetchingAccessToken = false;

            if (code == 200) {
                setAccessTokenExpiration(data["expires_in"]);
                setAccessToken(data["access_token"]);

                if (data["refresh_token"]) {
                    setRefreshToken(data["refresh_token"]);
                }

                _fireTokenCallbacks(null);
            } else {
                var error = new OAuthError(code);

                if (error.code == ERROR_TOKEN_REVOKED) {
                    logout();
                }

                _fireTokenCallbacks(error);
            }
        }

        /**
        * Request access token using refresh token
        */
        function refreshAccessToken() {
            if (_isLoggingIn) {
                return;
            }

            if (isLoggedIn() == false) {
                login();
                return;
            }

            if (_isFetchingAccessToken == true) {
                return;
            }

            if (isAccessTokenExpired() == true) {
                var refreshToken = getRefreshToken();

                _isFetchingAccessToken = true;
                Comm.makeWebRequest(
                    _baseUrl + "/auth/token",
                    {
                        "client_id" => "https://hasscontrol",
                        "grant_type" => "refresh_token",
                        "refresh_token" => refreshToken
                    },
                    {
                        :method => Comm.HTTP_REQUEST_METHOD_POST
                    },
                    method(:_onReceivedTokens)
                );
            } else {
                _fireTokenCallbacks(null);
            }
        }

        /**
        * Request access and refresh tokens from HASS using authorization code
        */
        function _getTokensUsingCode(code) {
            if (_isFetchingAccessToken != true) {
                _isFetchingAccessToken = true;

                Comm.makeWebRequest(
                    _baseUrl + "/auth/token",
                    {
                        "client_id" => "https://hasscontrol",
                        "code" => code,
                        "grant_type" => "authorization_code"

                    },
                    {
                        :method => Comm.HTTP_REQUEST_METHOD_POST
                    },
                    method(:_onReceivedTokens)
                );
            }
        }

        /**
        * Callback when OAuth response from HASS is received
        */
        function _onReceivedAuthCode(value) {
            if (value.data["code"] != null) {
                _getTokensUsingCode(value.data["code"]);
            } else {
                var error = new OAuthError(value.responseCode);

                _setIsLoggingIn(false);

                _fireTokenCallbacks(error);
            }
        }

        /**
        * Login into HASS
        */
        function login() {
            if (isLoggedIn() == true) {
                refreshAccessToken();
                return;
            }

            _setIsLoggingIn(true);

            if (!System.getDeviceSettings().phoneConnected) {
                var error = new OAuthError(OAuthError.ERROR_PHONE_NOT_CONNECTED);

                _fireTokenCallbacks(error);

                return;
            }

            Comm.makeOAuthRequest(
                _baseUrl + "/auth/authorize",
                {
                    "client_id" => "https://hasscontrol",
                    "redirect_uri"=> "https://hasscontrol/hass/auth_callback"
                },
                "https://hasscontrol/hass/auth_callback",
                Comm.OAUTH_RESULT_TYPE_URL,
                {"code"=>"code"}
            );
        }

        /**
        * Resets both tokens and revokes the refresh token in HASS
        */
        function logout() {
            if (_fixedAccessToken == false) {
                Comm.makeWebRequest(
                    _baseUrl + "/auth/token",
                    {
                        "action" => "revoke",
                        "token" => getRefreshToken()

                    },
                    {:method => Comm.HTTP_REQUEST_METHOD_POST},
                    null
                );
            }

            setAccessToken(null);
            setRefreshToken(null);
            setAccessTokenExpiration(null);
        }

        function _onWebResponse(responseCode, body, context) {
            var error = null;
            if (responseCode < 200 || responseCode >= 300) {
                error = new RequestError(responseCode);

                if (error.code == ERROR_NOT_AUTHORIZED) {
                    setAccessToken(null);
                    setAccessTokenExpiration(null);
                }
                if (
                    error.code == ERROR_NOT_FOUND
                    && context[:context] != null
                    && context[:context][:resource] != null
                ) {
                    error.setContext(context[:context][:resource]);
                }
            }

            context[:responseCallback].invoke(error, {
                :responseCode => responseCode,
                :body => body,
                :context => context[:context]
            });
        }

        function _doAuthenticatedWebRequest(error, context) {
            if (error != null) {
                context[:responseCallback].invoke(error, {
                    :context => context[:context]
                });
                return;
            }

            var accessToken = _accessToken;
            if (accessToken == null) {accessToken = Application.Storage.getValue("access_token");}

            var options = {
                :method => Comm.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + accessToken
                },
                :context => {
                    :responseCallback => context[:responseCallback],
                    :context => context[:options][:context]
                }
            };

            var passedOptions = context[:options];

            if (passedOptions[:method] != null) {
                options[:method] = passedOptions[:method];
            }

//            if (options[:method] == Comm.HTTP_REQUEST_METHOD_GET) {
//                System.println("GET: " + context[:url] + ", " + context[:parameters]);
//            } else if (options[:method] == Comm.HTTP_REQUEST_METHOD_POST) {
//                System.println("POST: " + context[:url] + ", " + context[:parameters]);
//            } else {
//                System.println("REQUEST: " + context[:url] + ", " + context[:parameters]);
//            }

            Comm.makeWebRequest(
                context[:url],
                context[:parameters],
                options,
                method(:_onWebResponse)
            );
        }

        /**
        * Executes single request to HASS with valid authentication params
        */
        function makeAuthenticatedWebRequest(url, parameters, options, responseCallback) {
            _tokenCallbacks.add({
                :callback => method(:_doAuthenticatedWebRequest),
                :context => {
                    :url => url,
                    :parameters => parameters,
                    :options => options,
                    :responseCallback => responseCallback
                }
            });

            refreshAccessToken();
        }

        /**
        * Returns refresh token used for obtaining new access token
        * from HASS server after its expiration
        */
        function getRefreshToken() {
            var refreshToken = _refreshToken;

            if (refreshToken == null) {
                refreshToken = Application.Storage.getValue("refresh_token");
            }

            return refreshToken;
        }

        /**
        * Sets refresh token which will be used for
        * obtaining of new access token from HASS server
        * after its expiration
        */
        function setRefreshToken(token) {
            if (_fixedAccessToken == true) {return;}

            _refreshToken = token;
            Application.Storage.setValue("refresh_token", token);
        }

        /**
        * Sets access token to running HASS server
        */
        function setAccessToken(token) {
            if (_fixedAccessToken == true) {return;}

            _accessToken = token;
            Application.Storage.setValue("access_token", token);
        }

        /**
        * Sets access token expiration date
        */
        function setAccessTokenExpiration(expiresIn) {
            if (_fixedAccessToken == true) {return;}

            if (expiresIn != null) {
                _expires = Time.now().add(new Time.Duration(expiresIn));
                Application.Storage.setValue("expires", _expires.value());
            } else {
                _expires = null;
                Application.Storage.setValue("expires", null);
            }
        }

        /**
        * Checks if access token has expired and needs to be refreshed
        */
        function isAccessTokenExpired() {
            // If we are using a long-lived access token we cant check if it has expired
            if (_fixedAccessToken == true) {
                return false;
            }

            var expires = _expires;
            if (expires == null) {
                expires = Application.Storage.getValue("expires");
                if (expires != null) {
                    _expires = new Time.Moment(expires);
                }
            }

            if (expires == null) {
                return true;
            }

            // add 1 minute as buffer
            var now = Time.now().add(new Time.Duration(60));
            if (_expires.lessThan(now)) {
                return true;
            }

            return false;
        }

        /**
        * Requests single entity from HASS
        */
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

        /**
        * Sets state of single entity in HASS
        */
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