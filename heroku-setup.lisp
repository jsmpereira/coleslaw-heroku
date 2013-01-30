(in-package :cl-user)

(print ">>> Setting up Coleslaw Lisp Blogware....")

;; *build-dir* is set from Heroku env variable BUILD_DIR, on heroku-buildpack-cl

(ql:quickload :coleslaw)
(in-package :coleslaw)

;; Redefine some coleslaw functions to account for Heroku's read-only filesystem.

;; Posts live in our heroku repo under /posts.
;; Also place .coleslawrc on our repository root.
(defun load-config (config-key)
  "Load the coleslaw configuration from DIR/.coleslawrc. DIR is ~ by default."
  (declare (ignore config-key))
  (with-open-file (in (merge-pathnames ".coleslawrc" cl-user::*build-dir*))
    (setf *config* (apply #'make-instance 'blog (read in))))
  (load-plugins (plugins *config*)))

;; We need to create the symlinks .curr and .pre to account for the fact that the app
;; will be served from /app. However index.html points to 1.html under current build.
(defun update-symlink (path target)
  "Update the symlink at PATH to point to TARGET."
  (flet ((normalize (str) (enough-namestring str cl-user::*build-dir*)))
    (if (and (stringp target) (string= target "1.html"))
        (run-program "ln -sfn ~a ~a" target path)
        (run-program "ln -sfn ~a ~a" (rel-path #P"/app/" (normalize target)) path))))

;; Create our blog
(coleslaw:main nil)

(print ">>> Done setting up Coleslaw Lisp Blogware.")
