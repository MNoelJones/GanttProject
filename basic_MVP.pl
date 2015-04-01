#!/bin/perl
use warnings;
use strict;

package Model;
use Moose;
no Moose;

package View;
use Moose;
has presenter => (is => 'ro', isa => 'Presenter');
no Moose;

package Presenter;
use Moose;
has model => (is => 'ro', isa => 'Model');
no Moose;

package View::Test;
use Moose;
extends 'View';
use Tk;
has entry => (is => 'rw', isa => 'Tk::Entry');
has string => (is => 'rw', isa => 'Str');
sub BUILD {
	my $self = shift;

	my $mw = MainWindow->new();
	my $f = $mw->Frame();
	$self->entry($f->Entry(-textvariable => $self->string))->pack();
	$f->pack;
	MainLoop;
}

package Model::Test;
use Moose;
extends 'Model';
no Moose;

package Presenter::Test;
use Moose;
extends 'Presenter';
no Moose;

package main;
my $m = Model::Test->new(string => "test");
my $p = Presenter::Test->new(model => $m);
my $t = View::Test->new(presenter => $p);

__END__
@startuml basic_MVP.png

class Observer
class Observable {
	register()
}

class Model extends Observable
class View {
	Presenter presenter
}
View --|> Observable
View --|> Observer

class Presenter extends Observer {
	Model model
}

"View::Test" --> "Presenter::Test" : presenter
"Presenter::Test" --> "Model::Test" : model

set namespaceSeparator ::

class View::Test {
	Presenter::Test presenter
	Tk::Entry string_e

	Str presentString()
	void storeString()
}

class Presenter::Test {
	View::Test view
	Str getModelString()
}
class Model::Test {
	Str test_string

	Str getString()
}
@enduml