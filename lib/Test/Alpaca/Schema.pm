package Test::Alpaca::Schema;
use sane;
our $SCHEMA = {};

sub add {
    my ($class, $handle, $pair) = @_;
    my ($database, $sql) = %$pair;

    $SCHEMA->{$handle}{$database} ||= [];
    push @{$SCHEMA->{$handle}{$database}}, $sql;
}

sub get {
    my ($class, $handle) = @_;
    return $SCHEMA->{$handle}
}

sub print {
    my ($class) = @_;

    for my $handle (keys %$SCHEMA) {
        my $pair = $SCHEMA->{$handle};
        for my $database (keys %$pair) {
            print "/* $handle -> $database */\n";
            my $queries = $pair->{$database};
            print("\t", $_ =~ s/\s+/ /gr, "\n") for @$queries;
        }
    }
}

1;
__END__

