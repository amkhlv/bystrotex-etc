(module parse-md racket
  (require markdown)

  (require scribble/srcdoc (for-doc scribble/base scribble/manual))
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
  ((title file) ((tag #f)))
  ("Show Markdown as a part")))

(define (md-file-show ttl #:file p #:tag [t #f])
  (decode-part
   (md-file->parts p)
   (if t `(,t) '())
   `(,ttl)
   0))



  )
