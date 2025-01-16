#!/usr/bin/env racket

#lang racket

(require scribble/reader bystroTeX/generate-asciidoc racket/cmdline)

(define input-file #f)
(define output-file #f)
(define bibtex-file #f)
(define extra-rules-file #f)

(command-line
 #:program "bystroTeX to AsciiDoc"
 #:once-each
 [("-i" "--input-file") i "input file (.scrbl)" (set! input-file i)]
 [("-o" "--output-file") o "output file (.adoc)" (set! output-file o)]
 [("-b" "--bibtex-file") b "BibTeX file (.bib)" (set! bibtex-file b)]
 [("-x" "--extra-rules-require") x.rkt "extra rules file" (set! extra-rules-file x.rkt)]
 )

(define x-rules (if extra-rules-file (dynamic-require extra-rules-file 'rules) (λ (_) #f)))

(unless (and input-file output-file)
  (error "not all arguments are given"))

(call-with-output-file
  output-file
  #:exists 'replace
  (λ (out)
    (define title (get-title (read-inside (open-input-file input-file))))
    (define abstract (get-abstract (read-inside (open-input-file input-file))))
    (let-values ([(i o) (make-pipe)])
      (thread (λ ()
                (fprintf o "= ~a\n" title)
                (fprintf o ":bibtex-file: ~a\n" bibtex-file)
                (displayln ":stem: latexmath\n" o)
                (displayln ":mathematical-format: svg\n" o)
                (print-adoc #:extras x-rules #:output-to o (read-inside (open-input-file input-file)))
                (displayln "bibliography::[]" o)
                (close-output-port o)
                ))
      (let rec ([line (read-line i)])
        (unless (eof-object? line)
          (unless
              (regexp-match? #px"#lang\\s+scribble/base" line)
            (displayln
             (string-replace
              (string-replace
               line
               "〚" "")
              "〛" ""
              )
             out)
            )
          (rec (read-line i))))
      (close-input-port i)
      )
    )
  )
