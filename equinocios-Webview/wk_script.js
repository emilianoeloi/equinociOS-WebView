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
		setTimeout(function(){
			window.webkit.messageHandlers.observe.postMessage(document.title);
		},1000);
	}
	window.onload = function(){
		window.hideHeader();
		window.changeNavTitle();
	}
})()