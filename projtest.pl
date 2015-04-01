#!/usr/bin/perl
use strict;
use warnings;
use Moose::Util::TypeConstraints;
use Time::Piece;

class_type 'TimePiece' => { class => 'Time::Piece' };

coerce 'TimePiece' 
   => from 'Str'
      => via { my $time = shift; Time::Piece->strptime($time, "%Y-%m-%d %T")};
      
package GanttProject::ResourceFactory;
use Moose;

has resource_list => (
   is => 'ro', 
   isa => 'HashRef[GanttProject::Resource]', 
   traits => ['Hash'], 
   handles => { 
      assign_resource => 'set', 
      get_resource => 'get',
      has_resource => 'exists',
   }
);

sub add_resource {
   my $self = shift;
   my $resource_id = shift;
   if (!$self->has_resource($resource_id)) {
      $self->assign_resource($resource_id => GanttProject::Resource->new(id => $resource_id));
   } 
   return $self->get_resource($resource_id);
}

package GanttProject::Resource;
use Moose;

has id => (is => 'ro', isa => 'Int');

no Moose;


package GanttProject::TaskFactory;
use Moose;

has task_list => (
   is => 'ro', 
   isa => 'HashRef[GanttProject::Task]', 
   traits => ['Hash'],
   handles => { 
      add_task => 'set', 
      get_task => 'get',
      has_task => 'exists',
   }
);

sub task {
   my $self = shift;
   my $h = {@_};
   my ($id, $graph) = ($h->{id}, $h->{graph});
   my $task;
   if ($self->has_task($id)) {
      print STDERR "Found existing task for $id\n";
      $task = $self->get_task($id);
      # Do I want to ensure this? We lose the existing graph reference if it already has one...
      #$task->graph($graph);
   } else {
      print STDERR "Generating new task for $id\n";
      $task = GanttProject::Task->new(id => $id, graph => $graph);
      $self->add_task($id, $task);
   }
}

no Moose;

package GanttProject::Task;
use Moose;

has id => (is => 'ro', isa => 'Str');
has description => (is => 'rw', isa => 'Str');
has start => (is => 'rw', isa => 'TimePiece', coerce => 1);
#has start => (is => 'ro', isa => 'DateTime');
has duration => (is => 'rw', isa => 'Maybe[DateTime::Duration]');
has resource => (is => 'rw', isa => 'ArrayRef[GanttProject::Resource]', default => sub { [] }, traits => [ 'Array' ], handles => {add_resource => "push"});
has subtasks => (is => 'rw', isa => 'ArrayRef[GanttProject::Task]', default => sub { [] }, traits => [ 'Array' ], handles => {add_subtask => "push"});
has depends_on => (is => 'rw', isa => 'ArrayRef[GanttProject::Task]', default => sub { [] }, traits => [ 'Array' ], handles => {add_depends => "push"});
has dependents => (is => 'rw', isa => 'ArrayRef[GanttProject::Task]', default => sub { [] }, traits => [ 'Array' ], handles => {add_dependent => "push"});
has weight => (is => 'rw', isa => 'Num');
has dupe => (is => 'rw', isa => 'Bool');
has graph => (is => 'ro', isa => 'Graph');
has twig => (is => 'ro', isa => 'Maybe[XML::Twig]');
has resource_factory => (is => 'ro', isa => 'GanttProject::ResourceFactory', default => sub { GanttProject::ResourceFactory->new(); });

sub init_from_graph {
   my $self = shift;
   my $g = $self->graph();
   
   foreach my $attr (qw(description start duration resource weight dupe)) {
      if (defined($g->get_vertex_attribute($self->id(), $attr))) {
         print STDERR "ATTR = $attr\n";
         print STDERR "ID = " . $self->id() . "\n";
         print STDERR "GVA = " . $g->get_vertex_attribute($self->id(), $attr) . "\n";
         if ($attr eq "resource") {
            $self->add_resource($self->resource_factory()->add_resource($g->get_vertex_attribute($self->id(), $attr)));
         } else {
            $self->$attr($g->get_vertex_attribute($self->id(), $attr));
         }
      }
   }
   
   foreach my $pair ([qw(subtasks add_subtask)], [qw(depends_on add_depends)], [qw(dependents add_dependent)]) {
      my ($attr, $adder) = @$pair;
      my $arr = $g->get_vertex_attribute($self->id(), $attr);
      if (defined($arr)) {
         foreach my $el (@$arr) {
            $self->$adder(GanttProject::Task->new(id => $el));
         }
      }
      
   }
}

sub set_graph_from_this {
   my $self = shift;
   my $g = $self->graph();

}

sub init_from_twig {
   my $self = shift;
   my $t = $self->twig();

}

sub set_twig_from_this {
   my $self = shift;
   my $t = $self->twig();

}

