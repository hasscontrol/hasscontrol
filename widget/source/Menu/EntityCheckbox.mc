using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class EntityCheckbox extends Ui.CheckboxMenuItem {
  var entity;

  function initialize(ent) {
    CheckboxMenuItem.initialize(
      ent.getName(),
      "",
      ent.getId(),
      ent.shouldShow(),
      {}
    );

    entity = ent;
  }
}