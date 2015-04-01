package GanttTimeline::TaskItem;
use Moose;
use GanttTimeline::Dependency;

has start => (is => 'ro', isa => "DateTime");
has end => (is => 'ro', isa => "DateTime");
has dependencies => (
   is => 'ro', 
   isa => "ArrayRef[GanttTimeline::Dependency]", 
   traits => ['Array'],
   default => sub { [] },
   handles => {
      push_dep => 'push',
      pop_dep => 'get'
   },
);

sub addDependency {
   my $self = shift;
   # TaskItem& item, DependencyType type
   my ($item, $type) = @_;
   if (defined($type)) {
      $self->dependencies->push_dep(GanttTimeline::Dependency->new(task_item => $item, type => $type));
   } else {
      $self->dependencies->push_dep(GanttTimeline::Dependency->new(task_item => $item));
   }
}

sub delDependency {
   my $self = shift;
   # Dependency d
   my $d = shift;
}

sub calculateEnd {
   my $self = shift;
}

sub calculateStart {
   my $self = shift;
}

sub calculateDuration {
   my $self = shift;
}



no Moose;
__PACKAGE__->meta->make_immutable;
1;
