using Toybox.Application as App;
using Toybox.StringUtil;

class EntityController {
  hidden var _mEntities;

  hidden var _focusedEntity;

  function initialize() {
    _focusedEntity = null;
    refreshEntities();
  }

  function refreshEntities() {
    var entities = App.getApp().hassController.getEntities();

    _mEntities = new [0];

    for (var i = 0; i < entities.size(); i++) {
      if (entities[i].getType() == Entity.TYPE_LIGHT || entities[i].getType() == Entity.TYPE_SWITCH) {
        _mEntities.add(entities[i]);
      }
    }

    if (
      (_focusedEntity == null && _mEntities.size() > 0)
      || _focusedEntity > _mEntities.size() - 1
    ) {
      _focusedEntity = 0;
    } else if (_mEntities.size() == 0) {
      _focusedEntity = null;
    }
  }

  function calcNextEntity() {
    if (_focusedEntity == null) {
      return null;
    }

    if (_mEntities.size() < 2) {
      return null;
    }

    var nextEntity = _focusedEntity + 1;

    if (nextEntity > _mEntities.size() - 1) {
      nextEntity = 0;
    }

    return nextEntity;
  }

  function calcPreviousEntity() {
    if (_focusedEntity == null) {
      return null;
    }

    if (_mEntities.size() < 2) {
      return null;
    }

    var previousEntity = _focusedEntity - 1;

    if (previousEntity < 0) {
      previousEntity = _mEntities.size() - 1;
    }

    return previousEntity;
  }

  function getFocusedEntity() {
    System.println("_focusedEntity: " + _focusedEntity);
    if (_focusedEntity == null) {
      return null;
    }
    return _mEntities[_focusedEntity];
  }

  function getNextEntity() {
    var nextEntity = calcNextEntity();

    if (nextEntity == null) {
      return null;
    }

    if (nextEntity < _focusedEntity) {
      return null;
    }

    return _mEntities[nextEntity];
  }

  function getPreviousEntity() {
    var previousEntity = calcPreviousEntity();

    if (previousEntity == null) {
      return null;
    }

    if (previousEntity > _focusedEntity) {
      return null;
    }

    return _mEntities[previousEntity];
  }

  function focusNextEntity() {
    var nextEntity = calcNextEntity();
    if (nextEntity != null) {
      _focusedEntity = nextEntity;
    }
  }

  function focusPreviousEntity() {
    var previousEntity = calcPreviousEntity();
    if (previousEntity != null) {
      _focusedEntity = previousEntity;
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

  function toggleFocusedEntity() {
    var entity = getFocusedEntity();

    if (entity == null) {
      return;
    }

    System.println("Setting entity");
    // App.getApp().viewController.showLoader("Setting Entity");

    App.getApp().hassController.toggleEntityState(entity);
    // App.getApp().hassController.toggleEntityState(entity, method(:onActivateComplete));

    // client.activateEntity(_mEntities[_focusedEntity][0], method(:onActivateComplete));
  }
}