; (require :common)

(local grid-size 100)

(var window-width (love.graphics.getWidth))
(var window-height (love.graphics.getHeight))
(var mx 0)
(var my 0)

(var selected 1)

(fn point-in-rectangle? [x y x1 y1 x2 y2]
  (if (and (>= x x1) (<= x x2) (>= y y1) (<= y y2))
    true
    false))

(fn draw-rectangle [mode x y w h radius]
  (love.graphics.rectangle mode x y w h radius))

(fn draw-rectangle-centered [mode x y w h radius]
  (love.graphics.rectangle mode (- x (/ w 2)) (- y (/ h 2)) w h radius))

(fn draw-text [x y text]
  (var font (love.graphics.getFont))
  (love.graphics.print text x y 0 1 1 (/ (font:getWidth text) 2) (/ (font:getHeight) 2)))

(fn draw-line [x1 y1 x2 y2 width]
  (love.graphics.setLineWidth width)
  (love.graphics.line x1 y1 x2 y2)
  )

(fn rgb [r g b]
  (values (/ r 255) (/ g 255) (/ b 255))
  )

(fn update [dt set-mode]
  (set (mx my) (love.mouse.getPosition))
  ; (when
  ;   (love.keyboard.isDown :escape) (love.event.quit))
    ; (love.keyboard.isDown :up) (set selected (+ (% (+ selected 1) (length menus)) 1))
    )

(fn draw [set-mode]
  (love.graphics.clear 1 1 1)
  (love.graphics.setColor 0 0 0)
  (draw-text (/ window-width 2) 50 "interconnect")
  (var menus [:play :quit])
  ; (each [index menu (ipairs menus)]
  ;   (var text (.. (if (= index selected) "> " "") menu))
  ;   (love.graphics.print text 10 y)
  ;   (set y (+ y 24))))

  (local x 0)
  (local y 0)
  (for [index 1 10]
    (love.graphics.setColor (/ 157 255) (/ 236 255) (/ 235 255))
    ; (draw-line (+ x (* index grid-size)) y (+ x (* index grid-size)) (+ y 9999) 3)
    ; (draw-line x (+ y (* index grid-size)) (+ x 9999) (+ y (* index grid-size)) 3)
    (for [inner_index 0 35]
      (draw-line (+ x (* index grid-size)) (+ y (* inner_index 25)) (+ x (* index grid-size)) (+ (+ y (* inner_index 25)) 12.5) 3)
    )
    (for [inner_index 0 45]
      (draw-line (+ x (* inner_index 25)) (+ y (* index grid-size)) (+ (+ x (* inner_index 25)) 12.5) (+ y (* index grid-size)) 3)
    )
  )

  (var margin-x 300)
  (var w (- window-width (* margin-x 2)))
  (var h (- window-height (* margin-x 2)))

  (love.graphics.setColor (rgb 71 222 220))
  (draw-rectangle :fill (- margin-x 20) (- margin-x 20) (+ w 40) (+ h 40) 5)
  (each [index menu (ipairs menus)]
    (var build-w w)
    (var build-h (/ h (length menus)))
    (var build-x margin-x)
    (var build-y (+ margin-x (* (- index 1) build-h)))
    (local hover (point-in-rectangle? mx my build-x build-y (+ build-x build-w) (+ build-y build-h)))
    (if hover
      (love.graphics.setColor 0 0.6 1)
      (love.graphics.setColor 1 1 1)
      )
    (draw-rectangle :fill build-x build-y build-w build-h 5)
    (if hover
      (love.graphics.setColor 1 1 1)
      (love.graphics.setColor 0 0 0))
    (draw-text (+ build-x (/ build-w 2)) (+ build-y (/ build-h 2)) menu)
    (when (and hover (love.mouse.isDown 1))
      (when (= index 1)
        (set-mode :src.game))
      (when (= index 2)
        (love.event.quit))
    )
  )
)

(fn load []
  true)

{: load : update : draw}