#!/usr/bin/env racket

#lang racket/base

;;; bystro-to-pdf.rkt
;;; ─────────────────────────────────────────────────────────────────────────
;;; Convert a BystroTeX-generated HTML document (single- or multi-page) to
;;; a PDF file using a headless browser and pdftk / pdfunite.
;;;
;;; Usage:
;;;   racket bystro-to-pdf.rkt [options] <main.html>
;;;
;;; Options:
;;;   -b / --browser  chromium | chrome | firefox | /path/to/exe
;;;                   (default: auto-detect)
;;;   -o / --output   output PDF filename
;;;                   (default: <main>.pdf in the same directory)
;;;
;;; For single-page documents the HTML file is printed directly.
;;; For multi-page documents the navigation chain is followed from
;;; <main.html> (via the .navright links Scribble inserts on every page),
;;; each page is printed to a temporary PDF, and the results are merged
;;; in order using pdftk or pdfunite.
;;; ─────────────────────────────────────────────────────────────────────────

(require racket/file
         racket/system
         racket/path
         racket/string
         racket/cmdline)

;; ═══════════════════════════════════════════════════════════════════════════
;; Browser detection and dispatch
;; ═══════════════════════════════════════════════════════════════════════════

;; Candidate executable names for each logical browser type.
(define browser-candidates
  '((chromium . ("chromium" "chromium-browser"))
    (chrome   . ("google-chrome" "google-chrome-stable" "google-chrome-beta"))
    (firefox  . ("firefox" "firefox-esr" "firefox-bin"))))

