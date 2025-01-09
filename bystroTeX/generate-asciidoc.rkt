(module generate-asciidoc racket
  (require racket/match)
  ;(#:extras [h (-> any/c void?)])
  (provide (contract-out
            [get-title (->*  ((listof any/c)) (#:extras (-> any/c boolean?)) string?)]))
  (define (get-title xs #:extras [h (λ (_) #f)])
    (with-output-to-string
      (λ ()(for ([xpr xs])
             (match xpr
               [`(title #:style ,_ ,@contents) (print-adoc #:extras h contents)]
               [`(title ,@contents) (print-adoc #:extras h contents)]
               [_ (void)])))))

  (provide (contract-out
            [get-abstract (->*  ((listof any/c)) (#:extras (-> any/c boolean?)) string?)]))
  (define (get-abstract xs #:extras [h (λ (_) #f)])
    (with-output-to-string
      (λ ()(for ([xpr xs])
             (match xpr
               [`(bystro-abstract ,@contents) (print-adoc #:extras h contents)]
               [_ (void)])))))

  (define (replace-svg-with-png x)
    (string-replace x ".svg" ".png"))
  (provide (contract-out
            [print-adoc (->*  ((listof any/c)) (#:extras (-> any/c boolean?) #:output-to output-port?) (values))]))
  (define (print-adoc xs #:extras [h (λ (_) #f)] #:output-to [out (current-output-port)])
    (parameterize ([current-output-port out])
      (for ([x xs]) (main x #:extras h))
      )
    (values))
  (define (main xpr #:extras extra-rules)
    (define (main1 x) (main x #:extras extra-rules))
    (match xpr
      [`(require ,@_) (void)]
      [`(bystro-set-css-dir ,@_) = (void)]
      [`(define ,@_) (void)]
      [`(bystro-def-formula ,@_) (void)]
      [`(bystro-toc ,@_) (void)]
      [`(bystro-local-toc ,@_) (void)]
      [`(bystro-close-connection ,@_) (void)]
      [`(bystro-source ,@_) (void)]
      [`(bystro-ribbon ,@_) (void)]
      [`(disconnect ,@_) (void)]
      [`(title ,@_) (void)]
      [`(bibliography ,@_) (void)]
      [`(fsize= ,@_) (void)]
      [`(fsize+ ,@_) (void)]
      [`(elemtag ,@_) (void)]
      [`(bystro-margin-note ,@_) (void)]
      [`(bystro-abstract ,@_) (void)]
      [`(bystro-authors ,@_) (void)]
      [`(table-of-contents ,@_) (void)]
      [`(autolist-pdfs ,@_) (void)]
      [`(autolist-svgs ,@_) (void)]
      [`(autolist-images ,@_) (void)]
      [`(high ,@_) (void)]
      [`(bystro-reset-colors ,@_) (void)]
      [`(bystro-scrbl-only ,@_) (void)]
      [`(apply ,f (quasiquote ,xs)) (main1 `(,f ,@xs))]
      [(list 'unquote x) (main1 x)]
      [`(use-LaTeX-preamble ,@xs)
       (begin
         (displayln "\n%BystroTeX-preamble-start\n")
         (map main1 xs)
         (displayln "\n%BystroTeX-preamble-end\n"))]
      [`(void "BystroTeX-start-appendix") (displayln "\\appendix")]
      [`(indent ,@xs) (map main1 xs)]
      [`(indent---> ,@xs) (map main1 xs)]
      [`(cite ,x) (printf "cite:[~a]" x)]
      ;[`(cite ,x) (printf "<<~a>>" x)]
      [`(seclink ,@xs) (printf "<<~a,Section ~a>>" (car xs) (car xs))]
      [`(verb ,x) (printf "`+~a+`" x)]
      [`(italic ,@xs) (begin (display "_") (map main1 xs) (display "_"))]
      [`(bold ,@xs) (begin (display "__") (map main1 xs) (display "__"))]
      [`(emph ,@xs) (begin (display "__") (map main1 xs) (display "__"))]
      [`(tt ,@xs) (begin (display "`") (map main1 xs) (display "`"))]
      [`(elem ,@xs) (map main1 xs)]
      [`(item ,@xs) (begin (display "* ") (map main1 xs) (displayln ""))]
      [`(itemlist #:style 'ordered ,@xs)
       (begin (displayln "") (map main1 xs) (displayln ""))]
      [`(itemlist ,@xs)
       (begin (displayln "") (map main1 xs) (displayln ""))]
      [`(comment ,@xs)
       (begin (display "\\footnote{") (map main1 xs) (display "}"))]
      [`(summary ,@xs) (map main1 xs)]
      [`(larger ,@xs)
       (begin (display "{\\large ") (map main1 xs) (display "}"))]
      [`(larger-2 ,@xs)
       (begin (display "{\\Large ") (map main1 xs) (display "}"))]
      [`(lsrger-3 ,@xs)
       (begin (display "{\\LARGE ") (map main1 xs) (display "}"))]
      ['noindent (display "\\noindent ")]
      [`(linebreak) (display "\n\n\\vspace{10pt}\n")]
      [`(hspace ,n) (printf "\\hspace{~aex}" n)]
      [`(hrule) (display "\\rule ")]
      [`(page ,ttl #:tag ,lbl ,@xs)
       (begin (printf "== [[~a]] " lbl) (main1 ttl))]
      [`(subpage 1 ,ttl #:tag ,@lbletc)
       (begin (printf "=== [[~a]] " (car lbletc)) (main1 ttl))]
      [`(subpage 2 ,ttl #:tag ,@lbletc)
       (begin (printf "==== [[~a]] " (car lbletc)) (main1 ttl))]
      [`(subpage 3 ,ttl #:tag ,@lbletc)
       (begin (printf "===== [[~a]] " (car lbletc)) (main1 ttl))]
      [`(section #:tag ,tg ,@xs)
       (begin (printf "= [[~a]] " tg) (map main1 xs))]
      [`(subsection #:tag ,tg ,@xs)
       (begin (printf "=== [[~a]] " tg) (map main1 xs))]
      [`(subsubsection #:tag ,tg ,@xs)
       (begin (printf "==== [[~a]] " tg) (map main1 xs))]
      [`(section ,@xs)
       (begin (display "== ") (map main1 xs))]
      [`(subsection ,@xs)
       (begin (display "=== ") (map main1 xs))]
      [`(subsubsection ,@xs)
       (begin (display "==== ") (map main1 xs))]
      [`(f ,@xs)
       (begin (display "stem:[") (map main1 xs) (display "]"))]
      [`(v+ ,_ ,f) (main1 f)]
      [`(v- ,_ ,f) (main1 f)]
      [`(h+ ,_ ,f) (main1 f)]
      [`(h- ,_ ,f) (main1 f)]
      [`(th-num ,x) (printf "\\refstepcounter{Theorems}\\label{~a}\\noindent{\\bf \\arabic{Theorems}}" x)]
      [`(th-ref ,x) (printf "\\ref{~a}" x)]
      [`(defn-num ,x) (printf "\\refstepcounter{Definitions}\\label{~a}\\noindent{\\bf \\arabic{Definitions}}" x)]
      [`(defn-ref ,x) (printf "\\ref{~a}" x)]
      [`(spn attn ,@xs) (begin (display "{\\bf ") (map main1 xs) (display "}"))]
      [`(ref ,x) (printf "<<~a>>" x)]
      [`(div s ,@xs) (begin (display "{\\bf ") (map main1 xs) (display "}"))]
      [`(hyperlink ,url ,@xs) 
       (printf "~a[~a]" url (with-output-to-string (λ () (map main1 xs))))]
      [`(spn attn ,@xs) ;TODO do something more expressive
       (begin (display "{\\bf ") (map main1 xs) (display "}"))]
      [`(spn TODO ,@xs) ;TODO do something more expressive
       (begin (display "{\\LARGE \\bf ") (map main1 xs) (display "}"))]
      [`(e #:label ,lbl ,@xs)
       (begin (printf "[[~a]]\n[latexmath]\n++++" lbl) (map main1 xs) (display "\n++++\n"))]
      [`(e ,@xs)
       (begin (display "\n[latexmath]\n++++") (map main1 xs) (display "\n++++\n"))]
      [`(image ,x) (printf "\\includegraphics{~a}" (replace-svg-with-png x))]
      [`(image #:scale ,f ,x) (printf "\\includegraphics[scale=~a]{~a}" f (replace-svg-with-png x))]
      [`(tbl #:orient ,_ `(quasiquote ,rows))
       (begin
         (display "\n\\begin{tabular}{")
         (for ([_ (car rows)]) (display " | c "))
         (displayln "| }")
         (map main1 rows)
         (displayln "\n\\end{tabular}"))]
      
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ; finally, to catch them all :
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      [`(spn TODO ,@xs) (void)]
      [x #:when (string? x) (display x)]
      [x (unless (extra-rules x) (displayln x (current-error-port)))]
      )
    )
  )

