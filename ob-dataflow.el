;;; ob-dataflow.el --- Dataflow diagram support for Org babel -*- lexical-binding: t -*-

;; Copyright (C) 2021 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (dataflow-diagram "0"))
;; Keywords: tools processes
;; URL: https://github.com/akirak/ob-dataflow

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides babel functions for dataflow diagrams:
;; https://github.com/sonyxperiadev/dataflow.

;; To use this library, you have to install two executables: dataflow and
;; GraphViz dot. See https://graphviz.org/ for information on dot.

;; Note that while dataflow itself supports dataflow diagrams (DFD) and sequence
;; diagrams, this library only supports DFD at present. To generate sequence
;; diagrams using Org Babel, you can use PlantUML instead. See
;; https://plantuml.com/emacs for information.

;;; Code:

(require 'dataflow-diagram)
(require 'ob)

(defgroup ob-dataflow nil
  "Dataflow diagram support for Org babel."
  :group 'dataflow-diagram
  :group 'org-babel)

(defcustom ob-dataflow-dot-executable "dot"
  "Path to a GraphViz dot executable."
  :type 'file
  :group 'ob-dataflow)

(defcustom ob-dataflow-dot-arguments nil
  "List of arguments to be passed to the dot command.

By customizing this variable, you can customize the appearance of
your diagrams. You can specify any options other than -T and -o.

For a list of supported arguments, see
<https://graphviz.org/doc/info/command.html>."
  :type '(repeat string)
  :group 'ob-dataflow)

(defvar org-babel-default-header-args:dataflow
  '((:results . "file")
    (:exports . "results")
    (:type . dfd))
  "Default arguments for evaluating a source block.")

(cl-defun ob-dataflow--dfd-commandline (&key in-file)
  "Return a command line for producing dot from IN-FILE."
  (mapconcat #'shell-quote-argument
             `(,dataflow-diagram-executable
               "dfd"
               ,in-file)
             " "))

(cl-defun ob-dataflow--dot-commandline (&key out-file)
  "Return a command line for producing an image to OUT-FILE."
  (let ((type (file-name-extension out-file)))
    (mapconcat #'shell-quote-argument
               `(,ob-dataflow-dot-executable
                 ,(concat "-T" type)
                 ,@ob-dataflow-dot-arguments
                 "-o" ,out-file)
               " ")))

(cl-defun ob-dataflow--dfd-and-dot-commandline (&key in-file
                                                     out-file)
  "Return a command line for producing an image from dataflow.

This function uses dataflow and dot in chain to produce an image.

IN-FILE is an input file in the dataflow syntax, and OUT-FILE is
the output file to be created."
  (concat (ob-dataflow--dfd-commandline :in-file in-file)
          " | "
          (ob-dataflow--dot-commandline :out-file out-file)))

(defun org-babel-execute:dataflow (body params)
  "Execute a block of plantuml code with org-babel.
This function is called by `org-babel-execute-src-block'.

BODY and PARAMS are from the babel source block."
  (let* ((out-file (or (cdr (assq :file params))
                       (user-error "You have to set an output file as :file parameter")))
         (in-file (org-babel-temp-file "dataflow-"))
         ;; Use org-babel-expand-body:generic if necessary.
         ;; See ob-plantuml.el for example
         (command (cl-case (cdr (assq :type params))
                    (dfd (ob-dataflow--dfd-and-dot-commandline
                          :in-file (org-babel-process-file-name in-file)
                          :out-file (org-babel-process-file-name out-file)))
                    (otherwise (user-error "Only the following :type keywords are allowed: dfd"
                                           (cdr (assq :type params)))))))
    (with-temp-file in-file (insert body))
    (message "%s" command)
    (org-babel-eval command "")
    nil))

(defun org-babel-prep-session:dataflow (_session _params)
  "Unsupported."
  (user-error "Session is not supported"))

(add-to-list 'org-src-lang-modes '("dataflow" . dataflow-diagram))

(provide 'ob-dataflow)
;;; ob-dataflow.el ends here
