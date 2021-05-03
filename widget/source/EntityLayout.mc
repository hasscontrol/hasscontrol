using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi as Ui;

module EntityLayout {
    var _mTimerScrollBar = new Timer.Timer();
    var _mTimerScrollBarActive = false;
    var _mShowScrollBar = false;
    var _mLastIndex = -1;
    
    /**
    * Draws icon stored in resources xml
    */
    function drawIcon(dc, rezDrawable) {
        var drawable = Ui.loadResource(rezDrawable);
        dc.drawBitmap((dc.getWidth() / 2) - (drawable.getHeight() / 2),
                      (dc.getHeight() * 0.3) - (drawable.getHeight() / 2),
                      drawable);
    }
    
    function _drawText(dc, text, hP, fonts) {
        var vh = dc.getHeight();
        var vw = dc.getWidth();
        var cvh = vh / 2;
        var cvw = vw / 2;
        var fontHeight = vh * 0.3;
        var fontWidth = vw * 0.80;
        var font = fonts[0];

        for (var i = 0; i < fonts.size(); i++) {
            var truncate = i == fonts.size() - 1;
            var tempText = Graphics.fitTextToArea(text, fonts[i], fontWidth, fontHeight, truncate);

            if (tempText != null) {
                text = tempText;
                font = fonts[i];
                break;
            }
        }

        dc.drawText(cvw, cvh * hP, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    /**
    * Draws entity name
    */
    function drawName(dc, text) {
        _drawText(dc, text, 1.1, [Graphics.FONT_MEDIUM, Graphics.FONT_TINY, Graphics.FONT_XTINY]);
    }
    
    /**
    * Draws entity state instead of icon
    */
    function drawState(dc, text) {
        _drawText(dc, text, 0.5, [Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_TINY]);
    }
        
    /**
    * Hides scroll bar when timer expires
    */
    function _onTimerDone() {
        _mTimerScrollBarActive = false;
        _mShowScrollBar = false;
        Ui.requestUpdate();
    }
        
    /**
    * Draws scroll bar
    * Supports round and square display
    */
    function _drawScrollBar(dc, total, index) {
        var vh = dc.getHeight();
        var padding = 1;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setPenWidth(10);
        
        if (System.getDeviceSettings().screenShape == 3 /*SCREEN_SHAPE_RECTANGLE*/) {
            var barSize = ((vh * 0.9 - padding) - (vh * 0.1 - padding)) / total;
            var barStart = (vh * 0.1) + (barSize * index);
 
            dc.drawLine(10, vh * 0.1, 10, vh * 0.9);

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.setPenWidth(6);
            dc.drawLine(10, barStart, 10, barStart + barSize);
        } else { /* ROUND AND SEMIROUND */
            var cvh = vh / 2;
            var cvw = dc.getWidth() / 2;
            var radius = cvh - 10;
            var topDegreeStart = 130;
            var bottomDegreeEnd = 230;
            var barSize = ((bottomDegreeEnd - padding) - (topDegreeStart + padding)) / total;
            var barStart = (topDegreeStart + padding) + (barSize * index);
            var attr = Graphics.ARC_COUNTER_CLOCKWISE;

            dc.drawArc(cvw, cvh, radius, attr, topDegreeStart, bottomDegreeEnd);

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.setPenWidth(6);
            dc.drawArc(cvw, cvh, radius, attr, barStart, barStart + barSize);
        }
    }

    /**
    * Checks if scroll bar should be showed and draws it
    */
    function drawScrollBarIfNeeded(dc, total, index) {
        if (_mTimerScrollBarActive && _mShowScrollBar == true) {
            return;
        }

        if (_mLastIndex != index) {
            if (_mTimerScrollBarActive) {
                _mTimerScrollBar.stop();
            }
            _mShowScrollBar = true;
            _drawScrollBar(dc, total, index);
            _mTimerScrollBar.start(new Lang.Method(EntityLayout, :_onTimerDone), 1000, false);
        }

        _mLastIndex = index;
    }
}