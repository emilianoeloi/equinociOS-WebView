(function(){
	window.cookieMng = {
		"set": function(cname,value){
			document.cookie=cname+"="+value;
		},
		"get": function(cname){
    		var name = cname + "=";
    		var ca = document.cookie.split(';');
    		for(var i=0; i<ca.length; i++) {
        		var c = ca[i];
        		while (c.charAt(0)==' ') c = c.substring(1);
        		if (c.indexOf(name) == 0) 
        			return c.substring(name.length,c.length);
    		}
    		return "";
		},
		"delete": function(cname){
			document.cookie=cname+"=";
		}
	}
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