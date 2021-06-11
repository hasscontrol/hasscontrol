using Toybox.Application as App;
using Toybox.Lang as Lang;
using Toybox.WatchUi as Ui;

(:glance)
module Hass {
    const STORAGE_GROUP_ENTITIES = "hass_group_entities";
    const STORAGE_STATES = "hass_entities_state";
    const supportedEntityTypes = [
        ENTITY_TYPE_ALARM_PANEL,
        ENTITY_TYPE_AUTOMATION,
        ENTITY_TYPE_BINARY_SENSOR,
        ENTITY_TYPE_COVER,
        ENTITY_TYPE_INPUT_BOOLEAN,
        ENTITY_TYPE_LIGHT,
        ENTITY_TYPE_LOCK,
        ENTITY_TYPE_SCENE,
        ENTITY_TYPE_SCRIPT,
        ENTITY_TYPE_SENSOR,
        ENTITY_TYPE_SWITCH
    ];
    var client = null;
    var _entities;
    var _entitiesStates = {};
    var _groupEntitiesCount;
    var _entityToRefreshCounter = 0;
    var _entitiesRefreshingSilent = false;

    /**
    * Initialize HTTP Client
    */
    function initClient() {
        client = new Client();
    }

    /**
    * Resets loaded entities and logout from HASS server
    */
    function logout() {
        _entities = [];
        _entitiesStates = {};
        client.logout();
    }

    /**
    * Returns name of group from settings set through Garmin Connect
    */
    function getGroup() {
        var group = App.Properties.getValue("group");
        if (group.find("group.") == null) {
            group = "group." + group;
        }
        return group;
    }

    /**
    * Returns all attributes of a single entity
    */
    function getEntityState(entityId) {
        return _entitiesStates.get(entityId);
    }

    /**
    * Returns list of imported entity ids inclusive
    * manualy defined scenes
    */
    function getImportedEntities() {
        return _entities;
    }

    /**
    * Helper callback method used for extracting data from single
    * entity response.
    */
    function _onRecievedGeneralEntity(err, data) {
        if (err != null) {
            if (_entitiesRefreshingSilent) {return;}

            if (data != null && data[:context][:callback] != null) {
                data[:context][:callback].invoke(err, null);
            } else {
                App.getApp().viewController.showError(err);
            }
            return;
        }

        var entityDict = {"state" => data[:body]["state"],
                          "attributes" => data[:body]["attributes"],
                          "last_changed" => data[:body]["last_changed"]};
        _entitiesStates.put(data[:body]["entity_id"], entityDict);
    }

    /**
    * Callback when single entity state is returned form HASS
    */
    function _onReceivedSingleEntity(err, data) {
        _onRecievedGeneralEntity(err, data);
        Ui.requestUpdate();
    }

    /**
    * Callback when state of entity is returned form HASS.
    * This function is used only when refreshing all imported
    * group entities at once. Caution we have to call one
    * web request after another, otherwise the app will crash.
    */
    function _onReceivedRefreshedImportedEntity(err, data) {
        _onRecievedGeneralEntity(err, data);

        _entityToRefreshCounter++;
        if (_entityToRefreshCounter < _groupEntitiesCount) {
            // we have to keep refreshing until we achieve end of list
            client.getEntity(_entities[_entityToRefreshCounter], null, new Lang.Method(Hass, :_onReceivedRefreshedImportedEntity));
        } else {
            // all entities are refreshed, remove loader and resets silent refresher
            App.getApp().viewController.removeLoader();
            _entitiesRefreshingSilent = false;
            Ui.requestUpdate();
        }
    }

    /**
    * Requests state of single entity from HASS
    */
    function refreshSingleEntity(entityId) {
        client.getEntity(entityId, null, new Lang.Method(Hass, :_onReceivedSingleEntity));
    }

    /**
    * Requests state of all imported entities from HASS
    * if there are manualy defined scene, insert them as well
    */
    function refreshImportedEntities(silent) {
        if(_groupEntitiesCount < 1) {return;}

        _entitiesRefreshingSilent = silent;
        client.getEntity(_entities[_entityToRefreshCounter], null, new Lang.Method(Hass, :_onReceivedRefreshedImportedEntity));
    }

