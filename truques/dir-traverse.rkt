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

  (define (dir->part dir filt fmt subparts)
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
     `(,@(subparts dir)
       ,@(for/list ([sd (in-list direct-subdirs)] #:when (filt sd))
           (dir->part sd filt fmt subparts))
       )              ; parts
     )
    )

  (provide
   (proc-doc/names
    bystro-traverse-dir
    (->* (pre-part?
          #:dir path?
          #:show (-> path? (listof (or/c block? element?))))
         (#:filter (-> path? boolean?)
          #:subparts (-> path? (listof part?))
          #:tag (or/c string? #f))
         part?)
    ((title start-in-dir fmt) ((filt (λ (p) #t)) (subparts (λ (p) '())) (tag #f)))
    ("traverse and show directories")))

  (define (bystro-traverse-dir title
                               #:dir start-in-dir
                               #:filter [filt (λ (p) #t)]
                               #:show fmt
                               #:tag [tag #f]
                               #:subparts [subparts (λ (p) '())]
                               )
    (make-part
     #f                                   ; tag-prefix
     (mk-part-tags tag)                   ; tags  (use user tag if provided)
     (list title)                         ; title-content
     (style #f '())                       ; style
     '()                                  ; to-collect
     '()                                  ; blocks
     (list (dir->part start-in-dir filt fmt subparts)))) ; parts

  )
