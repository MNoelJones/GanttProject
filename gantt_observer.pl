#!/bin/perl 
use warnings;
use strict;
use Exelis::MNJ::Debug;
$Exelis::MNJ::Debug::DEBUG = 0;

package GanttProject::Observer;

sub receiveEvent {
   warn "EventListener::receiveEvent not overriden to do anything useful";
}

package GanttProject::Subscription;
use Moose;

has observer_list => (is => 'ro', isa => 'HashRef[GanttProject::Observer]', default => sub { {} });

sub addObserver {
   my $self = shift;
   my $observer = shift;
   $observer->isa('GanttProject::Observer') or die "$observer is not an Observer!\n";
   $self->observer_list()->{$observer} = $observer;
}

sub delObserver {
   my $self = shift;
   my $observer = shift;
   if (exists($self->observer_list()->{$observer})) {
      delete $self->observer_list()->{$observer};
   }
}

sub notifyObservers {
   my $self = shift;
   my $event = shift;
   foreach my $observer (values %{$self->observer_list()}) {
      eval { $observer->receiveEvent($event) };
      warn $@ if ($@);
   }
}

no Moose;

package GanttProject::Task;
use Moose;
use DateTime;
use DateTime::Duration;

extends "GanttProject::Subscription", "GanttProject::Observer";

has start_time => (is => 'rw', isa => 'DateTime', trigger => sub { ::debug_funccall(\@_); my $self = shift; if (!defined($self->duration()) || !defined($self->end_time())) { $self->determineCalc("start") } });
has end_time => (is => 'rw', isa => 'DateTime', trigger => sub { ::debug_funccall(\@_); my $self = shift; if (!defined($self->duration()) || !defined($self->start_time())) { $self->determineCalc("end") }});
has duration => (is => 'rw', isa => 'DateTime::Duration', trigger => sub { ::debug_funccall(\@_); my $self = shift; if (!defined($self->start_time()) || !defined($self->end_time())) { $self->determineCalc("duration") }});
has dependents => (is => 'rw', isa => 'ArrayRef[GanttProject::Task]', default => sub { [] }, traits => ['Array'], handles => { '_addDependent' => 'push' });
has depends_on => (is => 'rw', isa => 'ArrayRef[GanttProject::Task]', default => sub { [] }, traits => ['Array'], handles => { '_addDependsOn' => 'push' });

sub determineCalc {
   ::debug_funccall(\@_);

   my $self = shift;
   my $type = shift;
  
   if ($type eq "start") {
      if (defined($self->duration())) {
         $self->calculateEnd();
      } else {
         $self->calculateDuration();
      }
   } elsif ($type eq "end") {
      if (defined($self->duration())) {
         $self->calculateStart();
      } else {
         $self->calculateDuration();
      }
   } elsif ($type eq "duration") {
      if (defined($self->end_time())) {
         $self->calculateStart();
      } else {
         $self->calculateEnd();
      }
   }
}

sub calculateStart {
   ::debug_funccall(\@_);

   my $self = shift;
   if (defined($self->end_time()) && defined($self->duration())) {
      $self->start_time($self->end_time() - $self->duration());
   }
}

sub calculateEnd {
   ::debug_funccall(\@_);

   my $self = shift;
   if (defined($self->start_time()) && defined($self->duration())) {
      $self->end_time($self->start_time() + $self->duration());
   }
}

sub calculateDuration {
   ::debug_funccall(\@_);

   my $self = shift;
   if (defined($self->start_time()) && defined($self->end_time())) {
      $self->duration($self->end_time() - $self->start_time());
   }
}

sub addDependent {
   ::debug_funccall(\@_);

   my $self = shift;
   my $task = shift;
   $self->_addDependent($task);
}

sub addDependsOn {
   ::debug_funccall(\@_);

   my $self = shift;
   my $task = shift;
   $self->_addDependsOn($task);
   $self->start_time($task->end_time());
   $task->addObserver($self);
}

sub display {
   ::debug_funccall(\@_);
   my $self = shift;
   use DateTime::Format::Duration;
   use DateTime::Format::Strptime;

   my $dtf = DateTime::Format::Strptime->new(pattern => "%H:%M");
   my $dtfd = DateTime::Format::Duration->new(pattern => "%H:%M");

   printf("%s <- %s -> %s\n", (defined($self->start_time())?$dtf->format_datetime($self->start_time()):"00:00"), (defined($self->duration())?$dtfd->format_duration($self->duration()):"00:00"), (defined($self->end_time())?$dtf->format_datetime($self->end_time()):"00:00"));
}

package main;
use DateTime;
use DateTime::Format::Duration;
use DateTime::Format::Strptime;


my $dtf = DateTime::Format::Strptime->new(pattern => "%H:%M");
my $dtfd = DateTime::Format::Duration->new(pattern => "%H:%M");
my $task1 = GanttProject::Task->new();
my $task2 = GanttProject::Task->new();
$task1->start_time($dtf->parse_datetime("12:00"));
$task1->duration($dtfd->parse_duration("0:30"));
$task2->addDependsOn($task1);
$task1->addDependent($task2);
$task2->duration($dtfd->parse_duration("0:30"));

$task1->display();
$task2->display();