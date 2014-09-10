//"use strict";
//document.domain = "arte.tv";

var arte_vp_player;
var arte_vp;

//too risky
/*if(document.domain != "arte.tv" && !document.getElementsByTagName("body")[0].className.match(/not-front/)){
    
    var s = document.createElement('script');
    s.type = 'text/javascript';
    var code = 'document.domain="arte.tv"';
    try {
        s.appendChild(document.createTextNode(code));
        document.body.insertBefore(s,document.body.firstChild);
    } catch (e) {
        s.text = code;
        document.body.insertBefore(s,document.body.firstChild);
    }
 
}*/

//var arte_vp_refresh = false; //setInterval for json refresh
function arte_vp_isNotDesktop() {
var check = false;
check =  /Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent);
return check;
}

// Find the right method, call on correct element
function arte_vp_launchFullScreen(element) {
  if(element.requestFullScreen) {
    element.requestFullScreen();
  } else if(element.mozRequestFullScreen) {
    element.mozRequestFullScreen();
  } else if(element.webkitRequestFullScreen) {
    element.webkitRequestFullScreen();
  }
}

function arte_vp_getCurrentHost(scriptName)
{
    //retrieve current server
    var scripts = document.getElementsByTagName('script');
    var prefix ="http://www.arte.tv/arte_vp/";
    for (var i = 0; i < scripts.length; i++)
    {
        if (scripts[i].src.match(new RegExp(scriptName,"g")))
        {
            if(
            scripts[i].src.indexOf("player.arte.tv/prod/")>-1 ||
            scripts[i].src.indexOf("www.arte.tv/playerv2/")>-1 ||
            scripts[i].src.indexOf("www.arte.tv/player/")>-1 ||
            scripts[i].src.indexOf("www.arte.tv/arte_vp")>-1 ||
            scripts[i].src.indexOf("develop.arte.tv/arte_vp/")> -1 ||
            scripts[i].src.indexOf("test.arte.tv/arte/arte_vp/")>-1
            )
            prefix = scripts[i].src.substring(0,scripts[i].src.indexOf(scriptName)).replace('/js','');
            
            if(
            scripts[i].src.indexOf("192.168")>-1 ||
            scripts[i].src.indexOf("dev.loc")>-1
            )
            prefix = "http://test.arte.tv/arte/arte_vp/";

        }
    }
    return prefix;
}
function arte_vp_get_browser_version(){
    var N=navigator.appName, ua=navigator.userAgent, tem;
    var M=ua.match(/(opera|chrome|safari|firefox|msie)\/?\s*(\.?\d+(\.\d+)*)/i);
    if(M && (tem= ua.match(/version\/([\.\d]+)/i))!== null) M[2]= tem[1];
    M=M? [M[1], M[2]]: [N, navigator.appVersion, '-?'];
    return M[1];
}

function arte_vp_get_browser(){
    var N=navigator.appName, ua=navigator.userAgent, tem;
    var M=ua.match(/(opera|chrome|safari|firefox|msie)\/?\s*(\.?\d+(\.\d+)*)/i);
    if(M && (tem= ua.match(/version\/([\.\d]+)/i))!== null) M[2]= tem[1];
    M=M? [M[1], M[2]]: [N, navigator.appVersion, '-?'];
    return M[0];
}
    
function arte_vp_isSafariLowerThan6() {
    return arte_vp_get_browser()=="Safari" && arte_vp_get_browser_version().substr(0,1)<6;
}
function arte_vp_readCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length,c.length);
    }
    return "";
}

