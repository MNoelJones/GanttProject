#!/usr/bin/perl
use strict;
use warnings;

use Project::Gantt;
use Project::Gantt::Skin;
use Time::Piece;
use Time::Seconds;


my $day_start = Time::Piece->strptime("09:00","%H:%M");
my $day_end = Time::Piece->strptime("17:30","%H:%M");

my $skin= new Project::Gantt::Skin(doTitle => 0);

my $proj = new Project::Gantt(
file            =>      'test.png',
skin            =>      $skin,
mode            =>      'hours',
description     =>      "test");

my $mnj  = $proj->addResource(name => 'MNJ',    type => 'human'    );
my $rack = $proj->addResource(name => 'Rack 1', type => 'equipment');
my $pc   = $proj->addResource(name => 'PC',     type => 'equipment');

my $tasks = [];
my $start = "2012-01-16 16:00:00";

for my $i (1..2) {
   $tasks->[$i] = $proj->addSubProject(
                     description => "Test" . $i,
                     start       => $start,
   );
   print STDERR "TASK: $i START: $start " . $tasks->[$i] . "\n";
   $start = subtasks($tasks->[$i], $start);
   print STDERR "NEXT START = $start\n";
}

sub subtasks {
   my ($proj, $start) = @_;
   print STDERR "PROJ: " . $proj . "\n";
   my $time_format = "%Y-%m-%d %H:%M:%S";
   my $prefix = $proj->{description};
   my $subtasks = {
      1 => {
         NAME     => $prefix . " - " . "Test setup", 
         DURATION => "0:30",
         RESOURCE => $mnj,
      },
      2 => {
         NAME     => $prefix . " - " . "Runtime", 
         DURATION => "2:00",
         RESOURCE => $rack,
      },
      3 => {
         NAME     => $prefix . " - " . "Cooldown", 
         DURATION => "0:30",
         RESOURCE => $rack,
      },
      4 => {
         NAME     => $prefix . " - " . "Results collection", 
         DURATION => "0:20",
         RESOURCE => $mnj,
      },
      5 => {
         NAME     => $prefix . " - " . "Results assessment", 
         DURATION => "2:00",
         RESOURCE => $mnj,
      },
   };
   my $subtask_start = Time::Piece->strptime($start, $time_format);
   my $subtask_end = undef;

   foreach my $taskid (sort {$a<=>$b} keys %$subtasks) {
      my $taskname = $subtasks->{$taskid}{NAME};
      print STDERR ref($start) . "\n";
      print STDERR "SUBTASK: $taskid, NAME: $taskname, START: $start, DURATION: $subtasks->{$taskid}{DURATION}\n";
      my $duration = Time::Piece->strptime($subtasks->{$taskid}{DURATION}, "%H:%M");
      print STDERR "Duration: " . $duration->strftime("%H:%M") . "\n";

      $subtask_end = $subtask_start+($duration->epoch);
      if ($subtasks->{$taskid}{RESOURCE}{type} eq "human" && 
          ($subtask_end->hour > $day_end->hour || 
            ($subtask_end->hour == $day_end->hour &&
             $subtask_end->min > $day_end->min))) {
         my $base_start = $subtask_start+ONE_DAY;
         print STDERR "BASE: " . $base_start . "\n";
         my $new_time = sprintf("%4d-%02d-%02d %02d:%02d:%02d",
            $base_start->year,
            $base_start->mon,
            $base_start->mday,
            $day_start->hour,
            $day_start->min,0);
         print STDERR "BASE: " . $new_time . "\n";
         $subtask_start = Time::Piece->strptime($new_time,$time_format);
         $subtask_end = $subtask_start+($duration->epoch);
      }
      print STDERR "subtask start: $subtask_start\n";
      print STDERR "subtask end  : $subtask_end\n";
      print STDERR "Adding subtask.\n";
      print STDERR "\tstart: " . $subtask_start->strftime($time_format) . "\n";
      print STDERR "\tend  : " . $subtask_end->strftime($time_format) . "\n";
      $proj->addTask(
      description     =>      $taskname,
      resource        =>      $subtasks->{$taskid}{RESOURCE},
      start           =>      $subtask_start->strftime($time_format),
      end             =>      $subtask_end->strftime($time_format),
      );
      print STDERR "...done\n";
      $subtask_start = $subtask_end;
   }
   return $subtask_end->strftime($time_format);
}
$proj->_display();
$proj->display();