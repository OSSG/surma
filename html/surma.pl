#!/usr/bin/perl -w
# surma - simple Samba UseR MAnager
# Core script of the web interface
# Copyright (C) 2008 Fedor A. Fetisov <faf@oits.ru>, OITS Co. Ltd.
# All Rights Reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use CGI;
use Crypt::SmbHash qw(ntlmgen);

use constant UPDATED => 'Ok';

my $get_tmpsmbpw = 'sudo /usr/local/bin/get_tmpsmbpw';
my $put_tmpsmbpw = 'sudo /usr/local/bin/put_tmpsmbpw';

my $language = {};

# Get language constants
if (-r './language') {
    $language = do('./language');
    if ($@) {
	warn "surma warning: Unable to obtain language constants. Language file corrupted?\n";
    }
}

# Get template
die "surma error: Template missed!\n" if !((-r './template.html') && open(IN, '<./template.html'));
my @template = <IN>;
close(IN);

# Prepare for action
my $variables = {'message' => ''};
my $cgi = new CGI;

# Try to get user data
my $data = {};
my $flag = 0;
foreach ('username', 'oldpw', 'newpw', 'newpw2') {
    $data->{$_} = $cgi->param($_);
    $flag++ if defined $data->{$_} && ($data->{$_} ne '');
}

if ($flag) {
# Data was supplied...
    if ($flag == 4) {
# ...and all fields were filled
	if ($data->{'newpw'} eq $data->{'newpw2'}) {
# New password confirmed, try to get name of the temporary file with actual hashes
	    my $filename = `$get_tmpsmbpw`;
	    chomp($filename) if (defined $filename);
# Check filename and try to open the file for read and write
	    if ((defined $filename) && ($filename ne '') && open(PWD, "+<$filename")) {
		my $found = 0;
		my $changed = 0;
# Search for the string related to given username
		while (my $string = <PWD>) {
		    if ($string =~ /^$data->{'username'}:/) {
# String found, calculating hashes using old password value
			my ($old_lm, $old_nt) = ntlmgen($data->{'oldpw'});
# Compare calculated hashes with the existing ones
			if ($string =~ /^($data->{'username'}:[0-9]+:)$old_lm:$old_nt(:.*)$/) {
# Hashes matched - old password is correct
# Calculate hashes using new password value
			    my ($new_lm, $new_nt) = ntlmgen($data->{'newpw'});
# Move filehandler pointer to the begining of the string...
			    seek(PWD, tell(PWD) - length($string), 0);
# ... and rewrite it
			    $string = $1 . $new_lm . ':' . $new_nt . $2;
			    print PWD $string;
			    $changed = 1;
			}
			else {
			    $variables->{'message'} = '<div class="error">%%Error: wrong old password%%!</div>';
			}
			$found = 1;
			last;
		    }
		}
		close(PWD);
# Try to save new password
        	my $result = `$put_tmpsmbpw`;
		chomp($result) if (defined $result);

		if ($found && $changed) {
# Password was successfully changed
		    if ((defined $result) && ($result eq UPDATED)) {
			$variables->{'message'} = '<div class="message">%%Password changed%%.</div>';
		    }
		    else {
			$variables->{'message'} = '<div class="error">%%Error: unable to save password file%%!</div>';
		    }
		}
		elsif (!$found) {
		    $variables->{'message'} = '<div class="error">%%Error: user not found%%!</div>';
		}
	    }
	    else {
		$variables->{'message'} = '<div class="error">%%Error: unable to get password file%%!</div>';
	    }
	}
	else {
	    $variables->{'message'} = '<div class="error">%%Error: password mismatch%%!</div>';
	}
    }
    else {
	$variables->{'message'} = '<div class="error">%%Error: you have to fill all fields%%!</div>';
    }
}

# Send document to client
print $cgi->header('text/html; charset=UTF-8');
foreach (@template) {
    s/\$\$(.+?)\$\$/$variables->{$1} || ''/eg;
    s/\%\%(.+?)\%\%/$language->{$1} || $1/eg;
    print;
}
