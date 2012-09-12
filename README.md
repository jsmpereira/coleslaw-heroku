# Coleslaw on Heroku

Deploy your Common Lisp blog using [Coleslaw](https://github.com/redline6561/coleslaw) on the Heroku platform.

Makes use of my [heroku-buildpack-cl](https://github.com/jsmpereira/heroku-buildpack-cl) fork.

Because of Heroku's build system and read-only filesystem, some tweaks were needed.

## Quick instructions

1. Setup Heroku app
  <pre>
  heroku create -s cedar --buildpack http://github.com/jsmpereira/heroku-buildpack-cl.git
  heroku labs:enable user-env-compile -a myapp
  heroku config:add CL_IMPL=sbcl
  heroku config:add CL_WEBSERVER=hunchentoot
  heroku config:add LANG=en_US.UTF-8
  </pre>

2. Rename example.coleslawrc to .coleslawrc and edit.

3. Create your content under /posts in .post files.

4. ```git push heroku master```