function encodeData(s){
    return encodeURIComponent(s).replace(/\-/g, "%2D").replace(/\_/g, "%5F").replace(/\./g, "%2E").replace(/\!/g, "%21").replace(/\~/g, "%7E").replace(/\*/g, "%2A").replace(/\'/g, "%27").replace(/\(/g, "%28").replace(/\)/g, "%29");
}

function arte_vp_iframizator(video_wrapper_param)//jquery object
{
    console.log(" IFRAMIZATOR started")
    //never knows...
    video_wrapper_param.addClass('video-container');
    
    //default size
    var videoHeight = 406;
    var videoWidth = 720;
    
    video_wrapper_param.find('img').css('display', 'block'); //force image display block to prevent the +5px "bug"

    if(video_wrapper_param.height()===0)
    {
        video_wrapper_param.css('height',videoHeight);
        video_wrapper_param.css('width',videoWidth);
    }
    else
    {
        videoWidth = video_wrapper_param.width();
        videoHeight = video_wrapper_param.height();
    }
    
    //var buffer = video_wrapper_param;
    //video_wrapper_param.remove();
    //$(".span12.content").prepend(buffer);
    
    var json_url = "";
    var prefix = arte_vp_getCurrentHost("main.js");
    var autostart = "";
    var rendering_place = "";
    var player_code ="";
    
    if(typeof(video_wrapper_param.attr("arte_vp_url")) !== "undefined")
    json_url = video_wrapper_param.attr("arte_vp_url");

    if(typeof(video_wrapper_param.attr("arte_vp_live-url")) !== "undefined")
    json_url = video_wrapper_param.attr("arte_vp_live-url");
   
    if(typeof(video_wrapper_param.attr("arte_vp_rendering_place")) !== "undefined")
    rendering_place = video_wrapper_param.attr("arte_vp_rendering_place");
    else
    rendering_place = window.location.href;
         
    /*if(typeof(video_wrapper_param.attr("arte_vp_autostart")) !== "undefined")
    autostart = video_wrapper_param.attr("arte_vp_autostart");
    else
    autostart = 0;*/
    
    if(arte_vp_isNotDesktop() || arte_vp_isSafariLowerThan6())
    {
        player_code = "<div id='arte_vp_jwplayer_iframe' class='arte_vp_jwplayer_iframe' style='display:none;position:absolute;z-index:2000;top:0;left:0;overflow:hidden;transition-duration:0;transition-property:no;background-color:#000000;width:"+videoWidth+"px;height:"+videoHeight+"px'><iframe style='transition-duration:0;transition-property:no;margin:0 auto;position:relative;display:block;background-color:#000000;' frameborder='0' scrolling='no' width='"+videoWidth+"px' height='"+videoHeight+"px' src='%prefix%index.php?json_url=%json_url%&lang=%lang%&config=%config%&rendering_place=%rendering_place%' allowFullScreen></iframe></div>";
    }
    else
    {
        player_code = "<div id='arte_vp_jwplayer_iframe' class='arte_vp_jwplayer_iframe' style='display:none;position:absolute;z-index:2000;top:0;left:0;overflow:hidden;transition-duration:0;transition-property:no;background-color:#000000;width:100%;height:100%'><iframe style='transition-duration:0;transition-property:no;margin:0 auto;position:relative;display:block;background-color:#000000;' frameborder='0' scrolling='no' width='100%' height='100%'  src='%prefix%index.php?json_url=%json_url%&lang=%lang%&config=%config%&rendering_place=%rendering_place%' allowFullScreen></iframe></div>";
    }
    player_code = player_code.replace("%prefix%",prefix);
    player_code = player_code.replace("%json_url%",encodeData(json_url));
    player_code = player_code.replace("%lang%",encodeURIComponent(video_wrapper_param.attr("arte_vp_lang")));
    player_code = player_code.replace("%config%",encodeURIComponent(video_wrapper_param.attr("arte_vp_config")));
    player_code = player_code.replace("%rendering_place%",encodeURIComponent(rendering_place));
    //player_code = player_code.replace("%autostart%",autostart);   
   
    //then append fresh player
    video_wrapper_param.append(player_code);

    //let's be smooth
    video_wrapper_param.find(".arte_vp_jwplayer_iframe").fadeIn();
}

//iframe generator for couch mode
function arte_vp_couch_mode_iframizator(couchmode_param)//jquery object
{

    var playlist_url = "";
    var prefix = arte_vp_getCurrentHost("main.js");
    var autostart = "";
    var rendering_place = "";
    var start_index = 0;

    if(typeof(couchmode_param.attr("arte_vp_json_playlist_url")) !== "undefined")
    playlist_url = couchmode_param.attr("arte_vp_json_playlist_url");
    
    if(typeof(couchmode_param.attr("arte_vp_rendering_place")) !== "undefined")
    rendering_place = couchmode_param.attr("arte_vp_rendering_place");
    else
    rendering_place = window.location.href;
    
    if(typeof(couchmode_param.attr("arte_vp_start_index")) !== "undefined")
    start_index = couchmode_param.attr("arte_vp_start_index");

    var player_code = "<div id='arte_vp_jwplayer_iframe' class='arte_vp_jwplayer_iframe' style='display:none;position:absolute;z-index:2000;top:0;left:0;overflow:hidden;transition-duration:0;transition-property:no;background-color:#000000;width:"+$(window).width()+";height:"+$(window).height()+";'><iframe style='transition-duration:0;transition-property:no;margin:0 auto;position:relative;display:block;background-color:#000000;' frameborder='0' scrolling='no' width='"+$(window).width()+"' height='"+$(window).height()+";'  src='%prefix%index.php?playlist_url=%playlist_url%&lang=%lang%&rendering_place=%rendering_place%&start_index=%start_index%'></iframe></div>";
    
    player_code = player_code.replace("%prefix%",prefix.replace('/js',''));
    player_code = player_code.replace("%playlist_url%",encodeURIComponent(playlist_url));
    player_code = player_code.replace("%lang%",encodeURIComponent(couchmode_param.attr("arte_vp_lang")));
    player_code = player_code.replace("%config%",encodeURIComponent(couchmode_param.attr("arte_vp_config")));
    player_code = player_code.replace("%rendering_place%",encodeURIComponent(rendering_place));
    player_code = player_code.replace("%start_index%",encodeURIComponent(start_index));
    
    $('body').prepend(player_code);
    
    $('body').find(".arte_vp_jwplayer_iframe").fadeIn();

}

function arte_vp_set_player_fullscreensize() {

    window.parent.$("#arte_vp_jwplayer_iframe,#arte_vp_jwplayer_iframe iframe").css("width","100%");
    window.parent.$("#arte_vp_jwplayer_iframe,#arte_vp_jwplayer_iframe iframe").css("height","100%");
}

function arte_vp_load_jQuery(url, success) {
    
    if(!window.jQuery)
    {
        var script = document.createElement('script');
        script.src = url;
        var head = document.getElementsByTagName('head')[0],
                        done = false;
        // Attach handlers for all browsers
        script.onload = script.onreadystatechange = function() {
                if (!done && (!this.readyState
                                    || this.readyState == 'loaded'
                                    || this.readyState == 'complete')) {
                        done = true;
                        success();
                        script.onload = script.onreadystatechange = null;
                        head.removeChild(script);
                }
        };
        head.appendChild(script);
    }
    else
    {
        success();
    }
}

arte_vp_load_jQuery('https://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js',function() {
    (function( $ ) {
        console.log(" Starting in vp load jquery")
        var clicked_player = null;
        window.loaded = null;
                
        $("div[arte_vp_url],div[arte_vp_live-url]").each(function( index ) {
            if($(this).css("position") == "static")
            $(this).css("position","relative");
        });
        
        //catch all normal video
        $(document).on("click touchstart",".arte_vp_trigger",function(event){
            console.log(" click on normal -trigger video ??")
            //try arte_vp_trigger must be in video-container
            clicked_player = jQuery(this).parent("div[arte_vp_url],div[arte_vp_live-url]");
                            
            if(window.loaded)
            arte_vp_iframizator(clicked_player);
            
            return false;
        });
        
        //catch all normal video
        $(document).on("click touchstart","div[arte_vp_url],div[data-url]",function(event){
            console.log(" click on normal video ?? ")
            //retro compat izi
            if(typeof($(this).attr("data-url") !== "undefined"))
            {
                $(this).attr("arte_vp_url",$(this).attr("data-url"));
                $(this).attr("arte_vp_config",$(this).attr("data-config"));
                $(this).attr("arte_vp_lang",$(this).attr("data-lang"));
            }
            
            if($(this).find(".arte_vp_trigger").length === 0)
            {
                clicked_player = jQuery(this);
                if(window.loaded)
                arte_vp_iframizator(clicked_player);
            }
            return false;
        });

        //catch all live 
        $(document).on("click touchstart","div[arte_vp_live-url]",function(event){
            console.log(" click on normal --live video ??")
            if($(this).find(".arte_vp_trigger").length === 0)
            {
                //add missing lang data on tvguide live video
                if(jQuery(this).attr("arte_vp_live-url") !== "")
                {
                    clicked_player = jQuery(this);
                    if(window.loaded)
                    arte_vp_iframizator(clicked_player);
                }
            }
            return false;
        });
        
        
        //Special widget catch all
        $(document).on("click touchstart","#widget-prog div[arte_vp_url]",function(event){
            console.log(" click on normal --catch all -- video ??")
            //add missing lang data on tvguide live video
            if(jQuery(this).attr("arte_vp_url") !== "")
            {
                clicked_player = jQuery(this);
                if(window.loaded)
                arte_vp_iframizator(clicked_player);
            }
            return false;
        });

        //one again hotfix of tvguide
        $(document).on("click touchstart",".overlay",function(event){
            console.log(" click on normal --ovelay video ??")
            $(this).parents("div.video-block").find(".video-container").trigger("click");

        });
        
        //autostart something ?

        //fallback
        //jQuery("div[data-autostart=1]").attr("arte_vp_autostart","1");
        //jQuery("div[arte_vp_autostart=1]").trigger("click");
        //case mobile immediately instantiate player if config is set, but only the first one (if not destroy the others)
        if(arte_vp_isNotDesktop())
        {
            setTimeout(function(){
                $("div[arte_vp_url]").each(
                    function(index) {
                        if(
                            typeof(jQuery(this).attr("arte_vp_url")) !== "undefined"
                            && jQuery(this).attr("arte_vp_autostart") != "1"
                        )
                        {
                            jQuery(this).trigger("click");
                            return false;
                        }
                    }
                );
            },1000);
        }

        //couch mode
        $(document).on("click touchstart","a[arte_vp_json_playlist_url]",function(event){

            if(jQuery(this).attr("arte_vp_json_playlist_url"))
            {
                //instantiate
                jQuery(this).unbind("click");
                arte_vp_couch_mode_iframizator(jQuery(this));
        
                //resize couchmode fullscreenmode       
                if($('#qunit').length === 0 && window.location.hostname !== "test.arte.tv") {
                    document.getElementById("arte_vp_jwplayer_iframe").onwebkitfullscreenchange = arte_vp_set_player_fullscreensize;
                    document.getElementById("arte_vp_jwplayer_iframe").onmozfullscreenchange = arte_vp_set_player_fullscreensize;
                    document.getElementById("arte_vp_jwplayer_iframe").onfullscreenchange = arte_vp_set_player_fullscreensize;

                    arte_vp_launchFullScreen(document.getElementById("arte_vp_jwplayer_iframe"));
                }
        
            }
            return false;
        });
                    
        $(window).load(function() {
            console.log(" loading cliked player ??? ", clicked_player)
            window.loaded = true;
            if(clicked_player !== null)
            {
                arte_vp_iframizator(clicked_player);
                clicked_player = null;
            }
        });
        
    })(jQuery); 
});
