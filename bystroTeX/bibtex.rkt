(module bibtex racket

  (require racket scribble/core scribble/base)
  (require bystroTeX/slides)
  (require net/zmq)
  (require json)
  
  (provide cite)
  (provide bibliography)
  
  (define (get-zeromq-socket-rust)
    (let* ([ctxt (context 1)]
           [sock (socket ctxt 'REQ)]
           [sock-path
            ;(format "ipc://~a/.local/run/bystrotex.ipc" (path->string (find-system-path 'home-dir)))
            (format "ipc://~a/.local/run/rust-extras.ipc" (path->string (find-system-path 'home-dir)))
            ]
           )
      (display (format " -- connecting to ~a ~n" sock-path))
      (socket-connect! sock sock-path)
      (display " -- connected")
      sock))
  (define zeromq-socket-rust (get-zeromq-socket-rust))
  (define items '()) ; list of citations
  (provide (contract-out  
            [get-bib-from-zeromq (-> string? jsexpr?)]))
  (define (get-bib-from-zeromq k)
    (let* ([j (make-hash `((req_type . "BibTeX") (payload . ,k)))])
      (socket-send! zeromq-socket-rust (jsexpr->bytes j))
      (define reply (socket-recv! zeromq-socket-rust))
      (bytes->jsexpr reply)
      )
    )
  ;; ---------------------------------------------------------------------------------------------------


  (define (cite x)
    (when (empty? (for/list ([y items] #:when (equal? x (car y))) #t))
      (let ([xh (get-bib-from-zeromq x)])
        (when (not-null? (hash-ref xh 'BibTeXKeyNotFound #f))
          (error (string-append "Error: BibTeXKeyNotFound: " (hash-ref xh 'BibTeXKeyNotFound #f))))
        (set! items (cons (cons x xh) items))))
    (elemref x x ))
  (define (intersperse separator ls)
    (if (or (null? ls) (null? (cdr ls)))
        ls
        (cons (car ls)
              (cons separator
                    (intersperse separator (cdr ls))))))

  (define (not-null? x) (and x (not (eq? 'null x))))
  (define (prepend-comma x) (if (cons? x) (cons ", " x) x))
  (define (prepend-hspace x) (if (cons? x) (cons (hspace 1) x) x))
  (define (format-title x) (italic x))
  (define (format-journal bh)
    (if (not-null? (hash-ref bh 'journal #f))
        `(,@(let ([j (hash-ref bh 'journal #f)]) (if (not-null? j) `(,j) '()))
          ,@(let ([v (hash-ref bh 'volume #f)])  (prepend-hspace (if (not-null? v) `(,(bold v)) '())))
          ,@(let ([y (hash-ref bh 'year #f)])    (prepend-hspace (if (not-null? y) `(,(string-append "(" y ")")) '())))
          ,@(let ([p (hash-ref bh 'pages #f)])   (prepend-hspace (if (not-null? p) `(,(string-append "p." p)) '())))
          )
        '()))
  (define (format-eprint bh)
    `(,@(let ([p (hash-ref bh 'archiveprefix #f)]) (if (not-null? p) `(,(bold p ":")) '()))
      ,@(let ([x (hash-ref bh 'eprint #f)])        (if (not-null? x) `(,x) '()))))
  (define (format-doi bh)
    `(,@(let ([doi (hash-ref bh 'doi #f)]) (if (not-null? doi) `(,(bold "doi:") ,doi) '()))))
  (define (format-bibitem bh)
    (apply 
     elem
     `(,@(let ([aus (hash-ref bh 'authors #f)]) (if (not-null? aus) (flatten (for/list ([a aus]) `(,a . ", "))) '()))
       ,@(let ([t (hash-ref bh 'title #f)])  (if (not-null? t) `(,(format-title t)) '()))
       ,@(prepend-comma (format-journal bh))
       ,@(prepend-comma (format-eprint bh))
       ,@(prepend-comma (format-doi bh))
       )))
  (define (bibliography)
    (make-table 
     (make-style 
      #f
      `(,(make-table-columns `(,(make-style "bystro-bib-key-cell" '()) 
                               ,(make-style #f '()) 
                               ,(make-style "bystro-bib-value-cell" '())))))
     (for/list ([i (reverse items)])
       (list (para (elemtag (car i) (string-append "[" (car i) "]"))) 
             (para (hspace 1))
             (para
              (format-bibitem (cdr i))
              )))))
  )