no Moose;

package main;

use Project::Gantt;
use Project::Gantt::Skin;
use Time::Piece;
use Time::Seconds;
use XML::Twig;

use Data::Dumper;
use Graph;

# "Globals"
my $g;
my $proj;
my $tasks; #DEAD
my $resources;

# Find leaf nodes

sub parse_project {
   my ($t, $o) = @_;
   my $name = $o->att("name");
   my $id = $o->att("id");
   $g->set_graph_attribute("name", $name);
   $g->set_graph_attribute("id", $id);
   
   #$proj->{id} = $id;
}

sub parse_resource {
   my ($t, $o) = @_;
   #$o->print; print "\n";
   #print "ID = " . $o->att("id") . "\n";
   #print "NAME = " . $o->first_child("name")->text . "\n";
   #print "TYPE = " . $o->first_child("type")->text . "\n";
   my $id   = $o->att("id");
   my $name = $o->first_child("name")->text;
   my $type = $o->first_child("type")->text;
   
   #print STDERR $resource_ref . "\n";
   #my $res_item = $data->{project}{resources}{$resource_ref};
   #print Dumper($res_item);
   #my $resource = $proj->addResource(name => $name, type => $type);
   #$resources->{$id} = $resource;
   $t->purge;
}

sub parse_task {
   my ($t, $o) = @_;
   my $id = $o->att("id");
   #if (exists($tasks->{$id}{TASK}))
   if (!$g->has_vertex($id)) {
      $g->add_vertex($id);
   }
   my $h = {};
   my $dup = undef;
   if ($dup = $o->att("dup")) {
      $h->{"dupe"} = $dup;
   }
   for my $item (qw(description start duration resource)) {
      if (defined($dup)) {
         if (defined($g->get_vertex_attribute($dup, $item))) {
            $h->{$item} = $g->get_vertex_attribute($dup, $item);      
         }
      }
      if ($o->first_child($item)) {
         my $text = $o->first_child($item)->text;
         if ($item eq "duration") {
            # convert from string to Time::Piece object
            $h->{$item}  = Time::Piece->strptime($text, "%H:%M");
         } else {
            $h->{$item} = $text
         }
         #$tasks->{$id}{$item} = $h->{$item};
         $g->set_vertex_attribute($id, $item, $h->{$item});
      }
   }

   if (defined($dup)) {
      my $subtasklist = $g->get_vertex_attribute($dup, "subtasks");
      if (defined($subtasklist)) {
         my $subtasks = $g->get_vertex_attribute($id, "subtasks");
         foreach my $subtask (@$subtasklist) {
            my $newsubtaskid = construct_id($id, $subtask);
            #print STDERR "Duplicate $subtask for $id as $newsubtaskid\n";
            $g->add_vertex($newsubtaskid);
            $g->set_vertex_attributes($newsubtaskid, $g->get_vertex_attributes($subtask));
            #print STDERR "set_vertex_attributes($newsubtaskid, " . Dumper($g->get_vertex_attributes($subtask));
            #my @olddependents = $g->predecessors($subtask);
            my $olddependents = $g->get_vertex_attribute($subtask, "depends_on");
            print STDERR "\$olddependents for $subtask: " . Dumper($olddependents);
            foreach my $olddep (@$olddependents) {
               #print STDERR "OLDDEP: " . Dumper($olddep);
               print STDERR "Processing edge from $olddep to $subtask\n";
               my $newdependid;
               if (0) {
                  my $newdependid = $olddep;
                  if ($newdependid == $dup) { 
                     $newdependid = $id;
                  } elsif (grep {$newdependid} @$subtasklist) {  # Check if depend is a member of subtasklist
                     $newdependid = "$id".$newdependid;
                  }
               } else {
                  $newdependid = construct_depend_id($id, $dup, $olddep, $subtasklist);
               }
               my $dependents = $g->get_vertex_attribute($newdependid, "dependents");
               push(@$dependents, $newsubtaskid);
               $g->set_vertex_attribute($newdependid, "depends", $dependents);
               #print STDERR "add_edge($newdependid, $newsubtaskid)\n";
               $g->set_vertex_weight($newsubtaskid, $g->get_vertex_weight($dup));
               
               push(@$subtasks, $newsubtaskid);
               #$g->add_edge($id, $newsubtaskid);
            }
            #print STDERR "Duplicated $subtask\n";
         }
         $g->set_vertex_attribute($id, "subtasks", $subtasks);
      }
   }
   #print STDERR "Recording task $id\n";       
   #$tasks->{$id}{TASK} = $proj->addSubProject(
   #                           description => $h->{description},
   #                           start       => $h->{start},
   #                      );
   if (0) {
      #print STDERR "$id START: $h->{start}\n";
      if (exists($tasks->{$id}{SUBTASKS})) {
         foreach my $subtask_id (keys %{$tasks->{$id}{SUBTASKS}}) {
            foreach my $subtask_h (@{$tasks->{$id}{SUBTASKS}{$subtask_id}}) {
               $tasks->{$id}{TASK}->addTask(
               description     => $subtask_h->{description},
               resource        => $subtask_h->{resource},
               start           => $subtask_h->{start},
               end             => $subtask_h->{end}
               );
            }
         }
      }
   }
   
   $t->purge;
}

