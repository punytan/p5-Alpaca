package Alpaca::Service;
use sane;
use Alpaca::Config;
use Alpaca::Exception;
use Alpaca::Exception::ValidationError;

use Data::Validator;
use DBIx::Handler;
use SQL::Format;
use RedisDB;

if ($ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development') {
    require Alpaca::QueryLogger;
    Alpaca::QueryLogger->import;
}

my %validators;

sub sql {
    state $sql = SQL::Format->new;
    return $sql;
}

sub config { 'Alpaca::Config' }

sub connect {
    my ($class, $label) = @_;

    my $config = $class->config->resolve($label)
        or Alpaca::Exception->throw("No such label: $label");

    return $class->_connect($label, $config);
}

sub _connect { # you can override in subclass
    my ($class, $label, $config) = @_;

    if ($label =~ /^DB_/) {
        return DBIx::Handler->new(@$config{qw/ dsn user pass attr /});
    } elsif ($label =~ /^REDIS_/) {
        return RedisDB->new(%$config);
    } else {
        Alpaca::Exception->throw("Unknown label rule");
    }
}

sub add_validator {
    my ($class, $name, $args) = @_;
    my $validator = Data::Validator->new(%$args);
    $validator->with('NoRestricted');
    $validators{$class}{$name} = $validator;
}

sub validate {
    my ($class, $name, @args) = @_;

    if (my $validator = $validators{$class}{$name}) {
        my $params = eval { $validator->validate(@args) };
        if (my $e = $@) {
            Alpaca::Exception::ValidationError->throw($e);
        }
        return $params;
    } else {
        Alpaca::Exception->throw("No such validator: $name");
    }
}

1;
__END__
