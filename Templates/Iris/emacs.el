;;; island-theme.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 Vladislav
;;
;; Author: Vladislav <nikko@cachyos-x8664>
;; Maintainer: Vladislav <nikko@cachyos-x8664>
;; Created: июля 31, 2026
;; Modified: июля 31, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex text tools unix vc wp
;; Homepage: https://github.com/nikko/island-theme
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(require 'doom-themes)

(defgroup island-theme nil
  "Options for the iris theme."
  :group 'doom-themes)

(def-doom-theme island
  "A theme generated from the current wallpaper by iris."

  ;;;; Color palette
  ;; name        gui          256   16
  ((bg          '("{bg}"      nil   nil))
   (bg-alt      '("{surface}" nil   nil))
   (fg          '("{fg}"      nil   nil))
   (fg-alt      '("{dim}"     nil   nil))

   ;; base0 is the "darkest" end, base8 the "lightest" (inverted in light mode,
   ;; which is fine — iris already flips color0/color15 for you)
   (base0       '("{bg}"       nil nil))
   (base1       '("{color0}"   nil nil))
   (base2       '("{surface}"  nil nil))
   (base3       '("{color8}"   nil nil))
   (base4       '("{dim}"      nil nil))
   (base5       '("{color7}"   nil nil))
   (base6       '("{color7}"   nil nil))
   (base7       '("{color15}"  nil nil))
   (base8       '("{color15}"  nil nil))

   (grey        base4)
   (red         '("{red}"      nil nil))
   (orange      '("{color9}"   nil nil))
   (green       '("{green}"    nil nil))
   (teal        '("{color6}"   nil nil))
   (yellow      '("{yellow}"   nil nil))
   (blue        '("{color12}"  nil nil))
   (dark-blue   '("{color4}"   nil nil))
   (magenta     '("{color13}"  nil nil))
   (violet      '("{color5}"   nil nil))
   (cyan        '("{color14}"  nil nil))
   (dark-cyan   '("{color6}"   nil nil))

   ;;;; Face categories
   (highlight      '("{accent}"  nil nil))
   (vertical-bar   base2)
   (selection      base2)
   (builtin        '("{syntax_func}"     nil nil))
   (comments       '("{syntax_comment}"  nil nil))
   (doc-comments   '("{syntax_comment}"  nil nil))
   (constants      '("{syntax_const}"    nil nil))
   (functions      '("{syntax_func}"     nil nil))
   (keywords       '("{syntax_keyword}"  nil nil))
   (methods        '("{syntax_func}"     nil nil))
   (operators      '("{syntax_operator}" nil nil))
   (type           '("{syntax_type}"     nil nil))
   (strings        '("{syntax_string}"   nil nil))
   (variables      '("{syntax_param}"    nil nil))
   (numbers        '("{syntax_const}"    nil nil))
   (region         base2)
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    yellow)
   (vc-added       green)
   (vc-deleted     red)

   ;;;; Custom
   (modeline-bg     bg-alt)
   (modeline-bg-alt bg)
   (modeline-fg     fg)
   (modeline-fg-alt fg-alt))

  ;;;; Face overrides
  (((line-number             &override) :foreground base4)
   ((line-number-current-line &override) :foreground highlight :weight 'bold)
   (cursor  :background highlight)
   (mode-line          :background modeline-bg :foreground modeline-fg)
   (mode-line-inactive :background modeline-bg-alt :foreground modeline-fg-alt)
   ((font-lock-comment-face &override) :slant 'italic)
   (doom-modeline-bar :background highlight)
   (tooltip :background bg-alt :foreground fg)

   ;;;; Selection — surface sits too close to bg to read as a highlight,
   ;;;; so these are blended off the accent instead.
   (region  :background (doom-blend highlight bg 0.15) :extend t)
   (hl-line :background (doom-blend fg bg 0.07))
   (vertico-current :background (doom-blend highlight bg 0.22)
                    :foreground fg :extend t)
   (vertico-group-title :foreground highlight :weight 'bold)

   ;;;; Match highlighting
   ((completions-common-part &override) :foreground highlight :weight 'bold)
   (orderless-match-face-0 :foreground highlight :weight 'bold)
   (orderless-match-face-1 :foreground magenta   :weight 'bold)
   (orderless-match-face-2 :foreground green     :weight 'bold)
   (orderless-match-face-3 :foreground yellow    :weight 'bold))

  ;;;; Variable overrides
  ())

(provide-theme 'island)
;;; island-theme.el ends here
