(module extra-rules racket
  (provide rules)
  (define (rules xpr)
    (match xpr
      ['semicol (begin (display ";") #t)]
      [_ #f]
      ))
  (provide subs)
  (define
    subs
    (hash
     "↑" "\\uparrow"
     "↓" "\\downarrow"
     )
    )
  )
