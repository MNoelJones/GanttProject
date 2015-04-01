package GanttTimeline::Dependency;
use Moose;

has task_item => (is => 'ro', isa => "GanttTimeline::TaskItem");
has type => (is => 'ro', isa => "GanttTimeline::DependencyType");


no Moose;
__PACKAGE__->meta->make_immutable;
1;