package Test::Alpaca::Schema;
use sane;
our $SCHEMA = {};

sub add {
    my ($class, $handle, $pair) = @_;
    my ($database, $sql) = %$pair;

    $SCHEMA->{$handle}{$database} ||= [];
    push $SCHEMA->{$handle}{$database}, $sql;
}

sub get {
    my ($class, $handle) = @_;
    return $SCHEMA->{$handle}
}

1;
__END__

