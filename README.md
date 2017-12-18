# surma
simple **S**amba **U**se**R** **MA**nager

## Quick install guide for ALT Linux

```
# apt-get install perl-CGI perl-Crypt-SmbHash lighttpd sudo
# chkconfig lighttpd --add
# chkconfig lighttpd on

$ tar xvfz surma.tar.gz
$ cd surma
# mkdir /var/www
# mv html /var/www
# mv bin/* /usr/local/bin
# chmod 750 /usr/local/bin/get_tmpsmbpw /usr/local/bin/put_tmpsmbpw
# chown :lighttpd  /usr/local/bin/get_tmpsmbpw /usr/local/bin/put_tmpsmbpw

# control sudo public
# echo "lighttpd  ALL=(ALL) NOPASSWD:/usr/local/bin/get_tmpsmbpw" >> /etc/sudoers
# echo "lighttpd  ALL=(ALL) NOPASSWD:/usr/local/bin/put_tmpsmbpw" >> /etc/sudoers

# subst '/"mod_cgi",$/ s/^#//' /etc/lighttpd/lighttpd.conf

# cat << __END__ >>/etc/lighttpd/lighttpd.conf
## surma addon
index-file.names += ("surma.pl")
cgi.assign        = ( ".pl"  => "/usr/bin/perl")
__END__
```
