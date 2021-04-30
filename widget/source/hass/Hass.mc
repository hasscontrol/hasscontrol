using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System;

using Utils;

(:glance)
module Hass {
    const STORAGE_KEY = "hass_imported_entities";
    const supportedEntityTypes = [
        ENTITY_TYPE_AUTOMATION,
        ENTITY_TYPE_BINARY_SENSOR,
        ENTITY_TYPE_INPUT_BOOLEAN,
        ENTITY_TYPE_LIGHT,
        ENTITY_TYPE_LOCK,
        ENTITY_TYPE_SCENE,
        ENTITY_TYPE_SCRIPT,
        ENTITY_TYPE_SENSOR,
        ENTITY_TYPE_SWITCH
    ];
    var client = null;
    var _importedEntities = [];
    var _entityStates = {};
    var _entityToRefreshCounter = 0;
    var _entityRefreshingSilent = false;

    function initClient() {
        client = new Client();
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
        return _entityStates.get(entityId);        
    }
  
    /**
    * Returns list of imported entity ids
    */
    function getImportedEntities() {
        return _importedEntities;
    }
    
    /**
    * Helper callback method used for extracting data from single
    * entity response.
    */
    function _onRecievedGeneralEntity(err, data) {
        if (err != null) {
            if (_entityRefreshingSilent) {return;}
        
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
        _entityStates.put(data[:body]["entity_id"], entityDict);
    }
  
    /**
    * Callback when single entity state is returned form HASS
    */
    function _onReceivedSingleEntity(err, data) {
        _onRecievedGeneralEntity(err, data);
    }
    
    /**
    * Callback when state of entity is returned form HASS.
    * This function is used only when refreshing all imported
    * entities at once. We have to call one web request after
    * another, otherwise the app will crash.
    */
    function _onReceivedRefreshedImportedEntity(err, data) {
        _onRecievedGeneralEntity(err, data);
        
        _entityToRefreshCounter++;
        if (_entityToRefreshCounter < _importedEntities.size()) {
            // we have to keep refreshing until we achieve end of list
            client.getEntity(_importedEntities[_entityToRefreshCounter], null, Utils.method(Hass, :_onReceivedRefreshedImportedEntity));
        } else {
            // all entities are refreshed, remove loader and resets silent refresher
            App.getApp().viewController.removeLoader();
            _entityRefreshingSilent = false;
        }
    }

    /**
    * Requests state of single entity from HASS
    */
    function refreshSingleEntity(entityId) {
        client.getEntity(entityId, null, Utils.method(Hass, :_onReceivedSingleEntity));
    }
  
    /**
    * Requests state of all imported entities from HASS
    */
  	function refreshImportedEntities(silent) {
  	    if(_importedEntities.size() < 1) {return;}
  	    
  	    _entityToRefreshCounter = 0;
  	    _entityStates = {};
  	    _entityRefreshingSilent = silent;
  	    client.getEntity(_importedEntities[_entityToRefreshCounter], null, Utils.method(Hass, :_onReceivedRefreshedImportedEntity));
  	}

	/**
	* Callback called when HASS returns list with entities from the group
	*/
    function _onReceivedGroupEntities(err, data) {
        if (err) {
            App.getApp().viewController.showError(err);
            return;
        }
  
        _importedEntities = new [0];
        var recvEntities = data[:body]["attributes"]["entity_id"];
        for (var i = 0; i < recvEntities.size(); i++) {
      	    var recvEntityType = recvEntities[i].substring(0, recvEntities[i].find("."));
      	    if (supportedEntityTypes.indexOf(recvEntityType) != -1) {
      	        _importedEntities.add(recvEntities[i]);
      	    }
      	}
        
        storeGroupEntities();

        refreshImportedEntities(false);
    }
    
    /**
    * Stores entities from synchronized group into storage
    */
    function storeGroupEntities() {
        App.Storage.setValue(STORAGE_KEY, _importedEntities);
    }
    
    /**
    * Loads entities from previously synchronized group from storage
    */
    function loadGroupEntities() {
        var grEnt = App.Storage.getValue(STORAGE_KEY);
        if (grEnt instanceof Toybox.Lang.Array) {
            _importedEntities = grEnt;
        } else {
            _importedEntities = [];
        }
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
        client.getEntity(group, null, Utils.method(Hass, :_onReceivedGroupEntities));
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
            if (_entityStates.hasKey(entityId)) {
                _entityStates[entityId]["state"] = changedStates[i]["state"];
                _entityStates[entityId]["last_changed"] = changedStates[i]["last_changed"];
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
    client.setEntityState(id, type, action, Utils.method(Hass, :onToggleEntityStateCompleted));
    
    return true;
  }
}