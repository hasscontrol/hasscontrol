using Toybox.Communications as Comm;
using Toybox.Application as App;
using Toybox.StringUtil;
using Toybox.Time;

(:glance)
module Hass {
    class OauthCredentials {
        hidden var _refreshToken;
        hidden var _accessToken;
        hidden var _expires;

        function initialize() {
            _refreshToken = null;
            _accessToken = null;
            _expires = null;
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

        function setExpires(expiresIn) {
            if (expiresIn != null) {
                _expires = Time.now().add(new Time.Duration(expiresIn));
                Application.Storage.setValue("expires", _expires.value());
            } else {
                _expires = null;
                Application.Storage.setValue("expires", null);
            }
        }

        function clear() {
            System.println("Clearing credentials!");
            setAccessToken(null);
            setRefreshToken(null);
            setExpires(null);
        }

        function hasExpired() {
            // add 1 minute as buffer
            var now = Time.now().add(new Time.Duration(60));
            var expires = getExpires();

            if (expires == null) {
                return true;
            }

            if (expires.lessThan(now)) {
                return true;
            }

            return false;
        }
    }
}