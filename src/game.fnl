; (require :common)

(var window-width (love.graphics.getWidth))
(var window-height (love.graphics.getHeight))
(local grid-size 100)
(local camera {:x 0 :y 0})
(var mx 0)
(var my 0)
(var context-menu-open false)
(var context-menu-x 0)
(var context-menu-y 0)

(local builds [:drill :processor :connector])
(local build-prices [25 40 "10/grid"])
(var building 0)
(var building-x 0)
(var building-y 0)
(var building-from 0)
(var building-to 0)
(var building-entity 0)
(var building-obstructed false)
(var building-price 0)

(var entities [])
(var connectors [])
(local effects [])

(var gen-id 1)

(local drill-max-durability 100)
(local drill-price 25)
(local connector-price 10)
(local processor-price 40)

(var generator-energy 1000) ; goal: 1000000
(var fuel 0)
(var gold 100)
(var energy-time 1)
(var energy-timer 1)

(fn create-entity [x y type entity]
  (local id gen-id)
  (set gen-id (+ gen-id 1))
  (local (w h)
    (if (= type :generator)
      (values 2 2)
      (values 1 1)))
  (local durability
    (if (= type :drill)
      drill-max-durability
      99999))
  (local drill-type
    (if (= type :drill)
      entity.type
      nil))
  (table.insert entities
    {: id : x : y : w : h : type : drill-type : durability}))

(fn point-in-rectangle? [x y x1 y1 x2 y2]
  (if (and (>= x x1) (<= x x2) (>= y y1) (<= y y2))
    true
    false))

(fn get-entity-id-from-position [x y ?i]
  (local index (or ?i 1))
  (local entity (. entities index))
  (if (= entity nil)
    0
    (point-in-rectangle? x y entity.x entity.y (+ entity.x (- entity.w 1)) (+ entity.y (- entity.h 1)))
    entity.id
    (get-entity-id-from-position x y (+ index 1))))

(fn get-entity-index-from-id [id ?i]
  (local index (or ?i 1))
  (local entity (. entities index))
  (if (= entity nil)
    0
    (= entity.id id)
    index
    (get-entity-index-from-id id (+ index 1))))

(fn create-effect [x y type text]
  (table.insert effects
    {: x : y : type : text :timer 1}))

(fn load []
  (math.randomseed (os.time))

  (create-entity 4 3 :generator)
  ; (table.insert entities {:x 3 :y 5 :w 1 :h 1 :type :drill})
  ; (table.insert connectors {:from 1 :to 2})

  (for [index 1 20]
    (fn create-gold []
      (local x (lume.round (lume.random -15 15)))
      (local y (lume.round (lume.random -15 15)))
      (local entity (get-entity-id-from-position x y))
      (when (= entity 0)
        (create-entity x y :gold))
      (when (not= entity 0)
        (create-gold)))
    (create-gold))
  (for [index 1 20]
    (fn create-fuel []
      (local x (lume.round (lume.random -15 15)))
      (local y (lume.round (lume.random -15 15)))
      (local entity (get-entity-id-from-position x y))
      (when (= entity 0)
        (create-entity x y :fuel))
      (when (not= entity 0)
        (create-fuel)))
    (create-fuel)))

(local mouse {
  :left {
    :down false
    :pressed false
    :released false
    :index 1}
  :right {
    :down false
    :pressed false
    :released false
    :index 2}
  :middle {
    :down false
    :pressed false
    :released false
    :index 3}})
  
(fn update-mouse []
  (each [key button (pairs mouse)]
    (local down (love.mouse.isDown button.index))

    (when down
      (set button.pressed (not button.down))
      (set button.down true))
    
    (when (not down)
      (set button.released button.down)
      (set button.down false))))

