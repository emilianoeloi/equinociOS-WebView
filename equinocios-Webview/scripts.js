(function(){
	window.isInnerEquinocios = function(){
		return document.location.hostname == "equinocios.com"
	}
	window.hideHeader = function(){
		var nav = document.querySelector("nav");
		if(nav && window.isInnerEquinocios()){
			document.body.removeChild(nav);
		}
	}
	window.changeNavTitle = function(){
		document.location.href = "JStoObjC://title="+document.title;
	}
	window.onload = function(){
		window.hideHeader();
		window.changeNavTitle();
	}
})();