sub construct_depend_id {
   my ($id, $dup, $olddep, $subtasklist) = @_;
   my $newdependid = $olddep;
   if ($newdependid == $dup) {
      $newdependid = $id;
   } 
   # Check if depend is a member of subtasklist
   elsif (grep {$newdependid} @$subtasklist) {
      $newdependid = construct_id($id, $newdependid);
   }
   return $newdependid;
}

sub construct_id {
   my ($id1, $id2) = @_;
   return "$id1$id2";
}

sub parse_subtask {
   my ($t, $o) = @_;
   my $id = $o->att("id");
   my $pid = $o->parent->parent->att('id');
   my $subtasks = $g->get_vertex_attribute($pid, "subtasks");
   push(@$subtasks, $id);
   $g->set_vertex_attribute($pid, "subtasks", $subtasks);
   #$g->add_edge($pid, $id);
   
   my $name = $o->first_child("name")->text;
   $g->set_vertex_attribute($id, "name", $name);
   my $dur = Time::Piece->strptime($o->first_child("duration")->text, "%H:%M");
   $g->set_vertex_weight($id, $dur->epoch);
   
   my $res_id = $o->first_child("resource")->att("ref");
   $g->set_vertex_attribute($id, "resource", $res_id);
   my $dep = undef;
   my $start_time = 0;
   my $end_time = 0;
   if ($o->first_child("depend")) {
      $dep = $o->first_child("depend")->text;
      #print STDERR "SUBTASK: \$g->add_edge($dep, $id)\n";
      #$g->add_edge($dep, $id);
      my $dependents = $g->get_vertex_attribute($id, "dependents");
      my $depends_on = $g->get_vertex_attribute($dep, "depends_on");
      push(@$dependents, $dep);
      push(@$depends_on, $id);
      $g->set_vertex_attribute($id, "dependents", $dependents);
      $g->set_vertex_attribute($dep, "depends_on", $depends_on);
      if (0) { 
         if (defined($dep) && exists($tasks->{$dep}{end})) {
            if ($tasks->{$dep}{end} > $start_time) {
               #print STDERR "\tSTART: $start_time";
               $start_time = $tasks->{$dep}{end};
            }
            #push(@{$tasks->{$id}{DEPENDSON}}, $dep);
            #push(@{$tasks->{$dep}{DEPENDENTS}}, $id);
         }
      }
   }
   if (0) {
      #push(@{$tasks->{$pid}{SUBTASKS}{$id}}, 
      my %temp = (   description     =>      $name,
      resource        =>      $resources->{$res_id},
      start           =>      $start_time,
      end             =>      $end_time
      );
      while (my ($key,$val) = each(%temp)) {
         $tasks->{$id}{$key} = $val; 
      }
      push(@{$tasks->{$pid}{SUBTASKS}}, $id);
   }
}

# Remove all edges
sub remove_all_edges {
   my $g = shift;
   my @vertices = $g->vertices();
   foreach my $vertex (@vertices) { 
      my @s = $g->successors($vertex);
      foreach my $n (@s) { 
         $g->delete_edge($vertex, $n);
      } 
   }
}


# Add edges
sub add_attrib_edges {
   my ($g, $attrib) = @_;
   my @vertices = $g->vertices();
   foreach my $vertex (@vertices) {
      my $attrib_items = $g->get_vertex_attribute($vertex, $attrib);
      if (defined($attrib_items)) {
         foreach my $item (@$attrib_items) {
            $g->add_edge($vertex, $item);
         }
      }
   }
}

# Critical path analysis functions

sub find_leaves {
   my $g = shift;
   my @v = $g->vertices();
   my $leaves = [];

   foreach my $v (@v) {
      if (!$g->has_vertex_attribute($v,"children") && $g->is_sink_vertex($v)) {
         push(@$leaves, $v);
      }
   }
   return $leaves;
}

sub calc_crit_time {
   my ($g, $node) = @_;
   my $max = 0;
   my $ct = 0;
   
   if (!$g->is_sink_vertex($node)) {
      $ct += ($g->get_vertex_weight($node) || 0);
      foreach my $suc ($g->successors($node)) {
         #my $wt = $g->get_vertex_weight($suc);
         # 0 + <blah> = 0 if <blah> is undef (shortcuts test for !defined(<blah>))
         my $wt = ($g->get_vertex_attribute($suc, "Critical Time") || 0);
         $max = $wt if ($wt>$max);
      }
      $ct+=$max;
   }
   #print STDERR "CT($node) = $ct\n";
   return $ct;
}

