package Alpaca::QueryLogger;
use sane;
use DBIx::QueryLog;
use Text::ASCIITable;
use Term::ANSIColor 'colored';

sub import {
    DBIx::QueryLog->import;
    DBIx::QueryLog->explain(1);
    DBIx::QueryLog->compact(1);
    __PACKAGE__->logger(__PACKAGE__);
    __PACKAGE__->skip('DBIx::Handler');
}

sub printer {
    my ($class, $raw_message, $opts) = @_;

    my $message = $opts && $opts->{indent}
        ? "\t" . join "\t", (map { "$_\n" } split /\n/, $raw_message)
        : $raw_message;
    if ($ENV{HARNESS_ACTIVE}) {
        require Test::More;
        Test::More::note("$message");
    } else {
        warn "$message";
    }
}

sub logger { shift; DBIx::QueryLog->logger(@_) }
sub log    {
    my ($class, %args) = @_;

    my %params = %{$args{params}};
    $class->printer(
        sprintf "%8.3fms | [%s:L%d] %s",
            ($params{time} * 1000),
            $params{pkg},
            $params{line},
            colored(['green'], $params{sql}),
    );
    if (my $explain = $args{params}->{explain}) {
        my @keys = qw/ id select_type table type possible_keys key key_len ref rows Extra /;

        my $t = Text::ASCIITable->new({ allowANSI => 1 });
        $t->setCols(@keys);

        for my $e (@$explain) {
            my $type = length $e->{type} ? $e->{type} : 'NULL';
            my $color = (grep { $type eq $_ } qw/ const eq_ref ref range /)
                ? ['bold', 'green']
                : ['bold', 'yellow'];

            $e->{type} = colored $color, $type;
            $t->addRow(map { length $e->{$_} ? $e->{$_} : 'NULL' } @keys);
        }

        $class->printer($t, { indent => 1 });
    }
}

sub skip {
    shift;
    %DBIx::QueryLog::SKIP_PKG_MAP = (
        %DBIx::QueryLog::SKIP_PKG_MAP,
        map { ($_ => 1) } @_,
    );
}

1;
__END__

