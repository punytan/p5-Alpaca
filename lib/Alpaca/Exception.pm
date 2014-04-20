package Alpaca::Exception;
use sane;
use overload '""' => sub { shift->{code} };

sub new {
    my ($class, $code, @args) = @_;
    bless { code => $code, args => [ @args ] }, $class;
}

sub throw {
    my ($class, @args) = @_;
    die $class->new(@args);
}

1;
__END__

