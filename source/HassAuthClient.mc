using Toybox.Communications as Comm;
using Toybox.Application as App;
using Toybox.Time;

const CLIENT_ID = "https://hasscontrol";
const REDIRECT_URL = CLIENT_ID + "/hass/auth_callback";

class HassAuthClient {
    hidden var _hassUrl;
    hidden var _refreshToken;
    hidden var _accessToken;
    hidden var _expires;
    hidden var _isLoggingIn;
    hidden var _isFetchingAccessToken;
    hidden var _tokenCallbacks;

    static var ERROR_UNKNOWN = 0;
    static var ERROR_SERVER_NOT_REACHABLE = 1;
    static var ERROR_NOT_AUTHORIZED = 2;
    static var ERROR_TOKEN_REVOKED = 3;

    function initialize() {
        Comm.registerForOAuthMessages(method(:onReceiveCode));

        _hassUrl = Application.Properties.getValue("host");

        _isLoggingIn = false;
        _isFetchingAccessToken = false;
        _tokenCallbacks = new [0];
        _refreshToken = null;
        _accessToken = null;
        _expires = null;

        var hasToken = (refreshToken != null);
        System.println("Has stored refreshToken: " + hasToken);
    }

    function getAccessToken() {
        var accessToken = _accessToken;

        if (accessToken == null) {
            accessToken = Application.Storage.getValue("access_token");
        }

        return accessToken;
    }

    function setAccessToken(token) {
        _accessToken = token;
        Application.Storage.setValue("access_token", token);
    }

    function getRefreshToken() {
        var refreshToken = _refreshToken;

        if (refreshToken == null) {
            refreshToken = Application.Storage.getValue("refresh_token");
        }

        return refreshToken;
    }

    function setRefreshToken(token) {
        _refreshToken = token;
        Application.Storage.setValue("refresh_token", token);
    }

    function getExpires() {
        var expires = _expires;

        if (expires == null) {
            expires = Application.Storage.getValue("expires");

            if (expires != null) {
                expires = new Time.Moment(expires);
                _expires = expires;
            }
        }

        return expires;
    }

    function setExpires(expires) {
        if (expires != null) {
            _expires = expires;
            Application.Storage.setValue("expires", _expires.value());
        } else {
            _expires = null;
            Application.Storage.setValue("expires", null);
        }
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

    function onReceiveTokens(code, data) {
        var areWeLoggingIn = false;
        _setIsLoggingIn(areWeLoggingIn);

        _isFetchingAccessToken = false;

        if (code == 200) {
            var expires = Time.now().add(new Time.Duration(data["expires_in"]));

            setExpires(expires);
            setAccessToken(data["access_token"]);

            if (data["refresh_token"]) {
                System.println("Saving refresh token");
                setRefreshToken(data["refresh_token"]);
            }

            System.println("Received tokens from home assistant");

            fireTokenCallbacks(null);
        } else {
            var error = { "errorCode" => ERROR_UNKNOWN };

            if (code == 401) {
                error = { "errorCode" => ERROR_NOT_AUTHORIZED };
            } else if (code == 404) {
                error = { "errorCode" => ERROR_SERVER_NOT_REACHABLE };
            } else if (code == 400) {
                error = { "errorCode" => ERROR_TOKEN_REVOKED };
                logout();
            }

            error["responseCode"] = code;
            error["type"] = "token";

            System.println("Failed to complete auth request, status " + code);
            System.println(data);

            fireTokenCallbacks(error);
        }
    }

    function hasExpired() {
        // add 1 minute as buffer
        var now = Time.now().add(new Time.Duration(1790));
        var expires = getExpires();

        if (expires == null) {
            return true;
        }

        if (expires.lessThan(now)) {
            return true;
        }

        return false;
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

        if (hasExpired() == true || force == true) {
            System.println("AccessToken has expired, lets refresh!");
            var refreshToken = getRefreshToken();

            _isFetchingAccessToken = true;
            Comm.makeWebRequest(
                _hassUrl + "/auth/token",
                {
                    "grant_type" => "refresh_token",
                    "client_id" => CLIENT_ID,
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
                _hassUrl + "/auth/token",
                {
                    "grant_type" => "authorization_code",
                    "client_id" => CLIENT_ID,
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
        // App.getApp().viewController.showLoginView(false);
        if (value.data["code"] != null) {
            System.println("Received auth code from home assistant");
            getTokensFromCode(value.data["code"]);
        } else {
            var error = { "errorCode" => ERROR_UNKNOWN };

            if (value.responseCode == 401) {
                error = { "errorCode" => ERROR_NOT_AUTHORIZED };
            } else if (value.responseCode == 404) {
                error = { "errorCode" => ERROR_SERVER_NOT_REACHABLE };
            }

            error["responseCode"] = value.responseCode;
            error["type"] = "authCode";

            var areWeLoggingIn = false;
            _setIsLoggingIn(areWeLoggingIn);

            fireTokenCallbacks(error);

            System.println("Failed to receive auth code!");
            System.println(value.data);
        }
    }

    function _setIsLoggingIn(isLoggingIn) {
        System.println("is logging in: " + isLoggingIn);
        _isLoggingIn = isLoggingIn;
        App.getApp().viewController.showLoginView(_isLoggingIn);
    }

    function isLoggedIn() {
        var refreshToken = getRefreshToken();
        if (refreshToken != null) {
            return true;
        }

        return false;
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

        var areWeLoggingIn = true;
        _setIsLoggingIn(areWeLoggingIn);

        System.println("About to fire an oauth request!");
        Comm.makeOAuthRequest(
            _hassUrl + "/auth/authorize",
            {
                "client_id" => CLIENT_ID,
                "response_type"=>"code",
                "scope"=>"public",
                "redirect_uri"=> REDIRECT_URL
            },
            REDIRECT_URL,
            Comm.OAUTH_RESULT_TYPE_URL,
            {"code"=>"code"}
        );
    }

    function logout() {
        System.println("Logging out!");
        setAccessToken(null);
        setRefreshToken(null);
        setExpires(null);
    }
}