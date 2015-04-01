package GanttTimeline::TimelineEntry;
use Moose;

has start => (is => 'ro', isa => "DateTime");
has end => (is => 'ro', isa => "DateTime");
has predecessors => (is => 'ro', isa => "ArrayRef[GanttTimeline::TimelineEntry]");
has successors => (is => 'ro', isa => "ArrayRef[GanttTimeline::TimelineEntry]");
has task_item => (is => 'ro', isa => "GanttTimeline::TaskItem");

#Public methods
sub earliestStart {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub earliestEnd {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub latestStart {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub latestEnd {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isStartLaterThanStart {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isStartLaterThanEnd {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isEndLaterThanStart {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isEndLaterThanEnd {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isStartEarlierThanStart {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isStartEarlierThanEnd {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isEndEarlierThanStart {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isEndEarlierThanEnd {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isStartEqualStart {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isStartEqualEnd {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isEndEqualStart {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub isEndEqualEnd {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub hasOverlap {
   my $self = shift;
# TimelineEntry& b
   my $b = shift;
}

sub Overlap {
   my $self = shift;
# TimelineEntry& b
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;