# venv.el - simple virtualenv support for Emacs.

I don't like `virtualenvwrapper`, so I took some code from [virtualenvwrapper.el](https://github.com/porterjamesj/virtualenvwrapper.el)
just to get the virtualenv activated and deactivated and made a standalone emacs package.

## Usage

``` emacs-lisp
(use-package venv
    :load-path "~/Downloads/venv.el")
```

Then use the commands `virtualenv-activate` and `virtualenv-deactivate`.
