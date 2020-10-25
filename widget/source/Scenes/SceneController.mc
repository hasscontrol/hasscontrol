using Toybox.Application as App;
using Toybox.StringUtil;

class SceneController {
  var scenes;

  hidden var _focusedScene;

  function initialize() {
    refreshScenes();
  }

  function refreshScenes() {
    var entities = App.getApp().hassController.getEntities();

    scenes = new [0];

    for (var i = 0; i < entities.size(); i++) {
      if (entities[i].getType() == Entity.TYPE_SCENE) {
        scenes.add(entities[i]);
      }
    }

    System.println("scenes: " + scenes);

    if (scenes.size() > 0) {
      _focusedScene = 0;
    } else {
      _focusedScene = null;
    }
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

    App.getApp().hassClient.activateScene(scenes[_focusedScene].getId(), method(:onActivateComplete));
  }
}