(fn update [dt set-mode]
  (set (mx my) (love.mouse.getPosition))
  (update-mouse)
  (local cam-speed 200)
  (when
    (love.keyboard.isDown :escape) 
    (set entities [])
    (set connectors [])
    (set generator-energy 1000)
    (set fuel 0)
    (set gold 100)
    (set energy-time 1)
    (set energy-timer 1)
    (set-mode :src.menu))
  ; (when context-menu-open
  ;   (when mouse.left.released
  ;     (set context-menu-open false))
  ;   )

  ; is hovering panel?
  (var margin-x 200)
  (var build-w (- window-width (* margin-x 2)))
  (var build-h 100)
  (var build-x margin-x)
  (var build-y (- window-height build-h))
  (local hover (point-in-rectangle? mx my build-x build-y (+ build-x build-w) (+ build-y build-h)))
  ; (when (not hover)
  ; (when (not context-menu-open)
    ; (when mouse.right.pressed
    ;   (set context-menu-x mx)
    ;   (set context-menu-y my)
    ;   (set context-menu-open true))

  (var scroll-area 100)
  (when
    (or (love.keyboard.isDown :w) (and (not hover) (< my scroll-area))) (set camera.y (- camera.y (* dt cam-speed))))
  (when
    (or (love.keyboard.isDown :s) (and (not hover) (> my (- window-height scroll-area)))) (set camera.y (+ camera.y (* dt cam-speed))))
  (when
    (or (love.keyboard.isDown :a) (and (not hover) (< mx scroll-area))) (set camera.x (- camera.x (* dt cam-speed))))
  (when
    (or (love.keyboard.isDown :d) (and (not hover) (> mx (- window-width scroll-area)))) (set camera.x (+ camera.x (* dt cam-speed))))
  ; )
  (set camera.x (math.min (math.max camera.x (* -22 grid-size)) (* 22 grid-size)))
  (set camera.y (math.min (math.max camera.y (* -22 grid-size)) (* 22 grid-size)))
  (when (> energy-timer 0)
    (set energy-timer (- energy-timer dt)))
  (when (<= energy-timer 0)
    (each [index connector (ipairs connectors)]
      (when (> generator-energy 0)
        ; (local from (. entities (get-entity-index-from-id connector.from)))
        (local to (. entities (get-entity-index-from-id connector.to)))
        (when (= to.type :drill)
          ; (set to.durability (- to.durability 1))
          (when (= to.drill-type :gold)
            (set gold (+ gold 1)))
          
          (when (= to.drill-type :fuel)
            (set fuel (+ fuel 1))))
        
        (when (and (= to.type :processor) (>= fuel 1))
          ; (set to.durability (- to.durability 1))
          ; (set gold (+ gold 1))
          (set fuel (- fuel 1))
          (set generator-energy (+ generator-energy 4)))
        
        (set generator-energy (- generator-energy 1))))
    
    ; (set generator-energy (- generator-energy (length connectors)))
    (set energy-timer (+ energy-timer energy-time)))
  (when (not= building 0)
    (set building-x (lume.round (/ (- (+ mx camera.x) (/ grid-size 2)) grid-size)))
    (set building-y (lume.round (/ (- (+ my camera.y) (/ grid-size 2)) grid-size)))
    (set building-entity (get-entity-id-from-position building-x building-y))
    (local entity (. entities (get-entity-index-from-id building-entity)))
    (local build (. builds building))
    (set building-obstructed true)
    (when (= build :drill)
      (when (and (not= entity nil) (or (= entity.type :gold) (= entity.type :fuel)) (>= gold drill-price))
        (set building-obstructed false)))
    
    (when (= build :connector)
      (when (and (not= entity nil) (not= entity.type :gold :fuel)) ; (>= gold connector-price)
        (set building-obstructed false))
      (local from (. entities (get-entity-index-from-id building-from)))
      (local to entity)
      (when (and (not= from nil) (not= to nil))
        (local price
          (lume.round
            (*
              (lume.distance
                (+ from.x (/ from.w 2)) (+ to.x (/ to.w 2))
                (+ from.y (/ from.h 2)) (+ to.y (/ to.h 2)))
              connector-price)))
        (when (not= price 0)
          (set building-price price))))
    
    (when (= build :processor)
      (when (= entity nil)
        (set building-obstructed false)))
    
    (when mouse.left.pressed
      (when (not building-obstructed)
        (when (not= build :connector)
          (create-entity building-x building-y build entity)
          (when (= build :processor)
            (set gold (- gold processor-price)))
          (when (= build :drill)
            (set gold (- gold drill-price))
            (table.remove entities (get-entity-index-from-id building-entity)))
          (set building 0))
        
        (when (= build :connector)
          (var step false)
          (when (= building-from 0)
            (when (= entity.type :generator)
              (set building-from building-entity))
            (when (not= entity.type :generator)
              (fn get-connector-index-from-entity-id [id ?i]
                (local index (or ?i 1))
                (local connector (. connectors index))
                (db id)
                (db connector)
                (if (= connector nil)
                  0
                  (= connector.to id)
                  index
                  (get-connector-index-from-entity-id id (+ index 1))))
              
              (local connector (get-connector-index-from-entity-id entity.id))
              (when (not= connector 0)
                ; (db connectors)
                (set building-from building-entity)))
            
            (set step true))
          
          (when (and (not= building-from 0) (= building-to 0) (not step))
            (local from (. entities (get-entity-index-from-id building-from)))
            (local to entity)
            (when (and (>= gold building-price) (not= from.id to.id))
              (set building-to building-entity)
              (set gold (- gold building-price))
              (table.insert connectors {:from building-from :to building-to}))
            (set building 0)
            (set building-from 0)
            (set building-to 0))))
            ; (db building-from)
          
          ; (when (and (not= building-from 0) (not= building-to 0))
          ;   (when (not= building-from building-to)
          ;     (set gold (- gold connector-price))
          ;     (table.insert connectors {:from building-from :to building-to}))
          ;   (set building 0)
          ;   (set building-from 0)
          ;   (set building-to 0)
          ; )
        
      (when building-obstructed
        (set building 0)
        (set building-from 0)
        (set building-to 0))))
      
  ; (when (love.keyboard.isDown :f)
  ;   (db entities)
  ;   (db building-from)
  ; )
  (when (or (love.keyboard.isDown :c) (love.keyboard.isDown :space))
    (set camera.x 0)
    (set camera.y 0)))

(fn draw-rectangle [mode x y w h radius]
  (love.graphics.rectangle mode x y w h radius))

(fn draw-rectangle-centered [mode x y w h radius]
  (love.graphics.rectangle mode (- x (/ w 2)) (- y (/ h 2)) w h radius))

(fn draw-text [x y text]
  (var font (love.graphics.getFont))
  (love.graphics.print text x y 0 1 1 (/ (font:getWidth text) 2) (/ (font:getHeight) 2)))

(fn draw-line [x1 y1 x2 y2 width]
  (love.graphics.setLineWidth width)
  (love.graphics.line x1 y1 x2 y2))

(fn rgb [r g b]
  (values (/ r 255) (/ g 255) (/ b 255)))

(local small-font (love.graphics.newFont "data/font/IBMPlexMono-Regular.ttf" 14))

(fn draw [set-mode]
  (love.graphics.clear 1 1 1)
  (love.graphics.push)
  (love.graphics.translate (- camera.x) (- camera.y))

  ; grid
  (local x (* (- (lume.round (/ camera.x grid-size)) 1) grid-size))
  (local y (* (- (lume.round (/ camera.y grid-size)) 1) grid-size))
  (for [index 1 10]
    (love.graphics.setColor (/ 157 255) (/ 236 255) (/ 235 255))
    ; (draw-line (+ x (* index grid-size)) y (+ x (* index grid-size)) (+ y 9999) 3)
    ; (draw-line x (+ y (* index grid-size)) (+ x 9999) (+ y (* index grid-size)) 3)
    (for [inner_index 0 35]
      (draw-line (+ x (* index grid-size)) (+ y (* inner_index 25)) (+ x (* index grid-size)) (+ (+ y (* inner_index 25)) 12.5) 3))
    (for [inner_index 0 45]
      (draw-line (+ x (* inner_index 25)) (+ y (* index grid-size)) (+ (+ x (* inner_index 25)) 12.5) (+ y (* index grid-size)) 3)))
  
  ; entities
  (local previous-font (love.graphics.getFont))
  (love.graphics.setFont small-font)
  (each [index entity (ipairs entities)]
    (var x (* entity.x grid-size))
    (var y (* entity.y grid-size))
    (var w (* entity.w grid-size))
    (var h (* entity.h grid-size))
    (var text-x (+ x (/ w 2)))
    (var text-y (+ y (/ h 2)))
    (when (= entity.type :generator)
      (love.graphics.setColor 1 0 0.6)
      (draw-rectangle :fill x y w h 5)
      (love.graphics.setColor 1 1 1)
      (draw-text text-x text-y entity.type)
      (draw-text text-x (+ text-y 24) generator-energy))
    (when (= entity.type :drill)
      (love.graphics.setColor 0 0.6 1)
      (draw-rectangle :fill x y w h 5)
      (love.graphics.setColor 1 1 1)
      (draw-text text-x text-y entity.type))
    (when (= entity.type :processor)
      (love.graphics.setColor (rgb 51 204 47))
      (draw-rectangle :fill x y w h 5)
      (love.graphics.setColor 1 1 1)
      (draw-text text-x text-y entity.type))
    (when (= entity.type :gold)
      (love.graphics.setColor (rgb 228 196 21))
      (draw-rectangle :fill x y w h 5))
    (when (= entity.type :fuel)
      (love.graphics.setColor (rgb 90 70 58))
      (draw-rectangle :fill x y w h 5)))
  
  ; connectors
  (each [index connector (ipairs connectors)]
    (local from (. entities (get-entity-index-from-id connector.from)))
    (local to (. entities (get-entity-index-from-id connector.to)))
    (local from-x (* (+ from.x (/ from.w 2)) grid-size))
    (local from-y (* (+ from.y (/ from.h 2)) grid-size))
    (local to-x (* (+ to.x (/ to.w 2)) grid-size))
    (local to-y (* (+ to.y (/ to.h 2)) grid-size))
    (love.graphics.setColor 1 0 0.2)
    (love.graphics.circle :fill from-x from-y 10)
    (draw-line from-x from-y to-x to-y 5)
    (love.graphics.circle :fill to-x to-y 10))

  ; building
  (when (not= building 0)
    (local entity (. entities (get-entity-index-from-id building-entity)))
    (local x (* building-x grid-size))
    (local y (* building-y grid-size))
    (local build (. builds building))
    (when (= build :drill)
      (if (not building-obstructed)
        (love.graphics.setColor 0 0.6 1)
        (love.graphics.setColor 1 0 0.2))
      
      (draw-rectangle :fill x y grid-size grid-size 5)
      (love.graphics.setColor 1 1 1)
      (draw-text (+ x (/ grid-size 2)) (+ y (/ grid-size 2)) build))
    
    (when (= build :processor)
      (if (not building-obstructed)
        (love.graphics.setColor (rgb 51 204 47))
        (love.graphics.setColor 1 0 0.2))
      
      (draw-rectangle :fill x y grid-size grid-size 5)
      (love.graphics.setColor 1 1 1)
      (draw-text (+ x (/ grid-size 2)) (+ y (/ grid-size 2)) build))
    
    (when (= build :connector)
      (when (= building-from 0)
        (local x (* (if entity (+ entity.x (/ (- entity.w 1) 2)) building-x) grid-size))
        (local y (* (if entity (+ entity.y (/ (- entity.h 1) 2)) building-y) grid-size))
        (love.graphics.setColor 1 0 0.2)
        (love.graphics.circle :fill (+ x (/ grid-size 2)) (+ y (/ grid-size 2)) 10))
      
      (when (not= building-from 0)
        (local x (* building-x grid-size))
        (local y (* building-y grid-size))
        (local from (. entities (get-entity-index-from-id building-from)))
        (local from-x (* (+ from.x (/ from.w 2)) grid-size))
        (local from-y (* (+ from.y (/ from.h 2)) grid-size))
        (love.graphics.setColor 1 0 0.2)
        (love.graphics.circle :fill (+ x (/ grid-size 2)) (+ y (/ grid-size 2)) 10)
        (love.graphics.circle :fill from-x from-y 10)
        (draw-line from-x from-y (* (+ building-x 0.5) grid-size) (* (+ building-y 0.5) grid-size) 5))))

  (love.graphics.pop)

  (var margin-x 200)
  (var w (- window-width (* margin-x 2)))
  (var h 100)

  ; build menu
  (love.graphics.setColor 1 1 1)
  (draw-rectangle :fill margin-x (- window-height h) w h 5)
  (love.graphics.setColor (rgb 71 222 220))
  (draw-rectangle :line margin-x (- window-height h) w h 5)
  (each [index build (ipairs builds)]
    (var build-w (/ w (length builds)))
    (var build-h h)
    (var build-x (+ margin-x (* (- index 1) build-w)))
    (var build-y (- window-height build-h))
    (local hover (point-in-rectangle? mx my build-x build-y (+ build-x build-w) (+ build-y build-h)))
    (if (or hover (= building index))
      (love.graphics.setColor 0 0.6 1)
      (love.graphics.setColor 1 1 1))
      
    (draw-rectangle :fill build-x build-y build-w build-h 5)
    (if (or hover (= building index))
      (love.graphics.setColor 1 1 1)
      (love.graphics.setColor 0 0 0))
    (draw-text (+ build-x (/ build-w 2)) (+ build-y (/ build-h 2)) build)
    (draw-text (+ build-x (/ build-w 2)) (+ (+ build-y (/ build-h 2)) (small-font:getHeight)) (.. "gold " (. build-prices index)))
    (when (and hover mouse.left.pressed)
      (set building index)))
    
  (love.graphics.setFont previous-font)
  
  ; ; context menu
  ; (when context-menu-open
  ;   (var w 200)
  ;   (var h 200)
  ;   (set context-menu-x (math.max (math.min context-menu-x (- window-width w)) 0))
  ;   (set context-menu-y (math.max (math.min context-menu-y (- window-height h)) 0))
  ;   (love.graphics.setColor (rgb 71 222 220))
  ;   (draw-rectangle :fill context-menu-x context-menu-y w h 5)
  ; )

  ; stats
  (love.graphics.setColor (rgb 228 196 21))
  (love.graphics.print (.. "gold " gold) 20 20)
  (love.graphics.setColor (rgb 90 70 58))
  (love.graphics.print (.. "fuel " fuel) 20 (+ 20 26))

  ; mouse pointer
  (love.graphics.setColor 0 0 0)
  (love.graphics.circle :fill mx my 4)
  (when (<= generator-energy 0)
    (set-mode :menu)))

{: load : update : draw}
