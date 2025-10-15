#|
Copyright 2012,2013 Andrei Mikhailov

This file is part of truques.

bystroTeX is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

bystroTeX is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with bystroTeX.  If not, see <http://www.gnu.org/licenses/>.
|#

(module truques racket
  (require scribble/core scribble/base scribble/html-properties scribble/decode scriblib/render-cond racket/string racket/path racket/date racket/port)
  (require bystroTeX/common)
  (require xml/path (prefix-in the: xml))
  (require "xml.rkt")
  (require "pdq.rkt")
  (define copy-tag-num 0)

  (define svg-annotations (make-hash))

  (provide (all-from-out "pdq.rkt"))
  (provide explain)
  (define-syntax explain
    (syntax-rules ()
      [(expose a ...)
       (nested
        (nested
         #:style (style "comment" '())
         (verbatim
          (let ([o (open-output-string)])
            (for ([x (syntax->datum  #'(a ...))])
              (pretty-print x o))
            (get-output-string o))))
        a ... )]))
  
  (provide (contract-out [show-and-go (->* (namespace-anchor?) () #:rest (listof string?) block?)]))
  (define (show-and-go a . x)
    (define thisns (namespace-anchor->namespace a))
    (let ((mycode (apply string-append x)))
        (nested (nested #:style (style "comment" '()) (verb mycode))
                (eval (read (open-input-string (string-append "(begin " mycode ")"))) thisns))))

  (provide (contract-out [curdir (-> element?)]))
  (define (curdir)
                                        ;  Inserts the link to the current dir
    (hyperlink (bystro-path-to-link ".") 
               #:style (make-style 
                        "sourcelink" 
                        (list (make-css-addition "misc.css"))) 
               "*dir*"))
  (provide (contract-out [mailto (->* () () #:rest (listof string?) element?)]))
  (define (mailto . x)
    (let* ([xx (map 
                (λ (u) (string-trim u #px"\\<|\\>")) 
                (filter 
                 ((curry regexp-match?) #rx"@") 
                 (apply append (map string-split x))))]
           [z (apply 
               ((curry string-append) "mailto:")
               (add-between xx ","))])
      (hyperlink z (add-between (filter (compose not ((curry regexp-match?) #px"^\\s*$")) x) " ⋄ "))))

  (provide (contract-out [copy-to-clipboard (->* () (#:rows (or/c integer? #f) #:cols (or/c integer? #f)) #:rest (listof string?) element?)]))
  (define (copy-to-clipboard #:rows [rows #f] #:cols [cols #f] . xs)
    (set! copy-tag-num (+ 1 copy-tag-num))
    (element
     (style #f '())
     (list
      (make-element
       (make-style
        "bystro-copy-to-clipboard"
        `(,(alt-tag "textarea")
          ,(attributes
            `(,(cons 'id (string-append "amkhlv-bystro-copy-id-" (number->string copy-tag-num)))
              ,(cons 'readonly "1")
              ,@(filter (lambda (x) (cdr x))
                        `(,(cons 'rows (if rows (number->string rows) #f))
                          ,(cons 'cols (if cols (number->string cols) #f))))))))
       (apply string-append xs))
      (tg
       button
       #:attrs ([onclick (string-append "amkhlvBystroCopyFn" (number->string copy-tag-num) "()")])
       "COPY")
      (tg
       script
       (string-append
        "function amkhlvBystroCopyFn"
        (number->string copy-tag-num)
        "() {navigator.clipboard.writeText(document.getElementById(\""
        "amkhlv-bystro-copy-id-"
        (number->string copy-tag-num)
        "\").value); }"
        )
       )
      )
     )
    )
  (provide (contract-out [autolist (->*
                                    ()
                                    (#:exts (listof symbol?)
                                     #:dir path-string?
                                     #:header (or/c (listof any/c) #f)
                                     #:output (-> path-string? (or/c (listof any/c)))
                                     #:filter (path-for-some-system? . -> . boolean?)
                                     )
                                    (or/c table? element?))]))
  (define (autolist
           #:exts [extensions '(pdf)]
           #:dir [dir (get-bystro-scrbl-name)]
           #:header [header #f]
           #:output [o
                     (lambda (f)
                       `(,(hyperlink
                           (find-relative-path
                            (current-directory)
                            (path->complete-path (simplify-path (build-path dir f))))
                           (path->string f))))]
           #:filter [flt (lambda (p) #t)]
           )
    (displayln "")
    (displayln dir)
    (let ([relevant-files
           (for/list
               ([f (directory-list dir)]
                #:when (and
                        (for/or ([ext (map symbol->string extensions)])
                          (string-suffix? (path->string f) (string-append "." ext)))
                        (flt f)
                        )
                )
             (o f))])
      (if (cons? relevant-files)
          (bystro-table
           #:style-name "bystro-autolist"
           (if (cons? header) (cons header relevant-files) relevant-files))
          (make-element
           (make-style "bystro-autolist-nothing-found" '())
           `("no files with extensions: "
             ,(string-join (map symbol->string extensions) "|"))))))
  (provide (contract-out [check (->* () () #:rest (listof any/c) element?)]))
  (define (check . xs)
    (make-element
     (make-style #f (list (alt-tag "label") (attributes `(,(cons 'class "bystro-checkbox-label")))))
     (append
      xs
      `(
        ,(make-element
          (make-style #f (list (alt-tag "input")
                               (attributes `(
                                             ,(cons 'type "checkbox")
                                             ,(cons 'class "bystro-checkbox")))))
          '())
        ,(make-element
          (make-style #f (list (alt-tag "span") (attributes `(,(cons 'class "bystro-checkmark")))))
          '()))
      )))
  
  (provide (contract-out [autolist-pdfs (->*
                                         ()
                                         (#:dir path-string?
                                          #:showtime boolean?
                                          #:filter (path-for-some-system? . -> . boolean?)
                                          #:tags (listof symbol?)
                                          )
                                         (or/c table? element?))]))
  (define (autolist-pdfs
           #:dir [dir (build-path 'same)]
           #:showtime [st #f]
           #:filter [flt (lambda (p) #t)]
           #:tags [tgs '()]
           )
    (autolist
     #:exts '(pdf PDF)
     #:dir dir
     #:header `(,(bold "summary") ,@(if st (list (bold "time")) '()) ,(bold "PDF"))
     #:filter (λ (p)
                (and
                 (flt p)
                 (let ([file.pdq (build-path dir (path-replace-extension p ".pdq"))])
                   (or
                    (not (file-exists? file.pdq))
                    (for/and ([atag tgs]) (member (symbol->string atag) (pdq-tags file.pdq)))))))
     #:output (lambda (f)
                (let* ([frel
                        (find-relative-path
                         (current-directory)
                         (path->complete-path (simplify-path (build-path dir f))))]
                       [.pdf (path->string f)]
                       [.pdq (path-replace-extension (resolve-path frel) ".pdq")]
                       [t (if st (file-or-directory-modify-seconds frel) #f)]
                       [x (if
                           (file-exists? .pdq)
                           (call-with-input-file .pdq
                             (lambda (inport) (the:xml->xexpr (the:document-element (the:read-xml inport)))))
                           '(root () (summary () "--")))]
                       [summary (se-path* '(summary) x)])
                  `(
                    ,(if
                      summary
                      (show-xexpr
                       #:transform-to-content
                       (hash-set (transform-to-content)
                                 'tag
                                 (λ (y)
                                   (make-element
                                    (make-style "bystro-pdq-tag" '())
                                    (caddr y))))
                       (cons
                        'rt
                        (append (se-path*/list '(summary) x) (se-path*/list '(tags) x)))
                       )
                      "")
                    ,@(if t (list (smaller (date->string (seconds->date t)))) '())
                    ,(hyperlink frel .pdf))))))
  (provide (contract-out [autolist-images (->*
                                           ()
                                           (#:exts (listof symbol?)
                                            #:dir path-string?
                                            #:scale number?
                                            #:ncols integer?
                                            #:filter (path-for-some-system? . -> . boolean?)
                                            #:showtime boolean?
                                            #:showdir boolean?
                                            #:output (path-string?  path? . -> . block?)
                                            )
                                           (or/c nested-flow? element?))]))  
  (define (autolist-images
           #:exts [extensions '(svg png tiff jpg jpeg)]
           #:dir [dir (build-path 'same)]
           #:scale [scale 0.25]
           #:ncols [ncols 2]
           #:filter [filt (λ (f) #t)]
           #:showtime [st #f]
           #:showdir [sd #t]
           #:output [o
                     (λ (d f)
                       (tbl `(,@`((,(hyperlink
                                     (build-path d f)
                                     (image #:scale scale (build-path d f))))
                                  (,(path->string f)))
                              ,@(if st
                                    `((,(date->string
                                         (seconds->date
                                          (file-or-directory-modify-seconds
                                           (find-relative-path
                                            (current-directory)
                                            (path->complete-path (simplify-path (build-path d f)))))))))
                                    '()))))]
           )
    (define (complement-list lst n)
      (if (equal? (length lst) n)
          lst
          (complement-list (cons "" lst) n)))
    (define/match (split-list-in-pairs lst acc)
      [('() (cons row aa)) (reverse (map reverse (cons (complement-list row ncols) aa)))]
      [((cons el rst) (cons row aa))
       #:when (equal? (length row) ncols)
       (split-list-in-pairs rst (cons (list el) (cons row aa)))]
      [((cons el rst) (cons row aa))
       (split-list-in-pairs rst (cons (cons el row) aa))]
      [((cons el rst) '())
       (split-list-in-pairs rst (list (list el)))])
    (let ([relevant-files
           (for/list
               ([f (directory-list dir)]
                #:when (and
                        (filt (build-path dir f))
                        (for/or ([ext (map symbol->string extensions)])
                         (string-suffix? (path->string f) (string-append "." ext))))
                )
             (o dir f))]
          )

          (apply
           nested
           `(,@(if sd `(,(copy-to-clipboard #:cols 80 (path->string (path->complete-path dir)))) '())
             ,(if (cons? relevant-files)
                  (tbl (split-list-in-pairs relevant-files '()))
                  (make-element
                   (make-style "bystro-autolist-nothing-found" '())
                   `("no files with extensions: "
                     ,(string-join (map symbol->string extensions) "|")))
                  )))))
  (define (xmlstarlet-desc path)
    (let*-values
        ([(sel-proc   sel-stdout sel-stdin            sel-stderr)
          (subprocess #f         (current-input-port) (current-error-port)
                      #f
                      (find-executable-path "xmlstarlet")
                      "sel" "-N" "s=http://www.w3.org/2000/svg"  "-t" "-v" "//s:desc" path)]
         [(unesc-proc unesc-stdout unesc-stdin unesc-stderr)
          (subprocess #f           sel-stdout  (current-error-port)
                      #f
                      (find-executable-path "xmlstarlet")
                      "unesc")])
      (subprocess-wait sel-proc)
      (let ([results (port->list read-line unesc-stdout)]
            )
        (close-input-port sel-stdout)
        (close-input-port unesc-stdout)
        results)
      ))
      
      
           
    
  (provide (contract-out [autolist-svgs (->*
                                         ()
                                         (#:dir path-string?
                                          #:scale number?
                                          #:ncols integer?
                                          #:filter (-> path-for-some-system? boolean?)
                                          #:showtime boolean?
                                          #:showdir boolean?
                                          #:annotated boolean?
                                          )
                                         (or/c nested-flow? element?))]))
  (define
    (autolist-svgs
     #:dir [dir (build-path 'same)]
     #:scale [scale 0.25]
     #:ncols [ncols 2]
     #:filter [filt (λ (f) #t)]
     #:showtime [st #f]
     #:showdir [sd #t]
     #:annotated [annot #f]
     )
    (let* ([tag-prefix (gensym "annotation")]
           )
      (nested
       `(
         ,@(if annot
               `(,(elemtag `(bystro-svg-annot-top ,tag-prefix) "")
                 ,(make-delayed-block
                   (lambda (renderer pt ri) 
                     (let ([ks (resolve-get-keys
                                pt
                                ri
                                (lambda (key)
                                  (and (cons? key)
                                       (cons? (cadr key))
                                       (cons? (cdr (cadr key)))
                                       (eq? (car (cadr key)) 'bystro-svg-annot)
                                       (eq? (cadr (cadr key)) tag-prefix))))]
                           )
                       (nested
                        `(,(element
                            (style #f '())
                            (for/list ([k ks])
                              (displayln k)
                              (element
                               (style #f '())
                               `(,(element
                                   (style "bystro-svg-annotation-tag-link" '())
                                   `(,(elemref
                                       (cadr k)
                                       (hash-ref svg-annotations (cdr (cadr k))))))
                                 ,(hspace 1)))))))))))
               '())
         ,(autolist-images
           #:exts '(svg)
           #:dir dir
           #:ncols ncols
           #:filter filt
           #:showtime st
           #:showdir sd
           #:scale scale
           #:output (λ (d f)
                      (tbl `(
                             ,@(if annot

                                   `((,(let ([ans (xmlstarlet-desc (build-path d f))])
                                         (if (cons? ans)
                                             (element
                                              (make-style #f '())
                                              `(,(element
                                                  (make-style "bystro-svg-annotation-tag-link" '())
                                                  `(,(elemref `(bystro-svg-annot-top ,tag-prefix) "up")))
                                                ,(hspace 1)
                                                ,(element
                                                  (make-style #f '())
                                                  `(,@(for/list ([annotation ans])
                                                        (let ([n (gensym "no")]
                                                              )
                                                          (hash-set! svg-annotations `(,tag-prefix ,n) annotation)
                                                          (element
                                                           (make-style #f '())
                                                           `(,(element
                                                               (make-style "bystro-svg-annotation-tag" '())
                                                               `(,(elemtag `(bystro-svg-annot ,tag-prefix ,n) annotation)))
                                                             ,(hspace 1)))))))))
                                             (element
                                              (make-style "bystro-svg-annotation-tag-link" '())
                                              `(,(elemref `(bystro-svg-annot-top ,tag-prefix) "up")))))))
                                   '())
                             ,@`((,(hyperlink (build-path d f) (image #:scale scale (build-path d f))))
                                 (,(path->string f)))
                             ,@(if st
                                   `((,(date->string
                                        (seconds->date
                                         (file-or-directory-modify-seconds
                                          (find-relative-path
                                           (current-directory)
                                           (path->complete-path (build-path d f))))))))
                                   '()
                                   )))))))))
      
  )
