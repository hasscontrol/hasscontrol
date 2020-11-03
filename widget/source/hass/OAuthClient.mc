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
        hidden var _credentials;

        hidden var _tokenCallbacks;

        hidden var _isLoggingIn;
        hidden var _isFetchingAccessToken;

        function initialize(options) {
            Comm.registerForOAuthMessages(method(:onReceiveCode));

            _authUrl = options[:authUrl];
            _tokenUrl = options[:tokenUrl];
            _clientId = options[:clientId];
            _redirectUrl = options[:redirectUrl];
            _credentials = new OauthCredentials();
            _tokenCallbacks = new [0];
            _isLoggingIn = false;
            _isFetchingAccessToken = false;
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

        function addTokenCallback(callback, context) {
            _tokenCallbacks.add({
                "callback" => callback,
                "context" => context
            });
        }

        function removeTokenCallback(callbackObject) {
            _tokenCallbacks.remove(callbackObject);
        }

        function fireTokenCallbacks(error) {
            for( var i = 0; i < _tokenCallbacks.size(); i++ ) {
                var callbackObject = _tokenCallbacks[i];

                callbackObject["callback"].invoke(error, callbackObject["context"]);

                removeTokenCallback(callbackObject);
            }
        }

        function _setIsLoggingIn(isLoggingIn) {
            System.println("is logging in: " + isLoggingIn);
            _isLoggingIn = isLoggingIn;
            App.getApp().viewController.showLoginView(_isLoggingIn);
        }

        function isLoggedIn() {
            var refreshToken = _credentials.getRefreshToken();
            if (refreshToken != null) {
                return true;
            }

            return false;
        }

        function onReceiveTokens(code, data) {
            _setIsLoggingIn(false);

            _isFetchingAccessToken = false;

            if (code == 200) {
                _credentials.setExpires(data["expires_in"]);
                _credentials.setAccessToken(data["access_token"]);

                if (data["refresh_token"]) {
                    System.println("Saving refresh token");
                    _credentials.setRefreshToken(data["refresh_token"]);
                }

                System.println("Received tokens from home assistant");

                fireTokenCallbacks(null);
            } else {
                var error = new OAuthError(code);

                if (error.code == ERROR_TOKEN_REVOKED) {
                    logout();
                }

                System.println("Failed to complete token request, status " + code);
                System.println(data);

                fireTokenCallbacks(error);
            }
        }

        function refreshToken(force) {
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

            if (_credentials.hasExpired() == true || force == true) {
                System.println("AccessToken has expired, lets refresh!");
                var refreshToken = _credentials.getRefreshToken();

                _isFetchingAccessToken = true;
                Comm.makeWebRequest(
                    _tokenUrl,
                    {
                        "grant_type" => "refresh_token",
                        "client_id" => _clientId,
                        "refresh_token" => refreshToken
                    },
                    {
                        :method => Comm.HTTP_REQUEST_METHOD_POST
                    },
                    method(:onReceiveTokens)
                );
            } else {
                System.println("AccessToken still valid :)");
                fireTokenCallbacks(null);
            }
        }

        function getTokensFromCode(code) {
            if (_isFetchingAccessToken != true) {
                _isFetchingAccessToken = true;

                Comm.makeWebRequest(
                    _tokenUrl,
                    {
                        "grant_type" => "authorization_code",
                        "client_id" => _clientId,
                        "code" => code
                    },
                    {
                        :method => Comm.HTTP_REQUEST_METHOD_POST
                    },
                    method(:onReceiveTokens)
                );
            }
        }

        function onReceiveCode(value) {
            if (value.data["code"] != null) {
                System.println("Received auth code from home assistant");
                getTokensFromCode(value.data["code"]);
            } else {
                var error = new OAuthError(value.responseCode);

                _setIsLoggingIn(false);

                fireTokenCallbacks(error);

                System.println("Failed to receive auth code!");
                System.println(error.toString());
            }
        }

        function login(callback) {
            if (callback != null) {
                addTokenCallback(callback);
            }

            if (isLoggedIn() == true) {
                System.println("Trying to login when we are already logged in");
                refreshToken(false);
                return;
            }

            _setIsLoggingIn(true);

            if (!System.getDeviceSettings().phoneConnected) {
                var error = new OAuthError(OAuthError.ERROR_PHONE_NOT_CONNECTED);

                fireTokenCallbacks(error);

                return;
            }

            System.println("About to fire an oauth request!");
            Comm.makeOAuthRequest(
            _authUrl,
                {
                    "client_id" => _clientId,
                    "response_type"=>"code",
                    "scope"=>"public",
                    "redirect_uri"=> _redirectUrl
                },
                _redirectUrl,
                Comm.OAUTH_RESULT_TYPE_URL,
                {"code"=>"code"}
            );
        }

        function logout() {
            // TODO: try to clear session in home assistant?
            _credentials.clear();
        }

        function onWebResponse(responseCode, body, context) {
            var error = null;

            if (responseCode < 200 || responseCode >= 300) {
                error = new RequestError(responseCode);

                if (error.code == ERROR_NOT_AUTHORIZED) {
                    _credentials.setAccessToken(null);
                    _credentials.setExpires(null);
                }
                if (
                    error.code == ERROR_NOT_FOUND
                    && context[:context] != null
                    && context[:context][:resource] != null
                ) {
                    error.setContext(context[:context][:resource]);
                }
            }

            System.println(context);

            context[:responseCallback].invoke(error, {
                :responseCode => responseCode,
                :body => body,
                :context => context[:context]
            });
        }

        function doAuthenticatedWebRequest(error, context) {
            if (error != null) {
                context[:responseCallback].invoke(error, {
                    :context => context[:context]
                });
                return;
            }

            var accessToken = _credentials.getAccessToken();

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
                method(:onWebResponse)
            );
        }

        function makeAuthenticatedWebRequest(url, parameters, options, responseCallback) {
            addTokenCallback(method(:doAuthenticatedWebRequest), {
                :url => url,
                :parameters => parameters,
                :options => options,
                :responseCallback => responseCallback,
            });

            refreshToken(false);
        }
    }
}