    /**
    * Callback called when HASS returns list with entities from the group
    * Is removes all previously imported states
    */
    function _onReceivedGroupEntities(err, data) {
        if (err) {
            App.getApp().viewController.showError(err);
            return;
        }

        _entities = new [0];
        _groupEntitiesCount = 0;
        var recvEntities = data[:body]["attributes"]["entity_id"];
        for (var i = 0; i < recvEntities.size(); i++) {
            var recvEntityType = recvEntities[i].substring(0, recvEntities[i].find("."));
            if (supportedEntityTypes.indexOf(recvEntityType) != -1) {
                _entities.add(recvEntities[i]);
                _groupEntitiesCount++;
            }
        }

        _entityToRefreshCounter = 0;
        _entitiesStates = {};
        //we have to import scenes again, because the dict was cleared
        importScenesFromSettings();

        refreshImportedEntities(false);
    }

    /**
    * Stores entities from synchronized group into storage
    */
    function storeGroupEntities() {
        if (_groupEntitiesCount == null || _groupEntitiesCount < 1) {
            return;
        }

        var _entitiesWithoutManualScenes = _entities.slice(0, _groupEntitiesCount);
        var dictToStore = {};
        for (var i = 0; i < _entitiesWithoutManualScenes.size(); i++) {
            dictToStore.put(_entitiesWithoutManualScenes[i], _entitiesStates[_entitiesWithoutManualScenes[i]]);
        }
        App.Storage.setValue(STORAGE_STATES, dictToStore);
        App.Storage.setValue(STORAGE_GROUP_ENTITIES, _entitiesWithoutManualScenes);
    }

    /**
    * Loads entities from previously synchronized group from storage
    */
    function loadGroupEntities() {
        var grEnt = App.Storage.getValue(STORAGE_GROUP_ENTITIES);
        var entStat = App.Storage.getValue(STORAGE_STATES);
        if (grEnt instanceof Lang.Array) {
            _entities = grEnt;
            _groupEntitiesCount = grEnt.size();
        } else {
            _entities = [];
            _groupEntitiesCount = 0;
        }

        _entitiesStates = (entStat instanceof Lang.Dictionary) ? entStat : {};
    }

    /*
    * Imports list of entities from HASS group
    */
    function importGroupEntities() {
        var group = getGroup();

        if (group == null) {
            App.getApp().viewController.showError(group + "\nis not a valid\ngroup");
            return;
        }

        App.getApp().viewController.showLoader(Rez.Strings.LoaderRefreshing);
        client.getEntity(group, null, new Lang.Method(Hass, :_onReceivedGroupEntities));
    }

    /**
    * Callback called when state/scene/etc. is toggled successfully
    */
    function onToggleEntityStateCompleted(error, data) {
        if (error != null) {
            App.getApp().viewController.showError(error);
            return;
        }

        var changedStates = data[:body];
        for (var i = 0; i < changedStates.size(); i++) {
            var entityId = changedStates[i]["entity_id"];
            if (_entitiesStates.hasKey(entityId)) {
                _entitiesStates[entityId]["state"] = changedStates[i]["state"];
                _entitiesStates[entityId]["attributes"] = changedStates[i]["attributes"];
                _entitiesStates[entityId]["last_changed"] = changedStates[i]["last_changed"];
            }
        }

        App.getApp().viewController.removeLoader();
    }

