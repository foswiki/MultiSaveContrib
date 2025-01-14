# Extension for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2013-2025 Michael Daum http://michaeldaumconsulting.com
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


package Foswiki::Contrib::MultiSaveContrib::Core;

=begin TML

---+ package Foswiki::Contrib::MultiSaveContrib::Core

core class for this plugin

an singleton instance is allocated on demand

=cut

use strict;
use warnings;

use Foswiki::Func ();
use Error qw(:try);

=begin TML

---++ =ClassProperty= TRACE

boolean toggle to enable debugging of this class

=cut

use constant TRACE => 0; # toggle me

=begin TML

---++ ClassMethod new(%opts) -> $core

constructor for a Core object

=cut

sub new {
  my $class = shift;

  my $this = bless({
    handler => {
      beforeSaveHandler => {},
      afterSaveHandler => {},
    },
    @_
  }, $class);

  if (defined $Foswiki::cfg{MultiSaveContrib}{Handler}) {
    foreach my $namespace (keys %{$Foswiki::cfg{MultiSaveContrib}{Handler}}) {
      foreach my $slot (keys %{$Foswiki::cfg{MultiSaveContrib}{Handler}{$namespace}}) {
	my $def = $Foswiki::cfg{MultiSaveContrib}{Handler}{$namespace}{$slot};
	$this->registerHandler($slot, $namespace, $def->{package}, $def->{function}, $def->{options});
      }
    }
  }

  return $this;
};

=begin TML

---++ ObjectMethod registerHandler($slot, $namespace, $package, $fn, $opts)

registers a callback for the given slot such as

   * beforeSaveHandler
   * afterSaveHandler

=cut

sub registerHandler {
  my ($this, $slot, $namespace, $package, $fn, $options) = @_;

  _writeDebug("registerHandler($namespace, $slot)");

  $this->{handler}{$slot}{$namespace} = {
    package => $package,
    function => $fn || $slot,
    options => $options,
  };
}

=begin TML

---++ ObjectMethod getHandler($slot, $namespace) -> $handler

This method not only returns the hash structure as registered but also
evaluates any package that the function is registered to.

see =registerHandler()=

=cut

sub getHandler {
  my ($this, $slot, $namespace) = @_;

  my $handler = $this->{handler}{$slot}{$namespace};
  return unless defined $handler;

  unless(ref($handler->{function})) {
    
    if (defined $handler->{package}) {
      _writeDebug("compiling $handler->{package} for $namespace");
      eval qq(use $handler->{package});

      # disable on error
      if ($@) {
        print STDERR "Error: $@\n";
        delete $this->{handler}{$slot}{$namespace};
        return;
      }
    }

    $handler->{function} = \&{$handler->{package}."::".$handler->{function}};
  }

  return $handler;
}

=begin TML

---++ ObjectMethod jsonRpcMultiSave()

handls the save json rpc call

=cut

