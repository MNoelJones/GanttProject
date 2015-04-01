package Gantt;

use strict;

use XML::Simple;
use Data::Dumper;

BEGIN {
    use Exporter qw();

    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

    @ISA = qw( Exporter );

    $VERSION = 0.1;

    @EXPORT_OK = qw();
    @EXPORT = qw();
}

use vars @EXPORT_OK;
use vars qw();

my %marked = ();
my $Debug = 1;

sub new
{
    my $self = {};

    $self->{ Project } = undef;
    $self->{ Start } = undef;

    return bless $self;
}


# Obtains a Directed Acyclic Graph from project description
# It also finds and returns the first task in the project 
# (ATTENTION: this task must be is unique)
sub project_to_dag
{
    my $self = shift;
    
    my $start;
    
    foreach my $task ( keys %{ $self->{ Project }->{task} } ) {
		if (not (defined $self->{Project}->{task}->{$task}->{dependency})) {
		    $start = $task;
		} else {
		    
		    foreach my $t ( @{$self->{Project}->{task}->{$task}->{dependency}} ) {   
				push @{ $self->{ Project }->{task}->{$t}->{adjacent}}, $task; 
		    }
		}
    }
    $self->{Start} = $start;

    print Dumper( $self->{ Project } ) if $Debug;
}


# Topological Sort
# see "Data Structures and Algorithms", A.V.Aho, J.E.Hopcroft, J.D.Ullman, p. 221 
sub topsort 
{
    my $self = shift;

    my $task = shift;
    my $pred = shift;

    $marked{ $task } = 1;
    if ( $pred ) {
    print STDERR "PRED: $pred = " . Dumper($self->{ Project }->{task}->{$pred}) if $Debug;
		$self->{ Project }->{task}->{$task}->{from_start} = 
		    $self->{ Project }->{task}->{$pred}->{from_start} + 
			$self->{ Project }->{task}->{$pred}->{duration};
    }

    if (defined @{  $self->{ Project }->{task}->{$task}->{adjacent}} ) {

		my @sorted_tasks = sort {
		    $self->{Project}->{task}->{$b}->{duration} <=>
			$self->{Project}->{task}->{$a}->{duration}
		} @{ $self->{ Project }->{task}->{$task}->{adjacent}};

		foreach my $t ( @sorted_tasks ) {
		    if (not $marked{ $t }) {
				$self->topsort( $t, $task );
		    }
		    
		}
    }
}


sub load_project 
{
    my $self = shift;
    
    my $project_file_name = shift;

    $self->{ Project } = XMLin( $project_file_name, forcearray => 1)
	|| die "Can't load project file - $! ";

    $self->project_to_dag( $self->{ Project } );
    $self->topsort( $self->{ Start });
}


sub length
{
    my $self = shift;

    my @l = sort { $b <=> $a } map {
		$_->{from_start} + $_->{duration}
    } values %{ $self->{ Project }->{task}};

    return $l[0];
}


sub print_as_text 
{
    my $self = shift;
    my $l = $self->length();
    
    print Dumper( $self->{ Project } ) if $Debug;

    print "$self->{ Project }->{ name }\n";
    
    print ' ' x (20+7);
    for my $i ( 1..$l ) {
		print ($i % 5 ? '-' : '+'); 
    }
    print "\n\n";

    foreach my $task ( keys %{ $self->{ Project }->{task} } ) {
		printf "%-20s [%3d] ", $task, $self->{ Project }->{task}->{$task}->{duration};
		print '-' x $self->{ Project }->{task}->{$task}->{from_start} .
		    '#' x $self->{ Project }->{task}->{$task}->{duration} . "\n";	
    }

    print "Total days: $l\n\n";
}


"That's all, folks";
END {
}

=head1 AUTHOR

Stefano Rodighiero, (stefano@filibusta.crema.unimi.it)

=cut

__END__

=head1 NAME

Gantt - Simple module to produce Gantt diagram from
XML project descriptions.

=head1 EXAMPLE

    use Gantt;

    my $g = new Gantt();

    $g->load_project( './project.xml' );
    $g->print_as_text;

Here a simple XML project description in the form expected
by this module

    <project name="Program development">
    <task name="Define Specifics" duration="5">
    </task>

    <task name="Analysis" duration="10">
    <dependency>Define Specifics</dependency>
    </task>

    <task name="Search documentation" duration="3">
    <dependency>Define Specifics</dependency>
    </task>

    <task name="Write code" duration="7">
    <dependency>Analysis</dependency>
    <dependency>Search documentation</dependency>
    </task>

    <task name="Write documentation" duration="5">
    <dependency>Write code</dependency>
    </task>

    <task name="Test" duration="5">
    <dependency>Write code</dependency>
    </task>

    <task name="Release" duration="2">
    <dependency>Test</dependency>
    <dependency>Write documentation</dependency>
    </task>

    </project>

=head1 WHAT I WOULD LIKE TO DO

=item * HTML output

=item * GraphViz output

=item * Graphic output using GD

=item * Tk interface to produce XML project description

=cut 


