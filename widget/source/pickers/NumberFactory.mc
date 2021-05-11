using Toybox.Graphics;
using Toybox.WatchUi;

/**
* Number picker factory used for typing numbers
*/
class NumberFactory extends WatchUi.PickerFactory {
    hidden var mStart;
    hidden var mStop;
    hidden var mIncrement;
    hidden var mFormatString;
    hidden var mFont;

    function initialize(start, stop, increment, options) {
        PickerFactory.initialize();

        mStart = start;
        mStop = stop;
        mIncrement = increment;

        if(options != null) {
            mFormatString = options.get(:format);
            mFont = options.get(:font);
        }

        if(mFont == null) {
            mFont = Graphics.FONT_NUMBER_MEDIUM;
        }

        if(mFormatString == null) {
            mFormatString = "%d";
        }
    }

    function getDrawable(index, selected) {
        return new WatchUi.Text( { :text=>getValue(index).format(mFormatString), :color=>Graphics.COLOR_WHITE, :font=> mFont, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER } );
    }

    function getValue(index) {
        return mStart + (index * mIncrement);
    }

    function getSize() {
        return ( mStop - mStart ) / mIncrement + 1;
    }

}
