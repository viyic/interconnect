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
