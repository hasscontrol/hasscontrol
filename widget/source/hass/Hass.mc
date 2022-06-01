using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System;

using Utils;

module Hass {
  const STORAGE_KEY = "Hass/entities";

  var client = null;
  var _entities = new [0];
  var _entitiesToRefresh = new [0];
  var _continueRefreshOnError = false;

  function initClient() {
    client = new Client();
  }

  function getGroup() {
    var group = App.Properties.getValue("group");

    if (group.find("group.") == null) {
      group = "group." + group;
    }

    return group;
  }

  function getEntities() {
    return _entities;
  }

  function getEntitiesByTypes(types) {
    var entities = new [0];

    for (var eI = 0; eI < _entities.size(); eI++) {
      var match = false;

      for (var tI = 0; tI < types.size(); tI++) {
        if (_entities[eI].getType() == types[tI]) {
          match = true;
          break;
        }
      }

      if (match) {
        entities.add(_entities[eI]);
      }
    }

    return entities;
  }

  function getEntity(id) {
    var entity = null;

    for (var i = 0; i < _entities.size(); i++) {
      if (_entities[i].getId().equals(id)) {
        entity = _entities[i];
        break;
      }
    }

    return entity;
  }

  function storeEntities() {
    var entities = new [0];

    for (var i = 0; i < _entities.size(); i++) {
      if (_entities[i].isExternal()) {
        continue;
      }
      entities.add(_entities[i].toDict());
    }

    App.Storage.setValue(STORAGE_KEY, entities);
  }

  function loadScenesFromSettings() {
    var scenes = Utils.getScenesFromSettings();

    // first remove all external scenes to make sure we are not persisting any old scenes
    var entitiesToRemove = new [0];
    for (var i = 0; i < _entities.size(); i++) {
      if (_entities[i].isExternal()) {
        entitiesToRemove.add(_entities[i]);
      }
    }
    for (var i = 0; i < entitiesToRemove.size(); i++) {
      _entities.remove(entitiesToRemove[i]);
    }
    entitiesToRemove = null;

    for (var i = 0; i < scenes.size(); i++) {
      var entity = getEntity(scenes[i][0]);

      if (entity != null) {
        // We only set the name if it's different than the id
        if (!scenes[i][0].equals(scenes[i][1])) {
          entity.setName(scenes[i][1]);
        }
      } else {
        _entities.add(new Entity({
          :id => scenes[i][0],
          :name => scenes[i][1],
          :state => "scening",
          :ext => true
        }));
      }
    }
  }

  function loadStoredEntities() {
    var entities = App.Storage.getValue(STORAGE_KEY);

    _entities = new [0];

    if (entities == null) {
      return;
    }

    for (var i = 0; i < entities.size(); i++) {
      _entities.add(Entity.createFromDict(entities[i]));
    }

    loadScenesFromSettings();

    System.println("Loaded entities: " + _entities);
  }

  function _onReceiveEntity(err, data) {
    if (err != null) {
      if (data != null && data[:context][:callback] != null) {
        data[:context][:callback].invoke(err, null);
      } else {
        App.getApp().viewController.showError(err);
      }
      return;
    }

    var name = null;
    var state = null;

    if (data != null && data[:body] != null) {
      if (data[:body]["attributes"] != null) {
        name = data[:body]["attributes"]["friendly_name"];
      }
      state = data[:body]["state"];
    }

    var entity = getEntity(data[:body]["entity_id"]);

    if (name != null) {
      entity.setName(name);
    }

    if (state != null) {
      entity.setState(state);
    } else {
      entity.setState(Entity.STATE_UNKNOWN);
    }

    if (data[:context][:callback] != null) {
      data[:context][:callback].invoke(null, entity);
    }
  }

  function refreshEntity(entity, callback) {
    client.getEntity(
      entity.getId(),
      {
        :entity => entity,
        :callback => callback
      },
      Utils.method(Hass, :_onReceiveEntity)
    );
  }

  function _refreshPendingEntities(error, noop) {
    if (error != null && !_continueRefreshOnError) {
      App.getApp().viewController.removeLoader();
      App.getApp().viewController.showError(error);

      // We need to finalize with reading the scenes from settings again,
      // so that the name config takes precedence
      loadScenesFromSettings();

      storeEntities();

      Ui.requestUpdate();
      return;
    }

    if (_entitiesToRefresh.size() > 0) {
      var entity = _entitiesToRefresh[0];

      _entitiesToRefresh.remove(entity);

      refreshEntity(entity, Utils.method(Hass, :_refreshPendingEntities));
    } else {
      // We need to finalize with reading the scenes from settings again,
      // so that the name config takes precedence
      loadScenesFromSettings();

      storeEntities();

      Ui.requestUpdate();

      App.getApp().viewController.removeLoader();
    }
  }

  function refreshAllEntities(continueOnError) {
    _entitiesToRefresh = new [0];
    _continueRefreshOnError = continueOnError == true;

    for (var i = 0; i < _entities.size(); i++) {
      _entitiesToRefresh.add(_entities[i]);
    }

    _refreshPendingEntities(null, null);
  }

  function _onReceiveEntities(err, data) {
    if (err == null) {
      var entities = data[:body]["attributes"]["entity_id"];

      _entities = new [0];

      for (var i = 0; i < entities.size(); i++) {
        var entity = getEntity(entities[i]);

        if (entity == null) {
          _entities.add(new Entity({
            :id => entities[i],
            :name => entities[i],
            :state => null
          }));
        } else {
          entity.setExternal(false);
        }
      }

      loadScenesFromSettings();

      refreshAllEntities(false);
    } else {
      App.getApp().viewController.removeLoader();
      App.getApp().viewController.showError(err);
    }
  }

