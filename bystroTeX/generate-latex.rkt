(module generate-latex racket
  (require racket/match)
  ;(#:extras [h (-> any/c void?)])
  (provide (contract-out
            [get-title (->*  ((listof any/c)) (#:extras (-> any/c boolean?)) string?)]))
  (define (get-title xs #:extras [h (λ (_) #f)])
    (with-output-to-string
      (λ ()(for ([xpr xs])
             (match xpr
               [`(title #:style ,_ ,@contents) (print-latex #:extras h contents)]
               [`(title ,@contents) (print-latex #:extras h contents)]
               [_ (void)])))))

  (provide (contract-out
            [get-abstract (->*  ((listof any/c)) (#:extras (-> any/c boolean?)) string?)]))
  (define (get-abstract xs #:extras [h (λ (_) #f)])
    (with-output-to-string
      (λ ()(for ([xpr xs])
             (match xpr
               [`(bystro-abstract ,@contents) (print-latex #:extras h contents)]
               [_ (void)])))))

  (define (replace-svg-with-png x)
    (string-replace x ".svg" ".png"))
  (provide (contract-out
            [print-latex (->*  ((listof any/c)) (#:extras (-> any/c boolean?) #:output-to output-port?) (values))]))
  (define (print-latex xs #:extras [h (λ (_) #f)] #:output-to [out (current-output-port)])
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
      [`(cite ,x) (printf "\\cite{~a}" x)]
      [`(seclink ,@xs) (printf "Section \\ref{~a}" (car xs))]
      [`(verb ,x) (printf "\\verbatim{~a}" x)]
      [`(italic ,@xs) (begin (display "{\\it ") (map main1 xs) (display "}"))]
      [`(bold ,@xs) (begin (display "{\\bf ") (map main1 xs) (display "}"))]
      [`(emph ,@xs) (begin (display "{\\em ") (map main1 xs) (display "}"))]
      [`(tt ,@xs) (begin (display "{\\tt ") (map main1 xs) (display "}"))]
      [`(elem ,@xs) (map main1 xs)]
      [`(item ,@xs) (begin (display "\\item ") (map main1 xs) (displayln ""))]
      [`(itemlist #:style 'ordered ,@xs)
       (begin (displayln "\n\\begin{enumerate}") (map main1 xs) (displayln "\n\\end{enumerate}\n"))]
      [`(itemlist ,@xs)
       (begin (displayln "\n\\begin{itemize}") (map main1 xs) (displayln "\n\\end{itemize}\n"))]
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
       (begin (display "\\section{") (main1 ttl) (printf "}\\label{~a}" lbl))]
      [`(subpage 1 ,ttl #:tag ,@lbletc)
       (begin (display "\\subsection{") (main1 ttl) (printf "}\\label{~a}" (car lbletc)))]
      [`(subpage 2 ,ttl #:tag ,@lbletc)
       (begin (display "\\subsubsection{") (main1 ttl) (printf "}\\label{~a}" (car lbletc)))]
      [`(subpage 3 ,ttl #:tag ,@lbletc)
       (begin (display "\\paragraph{") (main1 ttl) (printf "}\\label{~a}" (car lbletc)))]
      [`(section #:tag ,tg ,@xs)
       (begin (display "\\section{") (map main1 xs) (printf "}\\label{~a}" tg))]
      [`(subsection #:tag ,tg ,@xs)
       (begin (display "\\subsection{") (map main1 xs) (printf "}\\label{~a}" tg))]
      [`(subsubsection #:tag ,tg ,@xs)
       (begin (display "\\subsubsection{") (map main1 xs) (printf "}\\label{~a}" tg))]
      [`(section ,@xs)
       (begin (display "\\section{") (map main1 xs) (displayln "}"))]
      [`(subsection ,@xs)
       (begin (display "\\subsection{") (map main1 xs) (displayln "}"))]
      [`(subsubsection ,@xs)
       (begin (display "\\subsubsection{") (map main1 xs) (displayln "}"))]
      [`(f ,@xs)
       (begin (display "$") (map main1 xs) (display "$"))]
      [`(v+ ,_ ,f) (main1 f)]
      [`(v- ,_ ,f) (main1 f)]
      [`(h+ ,_ ,f) (main1 f)]
      [`(h- ,_ ,f) (main1 f)]
      [`(th-num ,x) (printf "\\refstepcounter{Theorems}\\label{~a}\\noindent{\\bf \\arabic{Theorems}}" x)]
      [`(th-ref ,x) (printf "\\ref{~a}" x)]
      [`(defn-num ,x) (printf "\\refstepcounter{Definitions}\\label{_a}\\noindent{\\bf \\arabic{Definitions}}" x)]
      [`(defn-ref ,x) (printf "\\ref{~a}" x)]
      [`(spn attn ,@xs) (begin (display "{\\bf ") (map main1 xs) (display "}"))]
      [`(ref ,x) (printf "\\ref{~a}" x)]
      [`(div s ,@xs) (begin (display "{\\bf ") (map main1 xs) (display "}"))]
      [`(hyperlink ,url ,@xs) ;TODO add blue color
       (printf "\\href{~a}{~a}" url (with-output-to-string (λ () (map main1 xs))))]
      [`(spn attn ,@xs) ;TODO do something more expressive
       (begin (display "{\\bf ") (map main1 xs) (display "}"))]
      [`(spn TODO ,@xs) ;TODO do something more expressive
       (begin (display "{\\LARGE \\bf ") (map main1 xs) (display "}"))]
      [`(e #:label ,lbl ,@xs)
       (begin (printf "\\begin{equation}\\label{~a}" lbl) (map main1 xs) (display "\\end{equation}"))]
      [`(e ,@xs)
       (begin (display "\\begin{equation}") (map main1 xs) (display "\\end{equation}"))]
      [`(image ,x) (printf "\\includegraphics{~a}" (replace-svg-with-png x))]
      [`(image #:scale ,f ,x) (printf "\\includegraphics[scale=~a]{~a}" f (replace-svg-with-png x))]
      [`(tbl #:orient ,_ `(quasiquote ,rows))
       (begin
         (display "\n\\begin{tabular}{")
         (for ([_ (car rows)]) (display " | c "))
         (displayln "| }")
         (map main1 rows)
         (displayln "\n\\end{tabular}"))]
      [`(align l.n ,@xs)
       (main1
        `(align
          r.l.n
          ,@(for/list ([row xs]) 
              (match row
                [(list 'quasiquote `(,f ,lbl)) `("" ,f ,lbl)]
                [`(,f ,lbl) `("" ,f ,lbl)]))))]
      [`(align r.l.n ,@xs)
       (letrec ([unq (λ (x)
                       (match x
                         [(list 'unquote y) y]
                         [y y]))]
                [unv (λ (x)
                       (match x
                         [(list 'v+ n f) f]
                         [(list 'v- n f) f]
                         [r r]))]
                [m (λ (x)
                     (match (unv (unq x))
                       [`(f ,@xs) (map main1 xs)]
                       [`(elem #:style 'no-break ,@xs)
                        (begin (display "\\mbox{") (map main1 xs) (display "}"))]
                       ["" (display "")]
                       ))]
                [f (λ (row)
                     (match row
                       [`(bystro-scrbl-only ,@rest) (display "")]
                       [`(quasiquote ,rest) (f (apply list (map unq rest)))]
                       [(list f1 f2 `(label ,lbl))
                        (begin (displayln "") (m f1) (display " & ") (m f2) (printf "\\label{~a}" lbl))]
                       [(list f1 f2 "")
                        (begin (displayln "") (m f1) (display " & ") (m f2))]
                       ))])
         (display "\\begin{align}")
         (f (car xs))
         (for ([row (cdr xs)])
           (display " \\\\")
           (f row)
           )
         (display "\\end{align}"))]
      
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ; finally, to catch them all :
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      [`(spn TODO ,@xs) (void)]
      [x #:when (string? x) (display x)]
      [x (unless (extra-rules x) (displayln x (current-error-port)))]
      )
    )
  )

