(var mode nil)
(fn set-mode [new-mode]
  (set mode (require new-mode))
  (mode.load))

(local font (love.graphics.newFont "data/font/IBMPlexMono-Regular.ttf" 24))
(local music (love.audio.newSource "data/audio/stardust-ep-track-1-exclusive-pixabay-music-196787.mp3" :static))
(music:setLooping true)


(fn love.load []
  (love.graphics.setFont font)
  (set-mode :src.menu)
  (music:play))

(fn love.update [dt]
  (mode.update dt set-mode))

(fn love.draw []
  (mode.draw set-mode))

; (fn love.keypressed [key]
;   (when (= key :escape) (love.event.quit)))