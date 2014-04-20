package Alpaca::Config;
use sane;

my %configs;

sub add {
    my ($class, $label, $args) = @_;
    $configs{$label} = $args;
}

sub resolve {
    my ($class, $label) = @_;
    my $config = $configs{$label};

    if (ref $config eq 'ARRAY') {
        my $index = int(rand scalar @$config);
        return $config->[$index];
    } else {
        return $config;
    }
}

sub configs {
    return %configs;
}

1;
__END__
