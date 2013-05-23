// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function flash_success(message) {
	$('flash_container').hide();
	$('flash_container').innerHTML = message;
	$('flash_container').addClassName('green');
	Effect.Appear('flash_container');
	setTimeout("Effect.Fade('flash_container');",5*1000);
}

function flash_error(message) {
	$('flash_container').hide();
	$('flash_container').innerHTML = message;
	$('flash_container').addClassName('red');
	Effect.Appear('flash_container');
	setTimeout("Effect.Fade('flash_container');",5*1000);
}

// http://radio.javaranch.com/pascarello/2006/08/17/1155837038219.html
var chatscroll = new Object();
chatscroll.Pane = function(scrollContainerId){
	this.bottomThreshold = 20;
	this.scrollContainerId = scrollContainerId;
	this._lastScrollPosition = 100000000;
}

chatscroll.Pane.prototype.activeScroll = function(){

	var _ref = this;
	var scrollDiv = document.getElementById(this.scrollContainerId);
	var currentHeight = 0;

	var _getElementHeight = function(){
		var intHt = 0;
		if(scrollDiv.style.pixelHeight)intHt = scrollDiv.style.pixelHeight;
		else intHt = scrollDiv.offsetHeight;
		return parseInt(intHt);
	}

	var _hasUserScrolled = function(){
		if(_ref._lastScrollPosition == scrollDiv.scrollTop || _ref._lastScrollPosition == null){
			return false;
		}
		return true;
	}

	var _scrollIfInZone = function(){
		if( !_hasUserScrolled || 
			(currentHeight - scrollDiv.scrollTop - _getElementHeight() <= _ref.bottomThreshold)){
				scrollDiv.scrollTop = currentHeight;
				_ref._isUserActive = false;
			}
	}


	if (scrollDiv.scrollHeight > 0)currentHeight = scrollDiv.scrollHeight;
	else if(scrollDiv.offsetHeight > 0)currentHeight = scrollDiv.offsetHeight;

	_scrollIfInZone();

	_ref = null;
	scrollDiv = null;
}

function calc_quota(quota, units) {
    quota = parseInt(quota);
	if (units == 'TB')
		quota *= 1099511627776; // terabyte
	else if (units == 'GB')
		quota *= 1073741824; // gigabyte
	else
		quota *= 1048576; // megabyte
	return quota;
}

function show_dialog() {
    //$('appdialog').style.display=''; //show();
	Effect.SlideDown('appdialog',{duration:0.5});
}
function hide_dialog() {
	Effect.SlideUp('appdialog',{duration:0.5});
}
