LeapPano
========

This project enables to add a panoramic image viewer on a website and to move the images with mouse and fingers. 
It uses Leap Motion to recognize movements with hands.
It's easily integrable. It use only JavaScript and HTML.

Demo
----

You can see a demo here : http://gcorbel.github.io/LeapPano/


How it works
------------

Here is a basic example :

    <!DOCTYPE html>
    <html lang="en">
      <head>
        <title>Demo of a panorama viewer with LeapMotion</title>
      </head>
      <body>

        <div id="container"></div>

        <script src="lib/three.js"></script>
        <script src="lib/leap.js"></script>
        <script src="lib/deepmerge.js"></script>
        <script src="lib/LeapPano.js"></script>
        <script type="text/javascript">
          window.onload = function() {
            pano = new LeapPano({container: 'container', files: ['images/basque.jpg'] })
            pano.init()

            Leap.loop({enableGestures: true}, function(frame) {
              pano.refresh(frame)
            })
          }

          function changeFile(file) {
            pano.setFilePath(file)
          }
        </script>
      </body>
    </html>

You can find this example here : https://github.com/GCorbel/LeapPano/blob/master/index.html

Options
-------

You can customize behaviour. This is the default options :

    container: null // The id of the containing div
    files: [] // Path to files. If there is many files, you can change the image by drawing a circle on the screen with Leap.
    defaultOptions:
      autoMotion:
        timeBeforeAutoMove: 2000 // Time, in milliseconds, to wait before starting the automatic movement.
        onStart: true // The camera move automaticaly on start (It don't wait the `timeBeforeAutoMove`)
        speed: 0.01 // The spped of the automatic movement
      leapMotion:
        maxLat: 70 // The maximum vertical position.
        minLat: 70 // The minimum vertical position.
      view:
        initialFov: 70 // The initial field of view
        initialLon: 0 // The initial horizontal position
        initialLat: 0 // The initial vertical position
        
Dependencies
------------

This project use [Three.js](http://threejs.org/), [Leap.js](https://github.com/leapmotion/leapjs) and [deepmerge](https://github.com/nrf110/deepmerge)

How I made it
-------------

 I wrote an article on my experiense. You can find it here :

 http://gcorbel.github.io/blog/english/2013/08/09/leap-motion-a-developer-point-of-view.html

 Or in french :

 http://gcorbel.github.io/blog/french/2013/08/04/leap-motion-le-point-de-vue-d-un-developpeur.html
