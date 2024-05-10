;; extends

;; inject glsl for any string that starts `#pragma language glsl`
(string 
  content: _ @injection.content
  (#lua-match? @injection.content "^%s*#pragma language glsl")
  (#set! injection.language "glsl"))


; inject glsl for calls to newShader
; love.graphics.newShader([[...]])
; and even just newShader([[...]])
((function_call
  name: (_) @_function
  arguments: (arguments
    (string
      content: _ @injection.content)))
  (#contains? @_function "newShader")
  (#set! injection.language "glsl"))
