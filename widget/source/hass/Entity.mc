
class Entity {
  static const HASS_STATE_ON = "on";
  static const HASS_STATE_OFF = "off";
  static const HASS_STATE_UNKNOWN = "unknown";

  static enum {
    STATE_ON,
    STATE_OFF,
    STATE_UNKNOWN
  }

  static function createFromDict(dict) {
    return new Entity({
      :id => dict["id"],
      :name => dict["name"],
      :state => dict["state"],
      :ext => dict["ext"],
    });
  }

  static function stringToState(stateInText) {
    if (stateInText == null) {
      return null;
    }
    if (Entity.HASS_STATE_ON.equals(stateInText)) {
      return Entity.STATE_ON;
    }
    if (Entity.HASS_STATE_OFF.equals(stateInText)) {
      return Entity.STATE_OFF;
    }

    return Entity.STATE_UNKNOWN;
  }

  static function stateToString(state) {
    if (state == Entity.STATE_ON) {
      return Entity.HASS_STATE_ON;
    }
    if (state == Entity.STATE_OFF) {
      return Entity.HASS_STATE_OFF;
    }

    if (state == null) {
      return null;
    }

    return Entity.HASS_STATE_UNKNOWN;
  }



  enum {
    TYPE_SCENE,
    TYPE_LIGHT,
    TYPE_SWITCH,
    TYPE_AUTOMATION,
    TYPE_UNKNOWN
  }

  hidden var _mId; // Home assistant id
  hidden var _mType; // Type of entity
  hidden var _mName; // Name
  hidden var _mState; // Current State
  hidden var _mExt; // Is this entity loaded from settings?

  function initialize(entity) {
    _mId = entity[:id];
    _mName = entity[:name];
    _mState = Entity.stringToState(entity[:state]);
    _mExt = entity[:ext] == true;

    if (_mId.find("scene.") != null) {
      _mType = TYPE_SCENE;
    } else if (_mId.find("light.") != null) {
      _mType = TYPE_LIGHT;
    } else if (_mId.find("switch.") != null) {
      _mType = TYPE_SWITCH;
    } else if (_mId.find("automation.") != null) {
      _mType = TYPE_AUTOMATION;
    } else {
      _mType = TYPE_UNKNOWN;
    }
  }

  function getId() {
    return _mId;
  }

  function getName() {
    return _mName;
  }

  function setName(newName) {
    _mName = newName;
  }

  function getType() {
    return _mType;
  }

  function setState(newState) {
    if (newState instanceof String) {
      _mState = Entity.stringToState(newState);
      return;
    }

    if (
      newState != null
      && newState != Entity.STATE_ON
      && newState != Entity.STATE_OFF
      && newState != Entity.STATE_UNKNOWN
    ) {
      throw new InvalidValueException("state must be a valid Entity state");
    }

    _mState = newState;
  }

  function getState() {
    return _mState;
  }

  function isExternal() {
    return _mExt;
  }

  function toDict() {
    return {
      "id" => _mId,
      "name" => _mName,
      "state" => Entity.stateToString(_mState),
      "ext" => _mExt,
    };
  }

  function toString() {
    return toDict().toString();
  }
}
