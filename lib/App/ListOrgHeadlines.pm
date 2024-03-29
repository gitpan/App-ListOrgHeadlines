package App::ListOrgHeadlines;
BEGIN {
  $App::ListOrgHeadlines::VERSION = '0.01';
}
#ABSTRACT: An application to list headlines in Org files

use 5.010;
use strict;
use warnings;
use Log::Any qw($log);

use DateTime;
use Org::Parser;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(list_org_headlines);

our %SPEC;

my $today;
my $yest;

sub _process_hl {
    my ($file, $hl, $args, $res) = @_;

    return if $args->{from_level} && $hl->level < $args->{from_level};
    return if $args->{to_level}   && $hl->level > $args->{to_level};
    if (defined $args->{todo}) {
        return if $args->{todo} xor $hl->is_todo;
    }
    if (defined $args->{done}) {
        return if $args->{done} xor $hl->is_done;
    }
    if (defined $args->{state}) {
        return unless $hl->is_todo &&
            $hl->todo_state eq $args->{state};
    }
    if ($args->{has_tags} || $args->{lack_tags}) {
        my $tags = $hl->get_tags;
        if ($args->{has_tags}) {
            for (@{ $args->{has_tags} }) {
                return unless $_ ~~ @$tags;
            }
        }
        if ($args->{lack_tags}) {
            for (@{ $args->{lack_tags} }) {
                return if $_ ~~ @$tags;
            }
        }
    }
    if (defined $args->{priority}) {
        my $p = $hl->todo_priority;
        return unless defined($p) && $args->{priority} eq $p;
    }

    my $ats = $hl->get_active_timestamp;
    my $days;
    $days = int(($ats->datetime->epoch - $today->epoch)/86400)
        if $ats;
    if (defined $args->{due_in}) {
        return unless $ats;
        return unless $days <= $args->{due_in};
    }

    my $r;
    if ($args->{detail}) {
        $r               = {};
        $r->{file}       = $file;
        $r->{title}      = $hl->title->as_string;
        $r->{due_date}   = $ats ? $ats->datetime : undef;
        $r->{priority}   = $hl->todo_priority;
        $r->{tags}       = [$hl->get_tags];
        $r->{is_todo}    = $hl->is_todo;
        $r->{is_done}    = $hl->is_done;
        $r->{todo_state} = $hl->todo_state;
        $r->{progress}   = $hl->progress;
        $r->{level}      = $hl->level;
    } else {
        if ($ats) {
            my $pl = abs($days) > 1 ? "s" : "";
            $r = sprintf("%s: %s (%s)",
                         $days == 0 ? "today" :
                             $days < 0 ? abs($days)." day$pl ago" :
                                 "in $days day$pl",
                         $hl->title->as_string,
                         $ats->datetime->ymd);
        } else {
            $r = $hl->title->as_string;
        }
    }
    push @$res, $r;
}

$SPEC{list_org_headlines} = {
    summary => 'List all headlines in all Org files',
    args    => {
        files => ['array*' => {
            of         => 'str*',
            arg_pos    => 0,
            arg_greedy => 1,
        }],
        todo => [bool => {
            summary => 'Filter headlines that are todos',
            default => 0,
        }],
        done => [bool => {
            summary => 'Filter todo items that are done',
        }],
        due_in => [int => {
            summary => 'Filter todo items which is due in this number of days',
        }],
        from_level => [int => {
            summary => 'Filter headlines having this level as the minimum',
            default => 1,
        }],
        to_level => [int => {
            summary => 'Filter headlines having this level as the maximum',
        }],
        state => [str => {
            summary => 'Filter todo items that have this state',
        }],
        detail => [bool => {
            summary => 'Show details instead of just titles',
            default => 0,
        }],
        has_tags => [array => {
            summary => 'Filter headlines that have the specified tags',
        }],
        lack_tags => [array => {
            summary => 'Filter headlines that don\'t have the specified tags',
        }],
        priority => [str => {
            summary => 'Filter todo items that have this priority',
        }],
    },
};
sub list_org_headlines {
    my %args = @_;

    my $files = $args{files};
    return [400, "Please specify files"] if !$files || !@$files;

    $today = DateTime->today;
    $yest  = $today->clone->add(days => -1);

    my $orgp = Org::Parser->new;
    my @res;

    for my $file (@$files) {
        $log->debug("Parsing $file ...");
        my $doc = $orgp->parse_file($file);
        $doc->walk(
            sub {
                my ($el) = @_;
                return unless $el->isa('Org::Element::Headline');
                _process_hl($file, $el, \%args, \@res)
            });
    } # for $file

    [200, "OK", \@res];
}

1;


=pod

=head1 NAME

App::ListOrgHeadlines - An application to list headlines in Org files

=head1 VERSION

version 0.01

=head1 FUNCTIONS

None are exported, but they are exportable.

=head2 list_org_headlines(%args) -> [STATUS_CODE, ERR_MSG, RESULT]


List all headlines in all Org files.

Returns a 3-element arrayref. STATUS_CODE is 200 on success, or an error code
between 3xx-5xx (just like in HTTP). ERR_MSG is a string containing error
message, RESULT is the actual result.

Arguments (C<*> denotes required arguments):

=over 4

=item * B<files>* => I<array>

=item * B<detail> => I<bool> (default C<0>)

Show details instead of just titles.

=item * B<done> => I<bool>

Filter todo items that are done.

=item * B<due_in> => I<int>

Filter todo items which is due in this number of days.

=item * B<from_level> => I<int> (default C<1>)

Filter headlines having this level as the minimum.

=item * B<has_tags> => I<array>

Filter headlines that have the specified tags.

=item * B<lack_tags> => I<array>

Filter headlines that don't have the specified tags.

=item * B<priority> => I<str>

Filter todo items that have this priority.

=item * B<state> => I<str>

Filter todo items that have this state.

=item * B<to_level> => I<int>

Filter headlines having this level as the maximum.

=item * B<todo> => I<bool> (default C<0>)

Filter headlines that are todos.

=back

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

