 using Toybox.WatchUi;
 
 class TextView extends WatchUi.View {

    private var d_msg;
    
    hidden var d_textarea;

    // Constructor
    function initialize(msg) {
        View.initialize();

		d_msg = msg;
    }
    
    function onShow() {
    	d_textarea = new WatchUi.TextArea({
    		:text => d_msg,
    		:color => Graphics.COLOR_WHITE,
    		:font => [ Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY ],
    		:justification => Graphics.TEXT_JUSTIFY_CENTER,
    		:locX => WatchUi.LAYOUT_HALIGN_CENTER,
    		:locY => WatchUi.LAYOUT_VALIGN_CENTER,
            :width=>160,
            :height=>160,
    	});
    }
    	

    // Update the View
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        d_textarea.draw(dc);
    }
}