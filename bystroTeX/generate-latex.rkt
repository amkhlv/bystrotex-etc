(module generate-latex racket
  (require racket/match scribble/srcdoc)
  
  (provide (proc-doc
            print-latex
            (->i  ([_ (listof any/c)])  ()  (values))
            ("prints LaTeX")))
  (define (print-latex xs) (map main xs) (values))

  (provide main)
  (define (main xpr)
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
      [`(use-LaTeX-preamble ,@xs)
       (begin
         (displayln "\n%BystroTeX-preamble-start\n")
         (map main xs)
         (displayln "\n%BystroTeX-preamble-end\n"))]
      [`(void "BystroTeX-start-appendix") (displayln "\\appendix")]
      [`(indent ,@xs) (map main xs)]
      [`(indent---> ,@xs) (map main xs)]
      [`(cite ,x) (printf "\\cite{~a}" x)]
      [`(seclink ,@xs) (printf "\\Section \\ref{~a}" (car xs))]
      [`(verb ,x) (printf "\\verbatim{~a}" x)]
      [`(italic ,@xs) (begin (display "{\\it ") (map main xs) (display "}"))]
      [`(bold ,@xs) (begin (display "{\\bf ") (map main xs) (display "}"))]
      [`(emph ,@xs) (begin (display "{\\em ") (map main xs) (display "}"))]
      [`(tt ,@xs) (begin (display "{\\tt ") (map main xs) (display "}"))]
      [`(elem ,@xs) (map main xs)]
      [`(item ,@xs) (begin (display "\\item") (map main xs) (displayln ""))]
      [`(itemlist #:style ordered ,@xs)
       (begin (displayln "\n\\begin{enumerate}") (map main xs) (displayln "\n\\end{enumerate}\n"))]
      [`(itemlist ,@xs)
       (begin (displayln "\n\\begin{itemize}") (map main xs) (displayln "\n\\end{itemize}\n"))]
      [`(comment ,@xs)
       (begin (display "\\footnote{") (map main xs) (display "}"))]
      [`(summary ,@xs) (map main xs)]
      [`(larger ,@xs)
       (begin (display "{\\large ") (map main xs) (display "}"))]
      [`(larger-2 ,@xs)
       (begin (display "{\\Large ") (map main xs) (display "}"))]
      [`(lsrger-3 ,@xs)
       (begin (display "{\\LARGE ") (map main xs) (display "}"))]
      ['noindent (display "\\noindent ")]
      [`(linebreak) (display "\n\n\\vspace{10pt}\n")]
      [`(hspace ,n) (printf "\\hspace{~a}" n)]
      [`(hrule) (display "\\rule ")]
      [`(page #:tag ,lbl ,@xs)
       (begin (display "\\section{") (map main xs) (printf "}\\label{~a}" lbl))]
      [`(subpage 1 ,ttl #:tag ,@lbletc)
       (begin (display "\\subsection{") (main ttl) (printf "}\\label{~a}" (car lbletc)))]
      [`(subpage 2 ,ttl #:tag ,@lbletc)
       (begin (display "\\subsubsection{") (main ttl) (printf "}\\label{~a}" (car lbletc)))]
      [`(subpage 3 ,ttl #:tag ,@lbletc)
       (begin (display "\\paragraph{") (main ttl) (printf "}\\label{~a}" (car lbletc)))]
      [`(section #:tag ,tg ,@xs)
       (begin (display "\\section{") (map main xs) (printf "}\\label{~a}" tg))]
      [`(subsection #:tag ,tg ,@xs)
       (begin (display "\\subsection{") (map main xs) (printf "}\\label{~a}" tg))]
      [`(subsubsection #:tag ,tg ,@xs)
       (begin (display "\\subsubsection{") (map main xs) (printf "}\\label{~a}" tg))]
      [`(section ,@xs)
       (begin (display "\\section{") (map main xs) (displayln "}"))]
      [`(subsection ,@xs)
       (begin (display "\\subsection{") (map main xs) (displayln "}"))]
      [`(subsubsection ,@xs)
       (begin (display "\\subsubsection{") (map main xs) (displayln "}"))]
      [`(f ,@xs)
       (begin (display "$") (map main xs) (display "$"))]
      [`(v+ ,_ ,f) (main f)]
      [`(v- ,_ ,f) (main f)]
      [`(h+ ,_ ,f) (main f)]
      [`(h- ,_ ,f) (main f)]
      [`(th-num ,x) (printf "\\refstepcounter{Theorems}\\label{~a}\\noindent{\\bf \\arabic{Theorems}}" x)]
      [`(th-ref ,x) (printf "\\ref{~a}" x)]
      [`(defn-num ,x) (printf "\\refstepcounter{Definitions}\\label{_a}\\noindent{\\bf \\arabic{Definitions}}" x)]
      [`(defn-ref ,x) (printf "\\ref{~a}" x)]
      [`(spn attn ,@xs) (begin (display "{\\bf ") (map main xs) (display "}"))]
      [`(ref ,x) (printf "\\ref{~a}" x)]
      [`(div s ,@xs) (begin (display "{\\bf ") (map main xs) (display "}"))]
      [`(hyperlink ,url ,@xs) ;TODO add blue color
       (printf "\\href{~a}{~a}" url (with-output-to-string (λ () (map main xs))))]
      [`(spn attn ,@xs) ;TODO do something more expressive
       (begin (display "{\\bf ") (map main xs) (display "}"))]
      [`(e #:label ,lbl ,@xs)
       (begin (printf "\\begin{equation}\\label{~a}" lbl) (map main xs) (display "\\end{equation}"))]
      [`(e ,@xs)
       (begin (display "\\begin{equation}") (map main xs) (display "\\end{equation}"))]
      ; finally, to catch them all:
      [x (display x)]
      )
    )
  )

