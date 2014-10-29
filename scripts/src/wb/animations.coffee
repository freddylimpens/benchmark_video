wbAnimations = angular.module('wbAnimations', ['ngAnimate'])

wbAnimations.animation('.intro', ()->

    exitIntro = (element, className, done)-> 
        console.log(" [Animate] Exit intro ! element = ", $(element)[0])
        console.log(" [Animate] Exit intro ! element = ", jQuery(element)[0])
        console.log(" [Animate] Exit intro ! element = ", angular.element(element))
        console.log(" [Animate] Exit intro ! element = ", jQuery($(element)[0])[0] )
        console.log(" [Animate] done = ", done)
        if className != 'active'
            return
        el = $(element)[0]
        elt = angular.element(el)
        #elem = $(elem)
        console.log(" Elem before animate", elt)
        
        elt.animate({
                top:-elt.height()
            }, 
            {   
                'duration': 1200,
                'easing': 'easeInOutExpo',
                'complete': ()->
                        elt.hide()
            }
            )

        return (cancel)->
            if (cancel) 
                element.stop()
                return true
            
        
    
    return {
        removeClass: exitIntro
        }
    )
