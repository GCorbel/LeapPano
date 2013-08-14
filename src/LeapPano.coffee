class window.LeapPano
  constructor: (config) ->
    @view = new LeapPano.View()
    @mouse = new LeapPano.Mouse(@view)
    @leap = new LeapPano.LeapMotion(@view)
    @files = config.files
    @view.setFiles(@files)
    @view.setFilePath(@files[0])

  init: =>
    @mouse.init()
    @leap.init()

    addEventListener "resize", @onWindowResize, false
    @animate()

    container = document.getElementById("container")
    container.appendChild @view.getRenderer().domElement

  setFilePath: (path) =>
    @view.setFilePath(path)

  setFrame: (frame) =>
    @leap.setFrame(frame)

  onWindowResize: =>
    camera = @view.getCamera()
    camera.aspect = innerWidth / innerHeight
    camera.updateProjectionMatrix()
    @view.getRenderer().setSize innerWidth, innerHeight

  animate: =>
    requestAnimationFrame @animate
    @view.render()

class LeapPano.LeapMotion
  constructor: (view) ->
    @view = view
    
  setFrame: (frame) ->
    @frame = frame

  init: ->
    setTimeout(@checkMotion, 1)

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
    newLat = @view.getLat() + (( y - 160 ) / 320)
    if newLat < 70 && newLat > -70
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

    setTimeout(@checkMotion, 1)

    
class LeapPano.View
  constructor: ->
    @lat = 0
    @lon = 0
    @fov = 70
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