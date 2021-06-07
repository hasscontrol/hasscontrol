using Toybox.Communications as Comm;
using Toybox.Application as App;
using Toybox.StringUtil;
using Toybox.Time;

(:glance)
module Hass {
    class OAuthClient {
        hidden var _authUrl;
        hidden var _tokenUrl;
        hidden var _clientId;
        hidden var _redirectUrl;

        hidden var _tokenCallbacks;

        hidden var _isLoggingIn;
        hidden var _isFetchingAccessToken;

        hidden var _refreshToken;
        hidden var _accessToken;
        hidden var _expires;
        hidden var _fixedAccessToken;

        function initialize(options) {
            Comm.registerForOAuthMessages(method(:_onReceivedAuthCode));

            _authUrl = options[:authUrl];
            _tokenUrl = options[:tokenUrl];
            _clientId = options[:clientId];
            _redirectUrl = options[:redirectUrl];
            _tokenCallbacks = new [0];
            _isLoggingIn = false;
            _isFetchingAccessToken = false;
            _fixedAccessToken = false;
            loadLongLivedToken();
        }

        function onSettingsChanged() {
            loadLongLivedToken();
        }

        function setAuthUrl(newUrl) {
            if (!_authUrl.equals(newUrl)) {
                logout();
            }

            _authUrl = newUrl;
        }

        function setTokenUrl(newUrl) {
            if (!_tokenUrl.equals(newUrl)) {
                logout();
            }

            _tokenUrl = newUrl;
        }

        function _fireTokenCallbacks(error) {
            for( var i = 0; i < _tokenCallbacks.size(); i++ ) {
                var callbackObject = _tokenCallbacks[i];

                callbackObject[:callback].invoke(error, callbackObject[:context]);

                _tokenCallbacks.remove(callbackObject);
            }
        }

        function _setIsLoggingIn(isLoggingIn) {
            System.println("is logging in: " + isLoggingIn);
            _isLoggingIn = isLoggingIn;
            if (isLoggingIn) {
                App.getApp().viewController.showLoginView();
            } else {
                App.getApp().viewController.removeLoginView();
            }
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
                    System.println("Saving refresh token");
                    setRefreshToken(data["refresh_token"]);
                }

                System.println("Received tokens from home assistant");

                _fireTokenCallbacks(null);
            } else {
                var error = new OAuthError(code);

                if (error.code == ERROR_TOKEN_REVOKED) {
                    logout();
                }

                System.println("Failed to complete token request, status " + code);
                System.println(data);

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
                System.println("Not logged in, let's log in!");
                login(null);
                return;
            }

            if (_isFetchingAccessToken == true) {
                return;
            }

            if (isAccessTokenExpired() == true) {
                System.println("AccessToken has expired, lets refresh!");
                var refreshToken = getRefreshToken();

                _isFetchingAccessToken = true;
                Comm.makeWebRequest(
                    _tokenUrl,
                    {
                        "grant_type" => "refresh_token",
                        "refresh_token" => refreshToken,
                        "client_id" => _clientId
                    },
                    {
                        :method => Comm.HTTP_REQUEST_METHOD_POST
                    },
                    method(:_onReceivedTokens)
                );
            } else {
                System.println("AccessToken still valid :)");
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
                    _tokenUrl,
                    {
                        "grant_type" => "authorization_code",
                        "code" => code,
                        "client_id" => _clientId

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
                System.println("Received auth code from home assistant");
                _getTokensUsingCode(value.data["code"]);
            } else {
                var error = new OAuthError(value.responseCode);

                _setIsLoggingIn(false);

                _fireTokenCallbacks(error);

                System.println("Failed to receive auth code!");
                System.println(error.toString());
            }
        }

        /**
        * Login into HASS
        */
        function login() {
            if (isLoggedIn() == true) {
                System.println("Trying to login when we are already logged in");
                refreshAccessToken();
                return;
            }

            _setIsLoggingIn(true);

            if (!System.getDeviceSettings().phoneConnected) {
                var error = new OAuthError(OAuthError.ERROR_PHONE_NOT_CONNECTED);

                _fireTokenCallbacks(error);

                return;
            }

            System.println("About to fire an oauth request!");
            Comm.makeOAuthRequest(
                _authUrl,
                {
                    "client_id" => _clientId,
                    "redirect_uri"=> _redirectUrl
                },
                _redirectUrl,
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
                    _tokenUrl,
                    {
                        "token" => getRefreshToken(),
                        "action" => "revoke"
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

            if (options[:method] == Comm.HTTP_REQUEST_METHOD_GET) {
                System.println("GET: " + context[:url] + ", " + context[:parameters]);
            } else if (options[:method] == Comm.HTTP_REQUEST_METHOD_POST) {
                System.println("POST: " + context[:url] + ", " + context[:parameters]);
            } else {
                System.println("REQUEST: " + context[:url] + ", " + context[:parameters]);
            }

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
        * Loads long lived token from CIQ settings
        */
        function loadLongLivedToken() {
            var accessToken = App.Properties.getValue("accessToken");
            if (accessToken.length() > 0 ) {
                _fixedAccessToken = true;
                _accessToken = accessToken;
            } else {
                _fixedAccessToken = false;
                _accessToken = null;
            }
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
            if (_fixedAccessToken == true) {
                System.println("Not allowed to set refresh token, while having long lived access token");
                return;
            }

            _refreshToken = token;
            Application.Storage.setValue("refresh_token", token);
        }

        /**
        * Sets access token to running HASS server
        */
        function setAccessToken(token) {
            if (_fixedAccessToken == true) {
                System.println("Not allowed to overwrite long lived access token");
                return;
            }

            _accessToken = token;
            Application.Storage.setValue("access_token", token);
        }

        /**
        * Sets access token expiration date
        */
        function setAccessTokenExpiration(expiresIn) {
            if (_fixedAccessToken == true) {
                System.println("Not allowed to set expires, while having long lived access token");
                return;
            }

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
    }
}