  function importEntities() {
    var group = getGroup();

    if (group == null || group.find("group.") == null) {
      App.getApp().viewController.showError(group + "\nis not a valid\ngroup");
      return;
    }

    App.getApp().viewController.showLoader("Refreshing");

    client.getEntity(group, null, Utils.method(Hass, :_onReceiveEntities));
  }

  function onToggleEntityStateCompleted(error, data) {
    if (error != null) {
      App.getApp().viewController.removeLoaderImmediate();
      App.getApp().viewController.showError(error);
      return;
    }

    if (data[:context][:state] != null) {
      var entity = getEntity(data[:context][:entityId]);

      if (entity != null) {
        var newState = data[:context][:state];

        if (entity.getType() == Entity.TYPE_SCRIPT) {
          newState = Entity.STATE_OFF;
        }

        entity.setState(newState);

        storeEntities();
        Ui.requestUpdate();
      }
    }

    App.getApp().viewController.removeLoader();
  }

  function toggleEntityState(entity) {
    var entityId = entity.getId();
    var currentState = entity.getState();
    var entityType = null;
    var action = null;
    var loadingText = "Loading";
    
    if (entity.getType() == Entity.TYPE_BINARY_SENSOR) {
        // binary_sensor cannot be set, only read
        return;
    }

    if (entity.getType() == Entity.TYPE_SCRIPT) {
      action = Client.ENTITY_ACTION_TURN_ON;
      loadingText = "Running";
    } else if (entity.getType() == Entity.TYPE_LOCK) {
      if (currentState == Entity.STATE_UNLOCKED) {
        action = Client.ENTITY_ACTION_LOCK;
        loadingText = "Locking";
      } else if (currentState == Entity.STATE_LOCKED) {
        action = Client.ENTITY_ACTION_UNLOCK;
        loadingText = "Unlocking";
      }
    } else if (entity.getType() == Entity.TYPE_COVER) {
      if (currentState == Entity.STATE_OPEN) {
        action = Client.ENTITY_ACTION_CLOSE_COVER;
        loadingText = "Closing";
      } else if (currentState == Entity.STATE_CLOSED) {
        action = Client.ENTITY_ACTION_OPEN_COVER;
        loadingText = "Opening";
      }
    } else if (entity.getType() == Entity.TYPE_INPUT_BUTTON || entity.getType() == Entity.TYPE_BUTTON) {
      action = Client.ENTITY_ACTION_PRESS;
      loadingText = "Pressing";
    } else {
      if (currentState == Entity.STATE_ON) {
        action = Client.ENTITY_ACTION_TURN_OFF;
        loadingText = "Turning off";
      } else if (currentState == Entity.STATE_OFF) {
        action = Client.ENTITY_ACTION_TURN_ON;
        loadingText = "Turning on";
      }
    }

    if (entity.getType() == Entity.TYPE_SCENE) {
      entityType = "scene";
      action = null;
    } else if (entity.getType() == Entity.TYPE_LIGHT) {
      entityType = "light";
    } else if (entity.getType() == Entity.TYPE_SWITCH) {
      entityType = "switch";
    } else if (entity.getType() == Entity.TYPE_AUTOMATION) {
      entityType = "automation";
    } else if (entity.getType() == Entity.TYPE_SCRIPT) {
      entityType = "script";
    } else if (entity.getType() == Entity.TYPE_LOCK) {
      entityType = "lock";
    } else if (entity.getType() == Entity.TYPE_COVER) {
      entityType = "cover";
    } else if (entity.getType() == Entity.TYPE_INPUT_BOOLEAN) {
      entityType = "input_boolean";
    } else if (entity.getType() == Entity.TYPE_INPUT_BUTTON) {
      entityType = "input_button";
    } else if (entity.getType() == Entity.TYPE_BUTTON) {
      entityType = "button";
    } 

    App.getApp().viewController.showLoader(loadingText);

    client.setEntityState(entityId, entityType, action, Utils.method(Hass, :onToggleEntityStateCompleted));
  }
}

class HassController {



  // function _refreshPendingEntities() {
  //   var entity = null;

  //   for (var i = 0; i < _entities.size(); i++) {
  //     if (_entities[i].getState() == null) {
  //       entity = _entities[i];
  //       break;
  //     }
  //   }

  //   if (entity != null) {
  //     client.getEntity(entity.getId(), method(:onReceiveRefreshedEntity));
  //   } else {
  //     System.println(_entities);
  //     storeEntities();
  //     App.getApp().viewController.removeLoader();
  //   }
  // }

  // function onReceiveEntities(err, data) {
  //   if (err == null) {
  //     var entities = data[:body]["attributes"]["entity_id"];

  //     _entities = new [0];

  //     for (var i = 0; i < entities.size(); i++) {
  //       _entities.add(new Entity({
  //         :id => entities[i],
  //         :name => "",
  //         :state => null
  //       }));
  //     }

  //     _refreshPendingEntities();
  //   } else {
  //     App.getApp().viewController.showError(err);
  //   }
  // }

  // function refreshAllEntityStates() {
  //     for (var i = 0; i < _entities.size(); i++) {
  //       _entities[i].setState(null);
  //     }

  //     _refreshPendingEntities();
  // }
}