    /*
    * Executes action on entity, script or scene
    * Entity is toggled
    */
    function toggleEntityState(id, type, currState) {
        var action = null;
        var loadingText = currState.equals(STATE_ON) ? Rez.Strings.LoaderTurningOff : Rez.Strings.LoaderTurningOn;

        switch(type) {
            case ENTITY_TYPE_AUTOMATION:
                //TODO USE TOGGLE
                action = currState.equals(STATE_ON) ? Client.ENTITY_ACTION_TURN_OFF : Client.ENTITY_ACTION_TURN_ON;
                break;
            case ENTITY_TYPE_INPUT_BOOLEAN:
                //TODO USE TOGGLE
                action = currState.equals(STATE_ON) ? Client.ENTITY_ACTION_TURN_OFF : Client.ENTITY_ACTION_TURN_ON;
                break;
            case ENTITY_TYPE_LIGHT:
                //TODO USE TOGGLE
                action = currState.equals(STATE_ON) ? Client.ENTITY_ACTION_TURN_OFF : Client.ENTITY_ACTION_TURN_ON;
                break;
            case ENTITY_TYPE_LOCK:
                //TODO USE TOGGLE
                action = currState.equals(STATE_ON) ? Client.ENTITY_ACTION_TURN_OFF : Client.ENTITY_ACTION_TURN_ON;
                loadingText = currState.equals(STATE_LOCKED) ? Rez.Strings.LoaderUnlocking : Rez.Strings.LoaderLocking;
                break;
            case ENTITY_TYPE_SCENE:
                loadingText = Rez.Strings.LoaderLoading;
                break;
            case ENTITY_TYPE_SCRIPT:
                loadingText = Rez.Strings.LoaderRunning;
                break;
            case ENTITY_TYPE_SWITCH:
                //TODO USE TOGGLE
                action = currState.equals(STATE_ON) ? Client.ENTITY_ACTION_TURN_OFF : Client.ENTITY_ACTION_TURN_ON;
                break;
            default:
                return false;
        }

        App.getApp().viewController.showLoader(loadingText);
        client.setEntityState(id, type, action, new Lang.Method(Hass, :onToggleEntityStateCompleted), null);

        return true;
    }

    /**
    * Manualy executes action with optional parameters.
    * These are used for setting attributes like brightness
    */
    function setEntityState(id, type, action, params) {
        App.getApp().viewController.showLoader(Rez.Strings.LoaderRunning);
        client.setEntityState(id, type, action, new Lang.Method(Hass, :onToggleEntityStateCompleted), params);

        return true;
    }

    /**
    * Read manualy defined scene entities through connect iq
    */
    function importScenesFromSettings() {
        var sceneString = App.Properties.getValue("scenes");
        if (sceneString == null || sceneString.equals("")) {return;}

        // remove old entities from states dict and entities array
        var entitToRemoveFromDict = _entities.slice(_groupEntitiesCount, _entities.size());
        for (var i=0; i < entitToRemoveFromDict.size(); i++) {
            _entitiesStates.remove(entitToRemoveFromDict[i]);
        }
        _entities = _entities.slice(0, _groupEntitiesCount);

        var run = true;
        do {
            var comPos = sceneString.find(",");
            var extractedScene;

            // extract one scene after another when sepparated by comma
            if (comPos == null) {
                extractedScene = sceneString;
                run = false;
            } else {
                extractedScene = sceneString.substring(0, comPos);
                sceneString = sceneString.substring(comPos+1, sceneString.length());
            }

            // remove white space from begin of string if present
            var spacPos = extractedScene.find(" ");
            while (spacPos != null) {
                extractedScene = extractedScene.substring(spacPos+1, extractedScene.length());
                spacPos = extractedScene.find(" ");
            }

            // extract manually defined name using equals sign if present
            var eqPos = extractedScene.find("=");
            var extractedSceneName = null;
            if (eqPos != null) {
                extractedSceneName = extractedScene.substring(eqPos+1, extractedScene.length());
                extractedScene  = extractedScene.substring(0,eqPos);
            }

            // add prefix "scene." if not specified
            if (extractedScene.find("scene.") == null) {
                extractedScene = "scene." + extractedScene;
            }

            _entities.add(extractedScene);
            _entitiesStates.put(extractedScene,
                              {"attributes" => {"friendly_name" => (extractedSceneName == null ? extractedScene : extractedSceneName)},
                               "state" => "scening"});
        } while (run);
    }
}