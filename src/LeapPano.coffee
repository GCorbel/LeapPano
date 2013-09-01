class window.LeapPano
  container: null
  files: []
  defaultOptions:
    autoMotion:
      timeBeforeAutoMove: 2000
      onStart: true
      speed: 0.01
    leapMotion:
      maxLat: 70
      minLat: 70
    view:
      initialFov: 70
      initialLon: 0
      initialLat: 0

  constructor: (options) ->
    @options = merge(@defaultOptions, options)

    @view = new LeapPano.View(@options.view)
    @mouse = new LeapPano.Mouse(@view, @options)
    @leap = new LeapPano.LeapMotion(@view, @options.leapMotion)
    @auto = new LeapPano.AutoMotion(@view, @options.autoMotion)
    @files = @options.files
    @view.setFiles(@files)
    @view.setFilePath(@files[0])

  init: =>
    @mouse.init()
    @leap.init()
    @auto.init()

    addEventListener "resize", @onWindowResize, false
    @animate()

    container = document.getElementById(@options.container)
    container.appendChild @view.getRenderer().domElement

  setFilePath: (path) =>
    @view.setFilePath(path)


  refresh: (frame) =>
    @leap.setFrame(frame)

  onWindowResize: =>
    camera = @view.getCamera()
    camera.aspect = innerWidth / innerHeight
    camera.updateProjectionMatrix()
    @view.getRenderer().setSize innerWidth, innerHeight

  animate: =>
    requestAnimationFrame @animate
    @view.render()

class LeapPano.AutoMotion
  @LOOP_SEED: 10

  constructor: (view, options) ->
    @view = view
    @options = options
    @count = 0
    @oldLon = view.getLon()
    @logLat = view.getLat()

  init: ->
    if @options.moveOnStart
      @startToMove()
    else
      @checkActivity()

  checkActivity: =>
    @count += 1
    if @positionChanged?()
      @count = 0

    @oldLat = @view.getLat()
    @oldLon = @view.getLon()

    if @count == @options.timeBeforeAutoMove / LeapPano.AutoMotion.LOOP_SEED
      @startToMove()
    else if @count == 0
      @stopToMove()

    requestAnimationFrame(@checkActivity)

  positionChanged: =>
    @view.getLon() != @oldLon || @view.getLat() != @oldLat

  startToMove: =>
    @continueToMove = true
    @move()

  stopToMove: =>
    @continueToMove = false

  move: =>
    if @continueToMove
      @view.setLon(@view.getLon() + @options.speed)

      if @view.getLat() > 0
        @view.setLat(@view.getLat() - @options.speed)

      if @view.getLat() < 0
        @view.setLat(@view.getLat() + @options.speed)

      @oldLat = @view.getLat()
      @oldLon = @view.getLon()
      requestAnimationFrame(@move)

class LeapPano.LeapMotion
  constructor: (view, options) ->
    @view = view
    @options = options

  setFrame: (frame) ->
    @frame = frame

  init: ->
    requestAnimationFrame(@checkMotion)

  checkMove: =>
    finger = @frame.fingers[0]
    if finger?
      @changeLon(finger)
      @changeLat(finger)

  changeLon: (finger) =>
    x = finger.tipPosition[0]
    @view.setLon(@view.getLon() + ( x / 320 ))

  changeLat: (finger) =>
    y = finger.tipPosition[1]
    latRatio = 1 - Math.abs((@view.getLat()) / 80)
    newLat = @view.getLat() + ((( y - 160 ) / 320) * latRatio)

    if newLat < @options.minLat && newLat > -@options.minLat
      @view.setLat(newLat)

  checkGestures: =>
    if(@frame.gestures.length > 0)
      gesture = @frame.gestures[0]
      if gesture.type == "circle"
        @view.switchFile()

  checkMotion: =>
    if @frame?
      @checkMove()
      @checkGestures()

    requestAnimationFrame(@checkMotion)

class LeapPano.View
  constructor: (options) ->
    @lat = options.initialLat
    @lon = options.initialLon
    @fov = options.initialFov
    @phi = 0
    @theta = 0
    @filePath = ''

  setFilePath: (path) ->
    @filePath = path
    @scene = null

  getLat: =>
    @lat

  setLat: (lat) =>
    @lat = lat

  getLon: =>
    @lon

  setLon: (lon) =>
    @lon = lon

  getFov: =>
    @fov

  setFov: (fov) =>
    @fov = fov

  setFiles: (files) =>
    @files = files

  switchFile: =>
    console.log @files.length
    if @files.length > 1
      if @filePath == @files[0]
        @setFilePath @files[1]
      else
        @setFilePath @files[0]

  getRenderer: =>
    return @renderer if @renderer

    @renderer = new THREE.WebGLRenderer()
    @renderer.setSize innerWidth, innerHeight
    @renderer

  getCamera: =>
    return @camera if @camera

    @camera = new THREE.PerspectiveCamera(@getFov(), innerWidth / innerHeight, 1, 1100)
    @camera.target = new THREE.Vector3(0, 0, 0)
    @camera

  render: =>
    camera = @getCamera()

    lat = Math.max(-85, Math.min(85, @getLat()))
    phi = THREE.Math.degToRad(90 - lat)
    theta = THREE.Math.degToRad(@getLon())
    camera.target.x = 500 * Math.sin(phi) * Math.cos(theta)
    camera.target.y = 500 * Math.cos(phi)
    camera.target.z = 500 * Math.sin(phi) * Math.sin(theta)
    camera.lookAt camera.target
    @getRenderer().render @getScene(), camera

  getScene: =>
    return @scene if @scene

    container = undefined
    mesh = undefined
    @scene = new THREE.Scene()
    mesh = new THREE.Mesh(new THREE.SphereGeometry(500, 60, 40), new THREE.MeshBasicMaterial(map: THREE.ImageUtils.loadTexture(@filePath)))
    mesh.scale.x = -1
    @scene.add mesh
    @scene

class LeapPano.Mouse
  constructor: (view) ->
    @view = view
    @isUserInteracting = false

  init: =>
    document.addEventListener "mousedown", @onDocumentMouseDown, false
    document.addEventListener "mousemove", @onDocumentMouseMove, false
    document.addEventListener "mouseup", @onDocumentMouseUp, false
    document.addEventListener "mousewheel", @onDocumentMouseWheel, false
    document.addEventListener "DOMMouseScroll", @onDocumentMouseWheel, false

  onDocumentMouseDown: (event) =>
    event.preventDefault()
    @isUserInteracting = true
    window.onPointerDownPointerX = event.clientX
    window.onPointerDownPointerY = event.clientY
    window.onPointerDownLon = @view.getLon()
    window.onPointerDownLat = @view.getLat()

  onDocumentMouseMove: (event) =>
    if @isUserInteracting
      @view.setLon((window.onPointerDownPointerX - event.clientX) * 0.1 + window.onPointerDownLon)
      @view.setLat((event.clientY - window.onPointerDownPointerY) * 0.1 + window.onPointerDownLat)

  onDocumentMouseUp: (event) =>
    @isUserInteracting = false

  onDocumentMouseWheel: (event) =>

    fov = @view.getFov()
    # WebKit
    if event.wheelDeltaY
      fov -= event.wheelDeltaY * 0.05

    # Opera / Explorer 9
    else if event.wheelDelta
      fov -= event.wheelDelta * 0.05

    # Firefox
    else fov += event.detail * 1.0  if event.detail
    @view.setFov(fov)
    @view.getCamera().projectionMatrix.makePerspective fov, innerWidth / innerHeight, 1, 1100
    @view.render()
