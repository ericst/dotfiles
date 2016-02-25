# ericst's dot files
Eric Seuret <eric@ericst.ch>

These are my config files to configure a machine the way I like it.

Feel free to take inspirations ;-)

## Installation
For simplicity, everything is managed by [RCM](https://github.com/thoughtbot/rcm).
So just follow their guide to understand.

### Spacemacs
[Spacemacs](http://spacemacs.org/) will assume that you have it extracted in ~/.emacs.d so don't forget to install it:

```bash
$ git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
```
## Units

### git

Just a simple gitconfig.

### spacemacs

The configuration is made in the spacemacs.org that you then tangle. See the file for more information.

### zsh

For the moment, just a copy of the grml zsh config. Should change to something homegrown though.

### mail

I am trying to swicht to mutt, offlineimap and msmtp.
The overall configuration is heavily inspired by [pbrisbin](https://github.com/pbrisbin/dotfiles/tree/master/tag-mail-recipient).
Please note that all the password will be expected in an ~/.netrc file. Here is the template. 

```
machine imap.gmail.com
        login eric.seuret@gmail.com
        password secret

machine smtp.gmail.com
        login eric.seuret@gmail.com
        password secret

machine mail.ericst.ch
        login eric@ericst.ch
        password secret

machine mail.cyon.ch
        login eric.seuret@cylenk.com
        password secret
```
### gpg

Heavily inspired by: [Riseup's OpenPGP Best Practices](https://help.riseup.net/en/security/message-security/openpgp/best-practices)

### tmux

Just setting C-a as send-prefix for nested sessions.
