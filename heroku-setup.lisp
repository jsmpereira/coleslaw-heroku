(in-package :cl-user)

(print ">>> Setting up web server....\n")

;; *build-dir* is set from Heroku env variable BUILD_DIR, on heroku-buildpack-cl

(ql:quickload :coleslaw)
(in-package :coleslaw)

;; Redefine some coleslaw functions to account for Heroku's read-only filesystem.

;; Everything is built under *build-dir* so :repo and :deploy
;; should account for that.
;; Posts live in our heroku repo under /posts.
;; Also place .coleslawrc on our repository root.
(defun load-config ()
  "Load the coleslaw configuration from DIR/.coleslawrc. DIR is ~ by default."
  (let ((dir (make-pathname :directory cl-user::*build-dir*)))
    (with-open-file (in (merge-pathnames ".coleslawrc" dir))
      (setf *config* (apply #'make-instance 'blog (read in))))
    (setf (repo *config*) (merge-pathnames (make-pathname :directory '(:relative "posts")) dir))
    (setf (deploy *config*) dir)
    (load-plugins (plugins *config*))))

;; We need to create the symlinks .curr and .pre to account for the fact that the app
;; will be served from /app. However index.html points to 1.html under current build.
(defun update-symlink (path target)
  "Update the symlink at PATH to point to TARGET."
  (if (and (stringp target) (string= target "1.html"))
      (run-program "ln -sfn ~a ~a" target path)
      (run-program "ln -sfn ~a ~a" (merge-pathnames (enough-namestring target (make-pathname :directory cl-user::*build-dir*)) (make-pathname :directory "app")) path)))

;; Create our blog
(coleslaw:main)

;;; Hunchentoot
(in-package :hunchentoot)
;; Hunchentoot fix for (create-folder-dispatcher-and-handler) with uri-prefix "/", should be available in next ql release.
(defun parse-path (path)
  "Return a relative pathname that has been verified to not contain
  any directory traversals or explicit device or host fields.  Returns
  NIL if the path is not acceptable."
  (when (every #'graphic-char-p path)
    (let* ((pathname (pathname (remove #\\ (regex-replace "^/*" path ""))))
           (directory (pathname-directory pathname)))
      (when (and (or (null (pathname-host pathname))
                     (equal (pathname-host pathname) (pathname-host *default-pathname-defaults*)))
                 (or (null (pathname-device pathname))
                     (equal (pathname-device pathname) (pathname-device *default-pathname-defaults*)))
                 (or (null directory)
                     (and (eql (first directory) :relative)
                          (every #'stringp (rest directory))))) ; only string components, no :UP traversals
        pathname))))

(defun request-pathname (&optional (request *request*) drop-prefix)
  "Construct a relative pathname from the request's SCRIPT-NAME.
If DROP-PREFIX is given, pathname construction starts at the first path
segment after the prefix.
"
  (let ((path (url-decode (script-name request))))
    (if drop-prefix
        (when (starts-with-p path drop-prefix)
          (parse-path (subseq path (length drop-prefix))))
        (parse-path path))))

;; Tell hunchentoot where to serve from and the point of entry
(push (create-folder-dispatcher-and-handler "/" "/app/.curr/")
      *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/" "/app/.curr/index.html")
      *dispatch-table*)

(print ">>> Done setting up web server.")
