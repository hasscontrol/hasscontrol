using Toybox.WatchUi as Ui;

class ProgressView extends Ui.ProgressBar {
    function initialize() {
      ProgressBar.initialize("", null);
    }

    function isActive() {
        return _isActive;
    }
}