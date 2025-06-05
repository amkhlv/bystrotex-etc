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
  (define current-page #f)
  (provide (contract-out
            [print-latex (->*  ((listof any/c)) (#:page (or/c #f string?) #:extras (-> any/c boolean?) #:output-to output-port?) (values))]))
  (define (print-latex xs #:page [p #f] #:extras [h (λ (_) #f)] #:output-to [out (current-output-port)])
    (parameterize ([current-output-port out])
      (for ([x xs]) (main x p #:extras h))
      )
    (values))
  (define (main xpr req-pg #:extras extra-rules)
    (define (main0 x) (main x req-pg #:extras extra-rules))
    (define (disp y)
      (when (or (not req-pg) (equal? current-page req-pg))
        (display y)))
    (define (displn y)
      (when (or (not req-pg) (equal? current-page req-pg))
        (displayln y)))
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
      [`(apply ,f (quasiquote ,xs)) (main0 `(,f ,@xs))]
      [(list 'unquote x) (main0 x)]
      [`(use-LaTeX-preamble ,@xs)
       (begin
         (displn "\n%BystroTeX-preamble-start\n")
         (map main0 xs)
         (displn "\n%BystroTeX-preamble-end\n"))]
      [`(void "BystroTeX-start-appendix") (displn "\\appendix")]
      [`(indent ,@xs) (map main0 xs)]
      [`(indent---> ,@xs) (map main0 xs)]
      [`(cite ,x) (printf "\\cite{~a}" x)]
      [`(seclink ,@xs) (printf "Section \\ref{~a}" (car xs))]
      [`(verb ,x) (printf "\\verbatim{~a}" x)]
      [`(italic ,@xs) (begin (disp "{\\it ") (map main0 xs) (disp "}"))]
      [`(bold ,@xs) (begin (disp "{\\bf ") (map main0 xs) (disp "}"))]
      [`(emph ,@xs) (begin (disp "{\\em ") (map main0 xs) (disp "}"))]
      [`(tt ,@xs) (begin (disp "{\\tt ") (map main0 xs) (disp "}"))]
      [`(elem ,@xs) (map main0 xs)]
      [`(item ,@xs) (begin (disp "\\item ") (map main0 xs) (displn ""))]
      [`(itemlist #:style 'ordered ,@xs)
       (begin (displn "\n\\begin{enumerate}") (map main0 xs) (displn "\n\\end{enumerate}\n"))]
      [`(itemlist ,@xs)
       (begin (displn "\n\\begin{itemize}") (map main0 xs) (displn "\n\\end{itemize}\n"))]
      [`(comment ,@xs)
       (begin (disp "\\footnote{") (map main0 xs) (disp "}"))]
      [`(summary ,@xs) (map main0 xs)]
      [`(larger ,@xs)
       (begin (disp "{\\large ") (map main0 xs) (disp "}"))]
      [`(larger-2 ,@xs)
       (begin (disp "{\\Large ") (map main0 xs) (disp "}"))]
      [`(lsrger-3 ,@xs)
       (begin (disp "{\\LARGE ") (map main0 xs) (disp "}"))]
      ['noindent (disp "\\noindent ")]
      [`(linebreak) (disp "\n\n\\vspace{10pt}\n")]
      [`(hspace ,n) (printf "\\hspace{~aex}" n)]
      [`(hrule) (disp "\\rule ")]
      [`(page ,ttl #:tag ,lbl ,@xs)
       (begin
         (set! current-page lbl)
         (unless req-pg
           (begin (disp "\\section{") (main0 ttl) (printf "}\\label{~a}" lbl))
           ))]
      [`(subpage 1 ,ttl #:tag ,@lbletc)
       (begin (disp "\\subsection{") (main0 ttl) (printf "}\\label{~a}" (car lbletc)))]
      [`(subpage 2 ,ttl #:tag ,@lbletc)
       (begin (disp "\\subsubsection{") (main0 ttl) (printf "}\\label{~a}" (car lbletc)))]
      [`(subpage 3 ,ttl #:tag ,@lbletc)
       (begin (disp "\\paragraph{") (main0 ttl) (printf "}\\label{~a}" (car lbletc)))]
      [`(section #:tag ,tg ,@xs)
       (begin (disp "\\section{") (map main0 xs) (printf "}\\label{~a}" tg))]
      [`(subsection #:tag ,tg ,@xs)
       (begin (disp "\\subsection{") (map main0 xs) (printf "}\\label{~a}" tg))]
      [`(subsubsection #:tag ,tg ,@xs)
       (begin (disp "\\subsubsection{") (map main0 xs) (printf "}\\label{~a}" tg))]
      [`(section ,@xs)
       (begin (disp "\\section{") (map main0 xs) (displn "}"))]
      [`(subsection ,@xs)
       (begin (disp "\\subsection{") (map main0 xs) (displn "}"))]
      [`(subsubsection ,@xs)
       (begin (disp "\\subsubsection{") (map main0 xs) (displn "}"))]
      [`(f ,@xs)
       (begin (disp "$") (map main0 xs) (disp "$"))]
      [`(v+ ,_ ,f) (main0 f)]
      [`(v- ,_ ,f) (main0 f)]
      [`(h+ ,_ ,f) (main0 f)]
      [`(h- ,_ ,f) (main0 f)]
      [`(th-num ,x) (printf "\\refstepcounter{Theorems}\\label{~a}\\noindent{\\bf \\arabic{Theorems}}" x)]
      [`(th-ref ,x) (printf "\\ref{~a}" x)]
      [`(defn-num ,x) (printf "\\refstepcounter{Definitions}\\label{~a}\\noindent{\\bf \\arabic{Definitions}}" x)]
      [`(defn-ref ,x) (printf "\\ref{~a}" x)]
      [`(spn attn ,@xs) (begin (disp "{\\bf ") (map main0 xs) (disp "}"))]
      [`(ref ,x) (printf "\\ref{~a}" x)]
      [`(div s ,@xs) (begin (disp "{\\bf ") (map main0 xs) (disp "}"))]
      [`(hyperlink ,url ,@xs) ;TODO add blue color
       (printf "\\href{~a}{~a}" url (with-output-to-string (λ () (map main0 xs))))]
      [`(spn attn ,@xs) ;TODO do something more expressive
       (begin (disp "{\\bf ") (map main0 xs) (disp "}"))]
      [`(spn TODO ,@xs) ;TODO do something more expressive
       (begin (disp "{\\LARGE \\bf ") (map main0 xs) (disp "}"))]
      [`(e #:label ,lbl ,@xs)
       (begin (printf "\\begin{equation}\\label{~a}" lbl) (map main0 xs) (disp "\\end{equation}"))]
      [`(e ,@xs)
       (begin (disp "\\begin{equation}") (map main0 xs) (disp "\\end{equation}"))]
      [`(image ,x) (printf "\\includegraphics{~a}" (replace-svg-with-png x))]
      [`(image #:scale ,f ,x) (printf "\\includegraphics[scale=~a]{~a}" f (replace-svg-with-png x))]
      [`(image #:scale ,f ,x ,@caps)
       (begin
         (printf "\\begin{figure}\\centering\\includegraphics[scale=~a]{~a}\\caption{" f (replace-svg-with-png x))
         (map main0 caps)
         (displn "}\\end{figure}")
         )
       ]
      [`(tbl #:orient ,_ `(quasiquote ,rows))
       (begin
         (disp "\n\\begin{tabular}{")
         (for ([_ (car rows)]) (disp " | c "))
         (displn "| }")
         (map main0 rows)
         (displn "\n\\end{tabular}"))]
      [`(align l.n ,@xs)
       (main0
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
                       [`(f ,@xs) (map main0 xs)]
                       [`(elem #:style 'no-break ,@xs)
                        (begin (disp "\\mbox{") (map main0 xs) (disp "}"))]
                       ["" (disp "")]
                       ))]
                [f (λ (row)
                     (match row
                       [`(bystro-scrbl-only ,@rest) (disp "")]
                       [`(quasiquote ,rest) (f (apply list (map unq rest)))]
                       [(list f1 f2 `(label ,lbl))
                        (begin (displn "") (m f1) (disp " & ") (m f2) (printf "\\label{~a}" lbl))]
                       [(list f1 f2 "")
                        (begin (displn "") (m f1) (disp " & ") (m f2))]
                       ))])
         (disp "\\begin{align}")
         (f (car xs))
         (for ([row (cdr xs)])
           (disp " \\\\")
           (f row)
           )
         (disp "\\end{align}"))]
      
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ; finally, to catch them all :
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      [`(spn TODO ,@xs) (void)]
      [x #:when (string? x) (disp x)]
      [x (unless (extra-rules x) (displayln x (current-error-port)))]
      )
    )
  )

