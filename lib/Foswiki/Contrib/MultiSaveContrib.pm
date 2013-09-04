# Extension for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2013 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Contrib::MultiSaveContrib;

use strict;
use warnings;

use Foswiki::Plugins();
use Foswiki::Contrib::JsonRpcContrib ();

our $VERSION = '1.01';
our $RELEASE = '1.01';
our $NO_PREFS_IN_TOPIC = 1;
our $SHORTDESCRIPTION = 'Json-RPC interface to save multiple changes in one transaction';
our $core;

sub jsonRpcMultiSave {
  return getCore()->jsonRpcMultiSave(@_);
}

sub registerHandler {
  return getCore()->registerHandler(@_);
}

sub getCore {
  unless ($core) {
    require Foswiki::Contrib::MultiSaveContrib::Core;
    $core = new Foswiki::Contrib::MultiSaveContrib::Core();
  }
  return $core;
}

1;