(define (find-exe-for type)
  (define candidates (cdr (assq type browser-candidates)))
  (or (for/first ([c candidates]
                  #:when (find-executable-path c))
        (find-executable-path c))
      (error (format "No ~a executable found in PATH; tried: ~a"
                     type (string-join candidates ", ")))))

;; Resolve the --browser argument to an absolute path.
;; Accepts a symbolic name ("chromium", "chrome", "firefox") or
;; an explicit path to an executable.
(define (resolve-browser spec)
  (define sym (string->symbol spec))
  (cond
    [(assq sym browser-candidates) (find-exe-for sym)]
    [(find-executable-path spec)   (find-executable-path spec)]
    [(and (file-exists? spec)
          (string->path spec))     (string->path spec)]
    [else (error "Browser executable not found:" spec)]))

;; Auto-detect: try chromium first, then chrome, then firefox.
(define (auto-detect-browser)
  (or (for*/first ([type '(chromium chrome firefox)]
                   [c    (cdr (assq type browser-candidates))]
                   #:when (find-executable-path c))
        (find-executable-path c))
      (error "No supported browser found in PATH.\n\
              Install chromium, google-chrome, or firefox, \
              or use --browser /path/to/exe")))

;; ───────────────────────────────────────────────────────────────────────────
;; Print one HTML file → one PDF file
;; ───────────────────────────────────────────────────────────────────────────

(define (absolute-str p)
  (path->string (path->complete-path p)))

(define (chromium-print! exe html-path pdf-path)
  (define url (string-append "file://" (absolute-str html-path)))
  (define code
    (system*/exit-code
     exe
     "--headless=new"
     "--disable-gpu"
     "--no-sandbox"
     "--print-to-pdf-no-header"
     (format "--print-to-pdf=~a" (absolute-str pdf-path))
     url))
  (unless (zero? code)
    (error "Chromium/Chrome exited with non-zero status" code)))

(define (firefox-print! exe html-path pdf-path)
  ;; Firefox ≥ 96 supports --headless --print-to-file.
  ;; Note: @page margin support in Firefox headless is less reliable
  ;; than in Chromium — results may vary.
  (define url (string-append "file://" (absolute-str html-path)))
  (define code
    (system*/exit-code
     exe
     "--headless"
     (format "--print-to-file=~a" (absolute-str pdf-path))
     url))
  (unless (zero? code)
    (error "Firefox exited with non-zero status" code)))

(define (exe-basename exe)
  (path->string (file-name-from-path exe)))

(define (print-page! exe html-path pdf-path)
  (define name (exe-basename exe))
  (cond
    [(or (string-prefix? "chromium" name)
         (string-prefix? "google-chrome" name))
     (chromium-print! exe html-path pdf-path)]
    [(string-prefix? "firefox" name)
     (firefox-print! exe html-path pdf-path)]
    [else
     ;; Unknown path supplied by user — assume Chromium-compatible flags.
     (chromium-print! exe html-path pdf-path)]))

;; ═══════════════════════════════════════════════════════════════════════════
;; PDF merging
;; ═══════════════════════════════════════════════════════════════════════════

(define (find-merge-tool)
  (or (find-executable-path "pdftk")
      (find-executable-path "pdfunite")
      (error "Neither pdftk nor pdfunite found in PATH.\n\
              Install one of them (e.g. `apt install pdftk` or \
              `apt install poppler-utils`).")))

(define (merge-pdfs! pdf-paths output-path)
  (define tool (find-merge-tool))
  (define name (exe-basename tool))
  (define abs-outs (map absolute-str pdf-paths))
  (define abs-out  (absolute-str output-path))
  (define code
    (cond
      [(string=? name "pdftk")
       ;; pdftk in1.pdf in2.pdf … cat output out.pdf
       (apply system*/exit-code
              tool
              (append abs-outs (list "cat" "output" abs-out)))]
      [(string=? name "pdfunite")
       ;; pdfunite in1.pdf in2.pdf … out.pdf
       (apply system*/exit-code
              tool
              (append abs-outs (list abs-out)))]))
  (unless (zero? code)
    (error "PDF merge failed with" name)))

;; ═══════════════════════════════════════════════════════════════════════════
;; Navigation-chain traversal
;; ═══════════════════════════════════════════════════════════════════════════

;; Extract the href of the "next page" link from a Scribble HTML file.
;; Scribble renders:  <span class="navright">…<a href="NEXT.html">…</span>
;; We use a permissive regex so minor Scribble version differences don't
;; break matching.
(define (next-page-href html-str)
  (define m
    (regexp-match
     #rx"navright[^<]{0,300}<a href=\"([^\"#][^\"]*\\.html)\""
     html-str))
  (and m (cadr m)))

;; Follow the .navright chain starting from START-FILE inside DIR.
;; Returns a list of filenames (strings), in page order.
(define (collect-pages start-file dir)
  (let loop ([current start-file] [acc (list start-file)])
    (define content (file->string (build-path dir current)))
    (define next    (next-page-href content))
    (if (and next (not (member next acc)))
        (loop next (append acc (list next)))
        acc)))

;; ═══════════════════════════════════════════════════════════════════════════
;; Zero-padded integer string (for temp-file naming)
;; ═══════════════════════════════════════════════════════════════════════════

(define (zpad n width)
  (define s (number->string n))
  (string-append (make-string (max 0 (- width (string-length s))) #\0) s))

;; ═══════════════════════════════════════════════════════════════════════════
;; Entry point
;; ═══════════════════════════════════════════════════════════════════════════

(module+ main
  (define browser-spec (make-parameter #f))   ; #f = auto-detect
  (define output-spec  (make-parameter #f))

  (define start-html
    (command-line
     #:program "bystro-to-pdf"
     #:once-each
     [("-b" "--browser") b
      "Browser: chromium (default auto-detect), chrome, firefox, or /path/to/exe"
      (browser-spec b)]
     [("-o" "--output") pdf
      "Output PDF path (default: <input>.pdf)"
      (output-spec pdf)]
     #:args (html-file)
     html-file))

  (define html-path  (string->path start-html))
  (define abs-html   (path->complete-path html-path))
  (define dir        (path-only abs-html))
  (define base-name  (path->string (file-name-from-path abs-html)))

  (define out-path
    (string->path
     (or (output-spec)
         (path->string (path-replace-suffix abs-html ".pdf")))))

  (define exe
    (if (browser-spec)
        (resolve-browser (browser-spec))
        (auto-detect-browser)))

  (printf "Browser: ~a\n" (absolute-str exe))

  ;; Collect pages by following .navright chain
  (define pages (collect-pages base-name dir))
  (printf "Pages (~a): ~a\n" (length pages) (string-join pages ", "))

  (cond
    ;; ── Single-page document ──────────────────────────────────────────────
    [(= 1 (length pages))
     (printf "Single-page document — printing directly…\n")
     (print-page! exe html-path out-path)
     (printf "Done: ~a\n" (absolute-str out-path))]

    ;; ── Multi-page document ───────────────────────────────────────────────
    [else
     (printf "Multi-page document — printing ~a pages…\n" (length pages))
     (define tmp-dir (make-temporary-file "bystrotex-pdf-~a" 'directory))
     (dynamic-wind
       void
       (lambda ()
         ;; Print each page to a numbered temp PDF
         (define part-pdfs
           (for/list ([page pages] [i (in-naturals)])
             (define pdf-path
               (build-path tmp-dir (string-append (zpad i 4) ".pdf")))
             (printf "  [~a/~a] ~a\n" (add1 i) (length pages) page)
             (print-page! exe (build-path dir page) pdf-path)
             pdf-path))
         ;; Merge
         (printf "Merging ~a PDFs…\n" (length part-pdfs))
         (merge-pdfs! part-pdfs out-path)
         (printf "Done: ~a\n" (absolute-str out-path)))
       ;; Always clean up temp files
       (lambda ()
         (for ([f (directory-list tmp-dir #:build? #t)])
           (with-handlers ([exn:fail? void]) (delete-file f)))
         (with-handlers ([exn:fail? void]) (delete-directory tmp-dir))))]))
