
(:glance)
module Hass {
    const ENTITY_TYPE_ALARM_PANEL = "alarm_control_panel";
    const ENTITY_TYPE_AUTOMATION = "automation";
    const ENTITY_TYPE_BINARY_SENSOR = "binary_sensor";
    const ENTITY_TYPE_COVER = "cover";
    const ENTITY_TYPE_INPUT_BOOLEAN = "input_boolean";
    const ENTITY_TYPE_LIGHT= "light";
    const ENTITY_TYPE_LOCK = "lock";
    const ENTITY_TYPE_SCENE = "scene";
    const ENTITY_TYPE_SCRIPT = "script";
    const ENTITY_TYPE_SENSOR = "sensor";
    const ENTITY_TYPE_SWITCH = "switch";

    const STATE_ON = "on";
    const STATE_OFF = "off";
    const STATE_LOCKED = "locked";
    const STATE_UNLOCKED = "unlocked";

    enum {
        ERROR_TOKEN_REVOKED,
        ERROR_SERVER_NOT_REACHABLE,
        ERROR_NOT_FOUND,
        ERROR_NOT_AUTHORIZED,
        ERROR_INVALID_URL
    }
}