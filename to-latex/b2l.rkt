#!/usr/bin/env racket

#lang racket

(require scribble/reader bystroTeX/generate-latex racket/cmdline)

(define input-file #f)
(define output-file #f)
(define header-file #f)
(define footer-file #f)

(command-line
 #:program "bystroTeX to LaTeX"
 #:once-each
 [("-i" "--input-file") i "input file (.scrbl)" (set! input-file i)]
 [("-o" "--output-file") o "output file (.tex)" (set! output-file o)]
 [("-t" "--header") h "header file (.tex)" (set! header-file h)]
 [("-b" "--footer") f "footer file (.tex)" (set! footer-file f)]
 )

(unless (and input-file output-file header-file footer-file)
  (error "not all arguments are given"))

(call-with-output-file
  output-file
  #:exists 'replace
  (λ (out) 
    (define title (get-title (read-inside (open-input-file input-file)))) 
    (define abstract (get-abstract (read-inside (open-input-file input-file))))
    (let-values ([(i o) (make-pipe)])
      (thread (λ ()
                (let ([header-input (open-input-file header-file)])
                  (for ([line (port->lines header-input)])
                    (cond
                      [(regexp-match? #px"^%TITLE" line) (displayln title o)]
                      [(regexp-match? #px"^%ABSTRACT" line) (displayln abstract o)]
                      [else (displayln line o)]))
                  (close-input-port header-input))
                (print-latex #:output-to o (read-inside (open-input-file input-file)))
                (let ([footer-input (open-input-file footer-file)])
                  (for ([line  (port->lines (open-input-file footer-file))])
                    (displayln line o))
                  (close-input-port footer-input))
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
