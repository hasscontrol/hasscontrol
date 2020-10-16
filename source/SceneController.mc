using Toybox.Application as App;

class SceneController {
  var client;
  var scenes;

  hidden var _focusedScene;

  function initialize(hassClient) {
    client = hassClient;

    scenes = new [0];
    refreshScenes();
  }

  function refreshScenes() {
    scenes = new [0];

    var sceneString = Application.Properties.getValue("scenes");

    if (sceneString != null && sceneString != "") {
      var chars = sceneString.toCharArray();
      var current = "";

      for (var i = 0; i < chars.size(); i++) {
        var char = chars[i];

        if (char.equals(',')) {
          scenes.add(current);
          current = "";
        } else if (char.equals(' ')) {
          continue;
        } else {
          current += char;
        }
      }

      if (!current.equals("")) {
        scenes.add(current);
      }
    }

    if (scenes.size() > 0) {
      _focusedScene = 0;
    } else {
      _focusedScene = null;
    }
  }

  function onSettingsChanged() {
    refreshScenes();
  }

  function calcNextScene() {
    if (_focusedScene == null) {
      return null;
    }

    var nextScene = _focusedScene + 1;

    if (nextScene > scenes.size() - 1) {
      nextScene = 0;
    }

    return nextScene;
  }

  function calcPreviousScene() {
    if (_focusedScene == null) {
      return null;
    }

    var previousScene = _focusedScene - 1;

    if (previousScene < 0) {
      previousScene = scenes.size() - 1;
    }

    return previousScene;
  }

  function getFocusedScene() {
    if (_focusedScene == null) {
      return null;
    }
    return scenes[_focusedScene];
  }

  function getNextScene() {
    var nextScene = calcNextScene();

    if (nextScene == null) {
      return null;
    }

    if (nextScene < _focusedScene) {
      return null;
    }

    return scenes[nextScene];
  }

  function getPreviousScene() {
    var previousScene = calcPreviousScene();

    if (previousScene == null) {
      return null;
    }

    if (previousScene > _focusedScene) {
      return null;
    }

    return scenes[previousScene];
  }

  function focusNextScene() {
    var nextScene = calcNextScene();
    if (nextScene != null) {
      _focusedScene = nextScene;
    }
  }

  function focusPreviousScene() {
    var previousScene = calcPreviousScene();
    if (previousScene != null) {
      _focusedScene = previousScene;
    }
  }

  function onActivateComplete(error, data) {
    var errorMessage = null;

    if (error != null && error["errorCode"] == HassClient.ERROR_PHONE_NOT_CONNECTED) {
      errorMessage = "Phone not\nconnected";
    } else if (error != null && error["errorCode"] == HassClient.ERROR_INVALID_HOST) {
      errorMessage = "Check settings\ninvalid host";
    } else if (error != null && error["errorCode"] == HassClient.ERROR_SERVER_NOT_REACHABLE) {
      errorMessage = "Home Assistant\nnot reachable";
    } else if (error != null && error["errorCode"] == HassClient.ERROR_NOT_AUTHORIZED) {
      errorMessage = "Authentication\nfailed";
    } else if (error != null && error["errorCode"] == HassClient.ERROR_RESOURCE_NOT_FOUND) {
      errorMessage = "Resource not\nfound";
    } else if (error != null && error["errorCode"] == HassClient.ERROR_TOKEN_REVOKED) {
      errorMessage = "Login Revoked";
    } else if (error != null) {
      errorMessage = "Unknown error\noccurred";
      errorMessage += "\n" + error["type"];
      errorMessage += "\n" + error["responseCode"];
    }

    if (errorMessage != null) {
      System.println(error);
      App.getApp().viewController.removeLoaderImmediate();
      App.getApp().viewController.showError(errorMessage);
    } else {
      App.getApp().viewController.removeLoader();
    }
  }

  function activateFocusedScene() {
    if (_focusedScene == null) {
      return;
    }

    System.println("About to activate focused scene: " + scenes[_focusedScene]);

    App.getApp().viewController.showLoader("Setting Scene");

    client.activateScene(scenes[_focusedScene], method(:onActivateComplete));
  }
}