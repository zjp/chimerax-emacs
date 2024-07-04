# chimerax.el -- The ChimeraX command line in Emacs

`chimerax.el`

This package provides a REPL that uses the ChimeraX REST server to allow you to send commands to ChimeraX from Emacs. Mostly a hatchet job on `dap-ui-repl` code.

## Installation

### Manual

Clone the repository to a directory of your choice.
``` shell
git clone https://github.com/zjp/chimerax-emacs ~/.emacs.d/chimerax-emacs
```

Then in your `init.el`, load the project require it.

``` emacs-lisp
(add-to-list 'load-path (expand-file-name "~/.emacs.d/chimerax-emacs"))
(require 'chimerax)
```

### MELPA
Coming soon

## Setup

In ChimeraX, open the Preferences panel and click on the startup tab. Configure ChimeraX to start its REST server at the same port every time and to return results in JSON.

`remotecontrol rest start port 3000 json true`

In Emacs, set `chimerax-rest-url` to the URL this command returns. For example, if the output is

``` shell
REST server started on host 127.0.0.1 port 3000
Visit http://127.0.0.1:3000/cmdline.html for CLI interface
```

then in your `init.el`:


``` emacs-lisp
(setq chimerax-rest-url "http://127.0.0.1:3000")
```

## Usage

`M-x chimerax-repl` will open a buffer at the bottom of the Emacs window that takes commands and forwards them to ChimeraX. The results of ChimeraX commands will be printed as in the example below:

``` text
>> view matrix
log notes:
view matrix camera 0.33375,-0.040265,0.9418,383.57,0.59703,0.7822,-0.17813,-48.384,-0.7295,0.62173,0.2851,176.57
view matrix models #1,1,0,0,0,0,1,0,0,0,0,1,0,#1.1,1,0,0,0,0,1,0,0,0,0,1,0
log warnings:
log errors:
log bugs:
```

## TODO

- [ ] Errors
- [ ] JSON results
- [ ] Python results
- [ ] `cxcmd` links