sub jsonRpcMultiSave {
  my ($this, $session, $request) = @_;

  _writeDebug("called jsonRpcMultiSave()");
  my $wikiName = Foswiki::Func::getWikiName();
  my $params = $request->params();
  my $formName = $request->param("formName");
  my $forceSave = Foswiki::Func::isTrue($request->param("force"), 0);
  my $minorChange = Foswiki::Func::isTrue($request->param("minor"), 1);

  _writeDebug("saving a $formName") if defined $formName;
  _writeDebug("forceSave=$forceSave");
  #_writeDebug("params=".dump($params));

  # collect required changes
  my %changes = ();
  foreach my $key (keys %$params) {
    next if $key eq 'POSTDATA';
    _writeDebug("key=$key");
    next unless $key =~ /^multisave\{(.*)\}\{(.*)\}$/;
    my $webTopic = $1;
    my $fieldName = $2;
    my @fieldValue = $request->param($key);
    my $fieldValue = join(", ", grep {!/^$/} @fieldValue);

    _writeDebug("found changes for $webTopic, $fieldName=$fieldValue");
    $changes{$webTopic}{$fieldName} = $fieldValue;
  }

  # call beforeSaveHandlers
  foreach my $key (keys %{$this->{handler}{beforeSaveHandler}}) {
    my $handler = $this->getHandler("beforeSaveHandler", $key);
    next unless $handler; # ... when it failed to instantiate

    my $result = &{$handler->{function}}($formName, \%changes, $handler->{options});

    if (defined $result) {
      _writeDebug("form $key vetoed against any further change");
      return $result;
    }
  }

  # apply all changes
  my %result = ();

  foreach my $webTopic (keys %changes) {

    my ($web, $topic) = Foswiki::Func::normalizeWebTopicName(undef, $webTopic);

    unless (Foswiki::Func::topicExists($web, $topic)) {
      $result{error}{$webTopic} = "topic not found";
      next;
    }

    my ($meta) = Foswiki::Func::readTopic($web, $topic);

    unless (Foswiki::Func::checkAccessPermission("CHANGE", $wikiName, undef, $topic, $web, $meta)) {
      $result{error}{$webTopic} = "change access denied";
      next;
    }

    my (undef, $lockUser, $unlockTime) = Foswiki::Func::checkTopicEditLock($web, $topic, "multisave");
    my $lockWikiName = Foswiki::Func::getWikiName($lockUser);
    if ($lockWikiName ne $wikiName) {
      my $time = int($unlockTime);
      if ($time > 0) {
        $result{error}{$webTopic} = "topic is locked by $wikiName";
	next;
      }
    }

    my $mustSave = 0;
    foreach my $fieldName (keys %{$changes{$webTopic}}) {
      my $fieldValue = $changes{$webTopic}{$fieldName};
      _writeDebug("fieldName=$fieldName, fieldValue=$fieldValue");
      if ($fieldName =~ /^(Set|Local)\+(.*)$/) {
        my $type = $1;
        my $prefName = $2;
        my $oldVal = $meta->get("PREFERENCE", $prefName);
        $oldVal = $oldVal->{value} if defined $oldVal;

        _writeDebug("oldVal=".(defined $oldVal?$oldVal:'undef').", newVal=$fieldValue");
        if (defined($oldVal) && $oldVal eq $fieldValue) {
          next;
        }

        $mustSave = 1;
        $meta->putKeyed('PREFERENCE', {
          name => $prefName,
          title => $prefName,
          value => $fieldValue,
          type => $type,
        });

      } else {
        my $oldVal = $meta->get("FIELD", $fieldName);
        $oldVal = $oldVal->{value} if defined $oldVal;

        _writeDebug("oldVal=".(defined $oldVal?$oldVal:'undef').", newVal=$fieldValue");
        if (defined($oldVal) && $oldVal eq $fieldValue) {
          next;
        }

        $mustSave = 1;
        $meta->putKeyed('FIELD', {
          name => $fieldName,
          title => $fieldName,
          value => $fieldValue,
        });
      }
    }
      
    _writeDebug("mustSave=$mustSave");
    next unless $mustSave || $forceSave;

    my $error;
    my %options = ();
    $options{minor} = 1 if $minorChange;
    try {
      _writeDebug("saving changes");
      $meta->save(%options);
    } catch Error::Simple with {
      $error = shift->stringify();
    };
    if (defined $error) {
      $result{error}{$webTopic} = $error;
      _writeDebug("web=$web, topic=$topic, error=$error");
    } else {
      $result{success}{$webTopic} = 'done';
    }
  }

  # call afterSaveHandlers
  foreach my $key (keys %{$this->{handler}{afterSaveHandler}}) {
    my $handler = $this->getHandler("afterSaveHandler", $key);
    next unless $handler; # ... when it failed to instantiate

    &{$handler->{function}}($formName, \%changes, \%result, $handler->{options});
  }

  return \%result;
}

=begin TML

---++ StaticMethod _writeDebug()

=cut

sub _writeDebug {
  print STDERR "- MultiSaveContrib - $_[0]\n" if TRACE;
}

1;
