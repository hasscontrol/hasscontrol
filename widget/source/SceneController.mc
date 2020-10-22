using Toybox.Application as App;
using Toybox.StringUtil;

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
      var currentId = "";
      var currentName = "";

      for (var i = 0; i < chars.size(); i++) {
        var char = chars[i];

        if (char.equals(',')) {
          if (currentId.equals("")) {
            currentId = currentName;
          }

          scenes.add([currentId, currentName]);
          currentId = "";
          currentName = "";
        } else if (char.equals('=')) {
          currentId = currentName;
          currentName = "";
        } else {
          currentName += char;
        }
      }

      if (!currentName.equals("")) {
        if (currentId.equals("")) {
          currentId = currentName;
        }

        scenes.add([currentId, currentName]);
      }
    }

    // remove whitespace
    for (var sceneIndex = 0; sceneIndex < scenes.size(); sceneIndex++) {
      var sceneIdChars = scenes[sceneIndex][0].toCharArray();
      var sceneNameChars = scenes[sceneIndex][1].toCharArray();
      var sceneId = "";

      for (var i = 0; i < sceneIdChars.size(); i++) {
        if (sceneIdChars[i].equals(' ')) {
          continue;
        }
        sceneId += sceneIdChars[i];
      }

      for (var i = 0; i < sceneNameChars.size(); i++) {
        if (!sceneNameChars[i].equals(' ')) {
          break;
        }
        sceneNameChars = sceneNameChars.slice(i + 1, null);
      }
      for (var i = sceneNameChars.size() - 1; i >= 0; i--) {
        if (!sceneNameChars[i].equals(' ')) {
          break;
        }
        sceneNameChars = sceneNameChars.slice(null, i);
      }

      scenes[sceneIndex][0] = sceneId;
      scenes[sceneIndex][1] = StringUtil.charArrayToString(sceneNameChars);
    }

    System.println("Loaded scenes: " + scenes);
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
    return scenes[_focusedScene][1];
  }

  function getNextScene() {
    var nextScene = calcNextScene();

    if (nextScene == null) {
      return null;
    }

    if (nextScene < _focusedScene) {
      return null;
    }

    return scenes[nextScene][1];
  }

  function getPreviousScene() {
    var previousScene = calcPreviousScene();

    if (previousScene == null) {
      return null;
    }

    if (previousScene > _focusedScene) {
      return null;
    }

    return scenes[previousScene][1];
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
    if (error != null) {
      System.println(error);
      App.getApp().viewController.removeLoaderImmediate();
      App.getApp().viewController.showError(error);
    } else {
      App.getApp().viewController.removeLoader();
    }
  }

  function activateFocusedScene() {
    if (_focusedScene == null) {
      return;
    }

    App.getApp().viewController.showLoader("Setting Scene");

    client.activateScene(scenes[_focusedScene][0], method(:onActivateComplete));
  }
}