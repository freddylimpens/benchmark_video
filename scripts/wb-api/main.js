
/*
**  scripts
*/

;(function($) 
{
    /*
    **  vars
    */

    var 
        // dom
        $window = $(window),
        $html = $('html'),
        $body = $('body'),
        $main = $('#main'),
        $content = $('#content'),
        $scrollElement = $('html,body');

    /*
    **  common
    */

    $.fn.Home = function() 
    {
        return this.each(function()
        {
            var $this = $(this),
                $intro = $this.find('.intro'),
                $panel = $this.find('.panel'),
                $themes = $panel.children('.themes'),
                _enable_panel = true,
                _scale = 1,
                _min_scale = 0.06,
                _max_scale = 1,
                _is_touch = Modernizr.touch;

            // init
            function _init()
            {
                // init
                _initCommon();
                _initPanel();
                _initThemes();
                _initPosts();
                _initIntro();

                // scale
                _setScale(_min_scale);
            }

            function _initCommon()
            {
                // external href
                $this._ExternalHref();

                // alt
                $('img').attr('alt', '');

                // black / White
                $('.bw')._ImgBW();

                // fancybox
                $('.fancybox').fancybox({
                    padding     : 0,
                    maxWidth    : 800,
                    maxHeight   : 600,
                    fitToView   : false,
                    width       : '70%',
                    height      : '90%',
                    autoSize    : false,
                    closeClick  : false,
                    openEffect  : 'none',
                    closeEffect : 'none',
                    tpl: {
                        next : '<a title="Next" class="fancybox-nav fancybox-next fancybox-wb-next" href="javascript:;"></a>',
                        prev : '<a title="Previous" class="fancybox-nav fancybox-prev fancybox-wb-prev" href="javascript:;"></a>',
                        closeBtn: '<a title="Close" class="fancybox-item fancybox-close fancybox-wb-close" href="javascript:;"></a>'
                    },
                    helpers : {
                        overlay : {
                            css : {
                                'background' : 'rgba(255, 255, 255, 0.95)'
                            }
                        }
                    }
                });
            }

            function _initPanel()
            {
                // position
                var x = - (($panel.width() - $window.width())/2);
                var y = - (($panel.height() - $window.height())/2);
                $panel.css({'left': x, 'top': y });

                // drag
                var click = {x: 0, y: 0};
                $themes
                    .draggable({
                        cursor: 'move',
                        start: function(event) 
                        {
                            click.x = event.clientX;
                            click.y = event.clientY;
                        },
                        drag: function(event, ui) 
                        {
                            var original = ui.originalPosition;
                            var velX = (event.clientX - click.x);
                            var velY = (event.clientY - click.y);

                            velX = velX * (1 / _scale);
                            velY = velY * (1 / _scale);

                            ui.position = {
                                'left': original.left + velX,
                                'top': original.top + velY
                            };
                        }
                    });

                // scale
                $panel.bind('mousewheel', function(event, delta) 
                {
                    if (!_enable_panel) return false;

                    if (delta > 0) {
                        _zoom(0.05);
                    }
                     else if(delta < 0) {
                        _zoom(-0.05);
                    }
                });

                // key event
                $window.on('keydown', function(event)
                {
                    if (!_enable_panel) return false;

                    switch (event.keyCode)
                    {
                        case 65:
                            break;

                        case 90:
                            break;
                    }
                    return false;
                });
            }

            function _initThemes()
            {
                $themes
                    .find('.theme')
                    .each(function()
                    {
                        var $this = $(this);

                        // positions
                        $this.css({
                            'top': $this.data('top'),
                            'left': $this.data('left'),
                            'z-index': $this.data('z-index')
                        });

                        // coordinates
                        _createCoordinates($this, '/theme/update');

                        // drag
                        _dragElement($this);
                    });
            }

            function _initPosts()
            {
                $panel
                    .find('.post')
                    .each(function()
                    {
                        var $this = $(this);

                        // position
                        $this.css({
                            'top': $this.data('top'),
                            'left': $this.data('left'),
                            'z-index': $this.data('z-index')
                        });

                        // width
                        if ( $this.data('width') )
                        {
                            $this.css('width', $this.data('width'));
                        };

                        // coordinates
                        _createCoordinates($this, '/post/update');

                        // drag
                        _dragElement($this);
                    });
            }

            // intro
            function _initIntro() 
            {
                var $loader = $intro.find('.loader');
                var $enter = $intro.find('.enter');
                var $notEnter = $intro.find('.not-enter');

                $loader.fadeOut('normal', function()
                {
                    if (!Modernizr.csstransforms)
                    {
                        $notEnter.fadeIn('normal');
                    }
                     else
                    {
                        $enter.fadeIn('normal', function(){
                            $enter
                                .children('span')
                                    .css('cursor', 'pointer')
                                    .click(function(){
                                        _exitIntro();
                                    });
                        });
                    }
                });
            }

            function _exitIntro() 
            {
                $intro
                    .animate({
                            top:-$intro.height()
                        }, 
                        1200, 
                        'easeInOutExpo',
                        function(){
                            $intro.hide();
                        });
            }

            // state
            function _zoom (inc) 
            {
                var scale = _scale + inc;
                _setScale(scale);
            }

            function _setScale (scale) 
            {
                scale = Math.max(_min_scale, scale);
                scale = Math.min(_max_scale, scale);
                _scale = scale;
                var transformScale = 'scale('+ scale +')';
                $panel.css({
                    '-webkit-transform': transformScale,
                    '-moz-transform': transformScale,
                    '-o-transform': transformScale,
                    'transform': transformScale
                });
            }

            // utils
            function _dragElement (element)
            {
                var $element = $(element);
                var click = {x: 0, y: 0};
                var original = _getCoordinates($element);

                $element
                    .draggable({
                        cursor: 'move',
                        start: function(event) 
                        {
                            original = _getCoordinates($element);
                            click.x = event.clientX;
                            click.y = event.clientY;
                        },
                        drag: function(event, ui) 
                        {
                            var velX = event.clientX - click.x;
                            var velY = event.clientY - click.y;

                            velX = velX * (1 / _scale);
                            velY = velY * (1 / _scale);

                            var top = original.top + velY;
                            var left = original.left + velX;

                            ui.position = {
                                'left': left,
                                'top': top
                            };

                            _setCoordinatesInfo($element, top, left);
                        }
                    });
            }

            function _createCoordinates (element, url)
            {
                var $element = $(element);
                var $coordinates = $('<div class="coordinates" />');
                var $info = $('<div class="info" />');
                var $submit = $('<div class="submit">Submit</div>');

                // append
                $coordinates.append($info);
                $coordinates.append($submit);
                $element.append($coordinates);

                // set coordinates
                _setCoordinatesInfo(
                    $element, 
                    $element.position().top,
                    $element.position().left
                );

                // submit
                $submit.click(function()
                {
                    $submit.html('Send');

                    var id = $element.data('id');
                    var top = $coordinates.data('top');
                    var left = $coordinates.data('left');

                    $.ajax({
                        url: url,
                        type : 'GET',
                        data : 'id=' + id + '&top=' + top  + '&left=' + left,
                        context: document.body
                    })
                    .done(function( data ) 
                    {
                        $submit.html('Done');

                        setTimeout(function(){
                             $submit.html('Submit');
                        }, 500);
                    });
                });
            }

            function _getCoordinates (element)
            {
                var $coordinates = $(element).children('.coordinates');
                return {
                    'top': $coordinates.data('top'), 
                    'left': $coordinates.data('left')
                };
            }

            function _setCoordinatesInfo (element, top, left)
            {
                var $element = $(element);
                var $coordinates = $element.children('.coordinates');
                var $info = $coordinates.children('.info');
                var top = Math.round(top);
                var left = Math.round(left);

                $coordinates.data('top', top);
                $coordinates.data('left', left);
                $info.html('top: ' + top + ' <br /> ' + 'left: ' +  left);
            }

            // start
            _init();
        });
    };

    /*
    **  plugins
    */

    $.fn._ExternalHref = function() 
    {
        return this.find("a[href^='http://'], a[href^='https://']").each(function() {
            this.target = '_blank';
        });
    };

    $.fn._ImgBW = function() 
    {
        return this.each(function()
        {
            var $this = $(this);
            var $img = $this.find('img');
            var src = $img.attr('src');

            if ($img.length)
            {
                $img.load(function()
                {
                    var $img_bw;
                    $img
                        .addClass('img')
                        .clone()
                        .addClass('img-bw')
                        .insertBefore($img)
                        .queue(function()
                        {
                            $img_bw = $(this);
                            $img_bw.dequeue();
                        });

                    var src_bw = grayscale($img_bw.attr('src'));
                    $img_bw.attr('src', src_bw);

                    $img.hide();
                    $this.hover(
                        function(){
                            $img_bw.hide();
                            $img.show();
                        }, 
                        function(){
                            $img_bw.show();
                            $img.hide();
                        });
                });
                $img.attr('src', src);
            }
        });
    };

    /*
    **  grayscale
    */

    function grayscale (src)
    {
        var canvas = document.createElement('canvas');
        var ctx = canvas.getContext('2d');
        var imgObj = new Image();
        imgObj.src = src;
        canvas.width = imgObj.width;
        canvas.height = imgObj.height; 
        ctx.drawImage(imgObj, 0, 0); 
        var imgPixels = ctx.getImageData(0, 0, canvas.width, canvas.height);
        for (var y = 0; y < imgPixels.height; y++)
        {
            for(var x = 0; x < imgPixels.width; x++)
            {
                var i = (y * 4) * imgPixels.width + x * 4;
                var avg = (imgPixels.data[i] + imgPixels.data[i + 1] + imgPixels.data[i + 2]) / 3;
                imgPixels.data[i] = avg; 
                imgPixels.data[i + 1] = avg; 
                imgPixels.data[i + 2] = avg;
            }
        }
        ctx.putImageData(imgPixels, 0, 0, 0, 0, imgPixels.width, imgPixels.height);
        return canvas.toDataURL();
    }

})(jQuery);

/*
** on load
*/

$(function() 
{
    $('.main-home').Home();
});
