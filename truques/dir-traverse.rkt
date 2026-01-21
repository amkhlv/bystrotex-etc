(module dir-traverse racket

  (require scribble/core
           scribble/decode
           scribble/base
           racket/file)
  (require scribble/srcdoc racket/contract/base (for-doc scribble/base scribble/manual))


  (define (mk-part-tags maybe-tag)
    (list (list 'part (or maybe-tag (make-generated-tag)))))

  (define (as-block x)
    (cond
      [(block? x) x]
      [else (para x)]))

  (define (dir->part dir fmt)
    (define direct-subdirs
      (for/list ([p (in-list (directory-list dir #:build? #t))]
                 #:when (directory-exists? p))
        p))

    (make-part
     #f                                   ; tag-prefix
     (mk-part-tags #f)                    ; tags
     (list (tt (path->string dir)))       ; title-content
     (style "bystro-traverse" '())        ; style
     '()                                  ; to-collect
     (map as-block (fmt dir))             ; blocks
     (for/list ([sd (in-list direct-subdirs)])
       (dir->part sd fmt))))              ; parts


  (provide (proc-doc/names
            bystro-traverse-dir
            (->* (pre-part?
                  #:dir path?
                  #:show (-> path? (listof (or/c block? element?)))
                  )
                 (#:tag (or/c string? #f)
                  )
                 part?)
            ((title start-in-dir fmt) ((tag #f)))
            ("traverse and show directories")))

  (define (bystro-traverse-dir title
                               #:dir start-in-dir
                               #:show fmt
                               #:tag [tag #f]
                               )
    (make-part
     #f                                   ; tag-prefix
     (mk-part-tags tag)                   ; tags  (use user tag if provided)
     (list title)                         ; title-content
     (style #f '())                       ; style
     '()                                  ; to-collect
     '()                                  ; blocks
     (list (dir->part start-in-dir fmt)))) ; parts

  )
