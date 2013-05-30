# See bottom of file for license and copyright information
package Foswiki::Contrib::MultiSaveContrib::JQuery;
use strict;
use warnings;

use Foswiki::Plugins::JQueryPlugin::Plugin;
our @ISA = qw( Foswiki::Plugins::JQueryPlugin::Plugin );

sub new {
    my $class = shift;

    my $this = bless(
        $class->SUPER::new(
            name       => 'MultiSave',
            version    => '0.01',
            author     => 'Michael Daum',
            homepage   => 'http://michaeldaumconsulting.com',
            puburl => '%PUBURLPATH%/%SYSTEMWEB%/MultiSaveContrib',
            css => ['jquery.multisave.css'],
            javascript => ['jquery.multisave.js'],
            dependencies => ['form', 'blockui'],
        ),
        $class
    );

    return $this;
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2013 Michael Daum http://michaeldaumconsulting.com

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.