#sub add_leaf_nodes {
#   my $task_id = shift;
#   my @leaves = ();
#   #print STDERR "Adding leaf nodes for task $task_id\n";
#   #if (exists($tasks->{$task_id}{SUBTASKS})) {
#   #   foreach my $subtask_id (@{$tasks->{$task_id}{SUBTASKS}}) {
#   #      push(@leaves, add_leaf_nodes($subtask_id));
#   #   }
#   #   return @leaves;
#   #} else {
#      return $task_id;
#   #}
#}

sub set_crit_time {
   my ($g, $node, $ct) = @_;
   if (!defined($ct)) { $ct = 0; }
   $g->set_vertex_attribute($node, "Critical Time", $ct);

   return $ct;
}

sub set_leaf_crit_time {
   my ($g, $leaves) = @_;
   foreach my $leaf (@$leaves) {
      my $crit_time = 0;
      $g->set_vertex_attribute($leaf, "Critical Time", $crit_time);
      print STDERR "\$g->set_vertex_attribute($leaf, \"Critical Time\", $crit_time)\n";
   }
}

sub set_non_leaf_crit_times {
   my $g = shift;
   foreach my $node (reverse($g->topological_sort)) {
      my $crit_time = calc_crit_time($g, $node);
      $g->set_vertex_attribute($node, "Critical Time", $crit_time);
      print STDERR "\$g->set_vertex_attribute($node, \"Critical Time\", $crit_time)\n";
   }
}

sub set_crit_times {
   my $g = shift;
   my $leaves = find_leaves($g);
   set_leaf_crit_time($g, $leaves);
   set_non_leaf_crit_times($g);
}

sub print_critical_path {
   my $g = shift;
   foreach my $v ($g->topological_sort) {
      my $vw = $g->get_vertex_weight($v);
      my $vct = $g->get_vertex_attribute($v, "Critical Time");
      print $v . " (" . (defined($vw)?$vw:"-") . ") " .
      "[" . (defined($vct)?$vct:"-") . "]\n";
   }
}

my $xml = XML::Twig->new(
twig_handlers => { 
   #'project' => \&parse_project,
   'project/resources/resource' => \&parse_resource,
   'project/tasks/task' => \&parse_task,
   'project/tasks/task/subtasks/task' => \&parse_subtask,
}
);


####### Main ########

my $fn = $ARGV[0] || "MNJ_projtest.xml";
$resources = {};
#my $tasks = {};
my $skin= new Project::Gantt::Skin(doTitle => 0);

$proj = new Project::Gantt(
         file            =>      'test.png',
         skin            =>      $skin,
         mode            =>      'hours',
         description     =>      "test"
);


$g = Graph->new();
my $data = $xml->parsefile($fn);
$data->purge;

#my @leaves = add_leaf_nodes(1);

#print Dumper({RES => $resources, TASKS => $tasks});

#print "Leaves: " . join(", ", @leaves) . "\n";

set_crit_times($g);
#print "$g\n";
#print_critical_path($g);

if (0) {
   my $res_nodes = {};
   my @reskeys = keys %$resources;
   foreach my $res (@reskeys) {
      $res_nodes->{$res} = Graph->new();
   }

   foreach my $v ($g->topological_sort) {
      my $v_res = $g->get_vertex_attribute($v, "resource");
      if (defined($v_res)) { 
         #print STDERR Dumper($g->vertex($v));
         $res_nodes->{$v_res}->add_vertex($g->vertex($v));
         $res_nodes->{$v_res}->set_vertex_attributes($g->vertex($v), $g->get_vertex_attributes($v));
         #print STDERR "$v_res => " . $res_nodes->{$v_res} . "\n";
      }
   }

#print STDERR Dumper($res_nodes);

   foreach my $res (@reskeys) {
      #print $res . "\t" . join(" ", $res_nodes->{$res}) . "\n";
      print_critical_path($res_nodes->{$res});
   }
}

foreach my $attrib ("subtasks", "dependents", "depends_on") {
   remove_all_edges($g);
   #print "$g\n";
   add_attrib_edges($g, $attrib);
   #print "$attrib : $g\n";
}

my $taskfactory = GanttProject::TaskFactory->new();
my $gtasks = [];
foreach my $node ($g->vertices()) {
   #my $task = GanttProject::Task->new(id => $node, graph => $g);
   my $task = $taskfactory->task(id => $node, graph => $g);
   $task->init_from_graph();
   push(@$gtasks, $task);
}

$Data::Dumper::Maxdepth = 4;
print STDERR Dumper($gtasks);

print "$g";