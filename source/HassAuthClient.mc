using Toybox.Communications as Comm;
using Toybox.Application as App;
using Toybox.Time;

class HassAuthClient {
    hidden var _hassUrl;
    hidden var _clientId;
    hidden var _redirectUrl;
    hidden var _refreshToken;
    hidden var _accessToken;
    hidden var _expires;
    hidden var _isLoggingIn;
    hidden var _isFetchingAccessToken;
    hidden var _tokenCallbacks;

    static var ERROR_UNKNOWN = 0;
    static var ERROR_SERVER_NOT_REACHABLE = 1;
    static var ERROR_NOT_AUTHORIZED = 2;

    function initialize() {
        Comm.registerForOAuthMessages(method(:onReceiveCode));

        _hassUrl = Application.Properties.getValue("host");

        var refreshToken = Application.Storage.getValue("refresh_token");
        var accessToken = Application.Storage.getValue("access_token");
        var expires = Application.Storage.getValue("expires");

        _clientId = "https://localhost";
        _redirectUrl = _clientId + "/hass/auth_callback";
        _isLoggingIn = false;
        _isFetchingAccessToken = false;
        _tokenCallbacks = new [0];

        var hasToken = (refreshToken != null);
        System.println("Has stored refreshToken: " + hasToken);


        // We have to create new references to the objects for Storage
        // They have week references
        if (refreshToken != null) {
            _refreshToken = refreshToken.toString();
        } else {
            _refreshToken = null;
        }

        if (accessToken != null) {
            _accessToken = accessToken.toString();
        } else {
            _accessToken = null;
        }

        if (expires != null) {
            _expires = new Time.Moment(expires);
        } else {
            _expires = null;
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

        if (code == 200) {
            _accessToken = data["access_token"];
            _refreshToken = data["refresh_token"];
            _expires = Time.now().add(new Time.Duration(data["expires_in"]));
            _isFetchingAccessToken = false;

            Application.Storage.setValue("refresh_token", _refreshToken);
            Application.Storage.setValue("access_token", _accessToken);
            Application.Storage.setValue("expires", _expires.value());

            fireTokenCallbacks(null);
        } else {
            var error = { "errorCode" => ERROR_UNKNOWN };

            if (code == 401) {
                error = { "errorCode" => ERROR_NOT_AUTHORIZED };
                clearAccessToken();
            } else if (code == 404) {
                error = { "errorCode" => ERROR_SERVER_NOT_REACHABLE };
            }

            error["responseCode"] = code;
            error["type"] = "token";

            System.println("Failed to complete auth request, status " + code);
            System.println(data);

            fireTokenCallbacks(error);
        }
    }

    function hasExpired() {
        if (_accessToken == null || _expires == null) {
            return true;
        }

        // add 1 minute as buffer
        var now = Time.now().add(new Time.Duration(60));

        if (_expires.lessThan(now)) {
            return true;
        }

        return false;
    }

    function getAccessToken() {
        return _accessToken;
    }

    function clearAccessToken() {
        _accessToken = null;
    }

    function refreshToken() {
        if (_isLoggingIn) {
            return;
        }

        if (isLoggedIn() == false) {
            System.println("Refreshing token, not logged in");
            login(null);
            return;
        }

        if (_isFetchingAccessToken == true) {
            return;
        }

        if (hasExpired() == true) {
            _isFetchingAccessToken = true;
            Comm.makeWebRequest(
                _hassUrl + "/auth/token",
                {
                    "grant_type" => "refresh_token",
                    "client_id" => _clientId,
                    "refresh_token" => _refreshToken
                },
                {
                    :method => Comm.HTTP_REQUEST_METHOD_POST
                },
                method(:onReceiveTokens)
            );
        } else {
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
        // App.getApp().viewController.showLoginView(false);
        if (value.data["code"] != null) {
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
        if (_refreshToken != null) {
            System.println("refresh token is not null!");
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
            refreshToken();
            return;
        }

        var areWeLoggingIn = false;
        _setIsLoggingIn(areWeLoggingIn);

        Comm.makeOAuthRequest(
            _hassUrl + "/auth/authorize",
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
}