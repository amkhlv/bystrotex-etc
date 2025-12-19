(module parse-md racket
  (require markdown)

  (require scribble/srcdoc racket/contract/base (for-doc scribble/base scribble/manual))
  (require markdown/scrib markdown/parse racket/port scribble/decode scribble/core)

  (provide (proc-doc
            md-file->parts
            (->i
             ([file path-string?])
             ()
             [result (listof (or/c pre-part? pre-flow? pre-content?))]
             )
            ("Parse Markdown")))
  (define (md-file->parts p)
    (with-input-from-file p
      (lambda ()
        (xexprs->scribble-pres
         (read-markdown)))))

  (provide
   (proc-doc/names
    md-file-show
    (->* (pre-part? #:file path-string?)
         (#:tag (or/c string? #f))
         part?)
    ((title file-path) ((tag #f)))
    ("Read Markdown from a file and show it as a part")))
  (define (md-file-show ttl #:file p #:tag [t #f])
    (decode-part
     (md-file->parts p)
     (if t `(,t) '())
     `(,ttl)
     0))

  (provide
   (proc-doc
    md-show
    (->i ([title pre-part?])
         (#:tag [tag (or/c string? #f)])
         #:rest [lines (listof string?)]
         [result part?])
    (#f)
    ("Show Markdown as a part")))


  (define (md-show title #:tag [tag #f] . lines)
    (decode-part
     (parameterize ([current-input-port
                     (open-input-string (apply string-append lines))])
       (lambda ()
         (xexprs->scribble-pres (read-markdown))))
     (if tag (list tag) '())
     (list title)
     0))



  )
