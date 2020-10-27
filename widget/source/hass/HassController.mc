using Toybox.Application as App;
using Toybox.WatchUi as Ui;

using Utils;


class HassController {
  static var STORAGE_KEY = "hassController/entities";

  hidden var client;
  hidden var _entities;

  function initialize(hassClient) {
    client = hassClient;
    _entities = new [0];

    loadEntities();
  }

  function getGroup() {
    return Application.Properties.getValue("group");
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

  function persistEntities() {
    var entities = new [0];

    for (var i = 0; i < _entities.size(); i++) {
      if (_entities[i].isExternal()) {
        return;
      }
      entities.add(_entities[i].toDict());
    }

    App.Storage.setValue(HassController.STORAGE_KEY, entities);

  }

  function loadEntities() {
    var entities = App.Storage.getValue(HassController.STORAGE_KEY);

    _entities = new [0];

    if (entities == null) {
      return;
    }

    for (var i = 0; i < entities.size(); i++) {
      _entities.add(Entity.createFromDict(entities[i]));
    }

    var scenes = Utils.getScenesFromSettings();

    for (var i = 0; i < scenes.size(); i++) {
      var entity = getEntity(scenes[i][0]);

      if (entity != null) {
        entity.setName(scenes[i][1]);
      } else {
        _entities.add(new Entity({
          :id => scenes[i][0],
          :name => scenes[i][1],
          :state => "scening",
          :show => true,
          :ext => true
        }));
      }
    }

    System.println(_entities);

    System.println("Loaded entities: " + _entities);
  }

  function onReceiveRefreshedEntity(err, data) {
    if (err == null) {
      var name = data[:body]["attributes"]["friendly_name"];
      var state = data[:body]["state"];

      if (state == null) {
        state = "unknown";
      }

      var entity = getEntity(data[:body]["entity_id"]);
      entity.setName(name);
      entity.setState(state);

      // TODO: we need to make sure we only call this same amout as we have entities
      // we dont want to be stuck in a endless loop
      refreshPendingEntity();
    } else {
      App.getApp().viewController.showError(err);
    }
  }

  function refreshPendingEntity() {
    var entity = null;

    for (var i = 0; i < _entities.size(); i++) {
      if (_entities[i].getState() == null) {
        entity = _entities[i];
        break;
      }
    }

    if (entity != null) {
      client.getEntity(entity.getId(), method(:onReceiveRefreshedEntity));
    } else {
      System.println(_entities);
      persistEntities();
      App.getApp().viewController.removeLoader();
    }
  }

  function onReceiveEntities(err, data) {
    if (err == null) {
      var entities = data[:body]["attributes"]["entity_id"];

      _entities = new [0];

      for (var i = 0; i < entities.size(); i++) {
        _entities.add(new Entity({
          :id => entities[i],
          :name => "",
          :state => null,
          :show => true // TODO: we need to persist existing setting
        }));
      }

      refreshPendingEntity();
    } else {
      App.getApp().viewController.showError(err);
    }
  }

  function fetchEntities() {
    var group = getGroup();

    if (group == null || group.find("group.") == null) {
      App.getApp().viewController.showError(group + "\nis not a valid\ngroup");
      return;
    }

    App.getApp().viewController.showLoader("Refreshing");

    client.getEntity(group, method(:onReceiveEntities));
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
        entity.setState(data[:context][:state]);

        persistEntities();
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

    if (currentState == Entity.STATE_ON) {
      action = HassClient.ENTITY_ACTION_TURN_OFF;
      loadingText = "Turning off";
    } else if (currentState == Entity.STATE_OFF) {
      action = HassClient.ENTITY_ACTION_TURN_ON;
      loadingText = "Turning on";
    }

    if (entity.getType() == Entity.TYPE_SCENE) {
      entityType = "scene";
      action = null;
    } else if (entity.getType() == Entity.TYPE_LIGHT) {
      entityType = "light";
    } else if (entity.getType() == Entity.TYPE_SWITCH) {
      entityType = "switch";
    }

    App.getApp().viewController.showLoader(loadingText);
    client.setEntityState(entityId, entityType, action, method(:onToggleEntityStateCompleted));
  }
}