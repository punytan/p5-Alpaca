package Test::Alpaca;
use sane;
use Alpaca::Config;
use Alpaca::QueryLogger;
use Alpaca::Exception;

use Test::More;
use Test::Deep;
use Test::Deep::Matcher;

use Guard 'guard';
use Module::Load;

use DBIx::Handler;

$ENV{DOCKER_HOST} ||= 'tcp://192.168.59.103:2375';

sub import {
    Test::More->export_to_level(1, @_);
    Test::Deep->export_to_level(1, @_);
    Test::Deep::Matcher->export_to_level(1, @_);
    sane->import;

    my $pkg = (caller)[0];
    no strict 'refs';
    *{"${pkg}::test_is_deeply"}  = *test_is_deeply;
    *{"${pkg}::test_cmp_deeply"} = *test_cmp_deeply;
    *{"${pkg}::test_exception"}  = *test_exception;
}

sub setup {
    my ($class, %args) = @_;
    my $guards = {};

    if (my $mysqld = $args{mysqld}) {
        $guards->{mysqld} = $class->launch_mysqld($mysqld);
    }

    if (my $memcached = $args{memcached}) {
        $guards->{memcached} = $class->launch_memcached($memcached);
    }

    if (my $redis = $args{redis}) {
        $guards->{redis} = $class->launch_redis($redis);
    }

    return $guards;
}

sub launch_mysqld {
    my ($class, $args) = @_;

    my $schema_class = ref $args->{schema_class} eq 'ARRAY'
        ? $args->{schema_class}
        : [ $args->{schema_class} ];

    Module::Load::load $_ for @$schema_class;

    note "Launch mysqld...";

    require Test::Docker::MySQL;
    my $mysqld = Test::Docker::MySQL->new;
    my $port = $mysqld->get_port;

    my %configs = Alpaca::Config->configs;
    for my $label (keys %configs) {
        next unless $label =~ /^DB_/;

        for my $schema_class (@$schema_class) {
            my $schema = $schema_class->get($label) || {};

            my $dsn  = "dbi:mysql:database=mysql;host=127.0.0.1;port=$port";
            my $handler = DBIx::Handler->new(
                $dsn, 'root', undef, {
                    RaiseError => 1,
                    AutoCommit => 0,
                }
            );

            my $attr = ref $configs{$label} eq 'ARRAY'
                ? $configs{$label}->[0]{attr}
                : $configs{$label}->{attr};

            my $params = {
                dsn  => "dbi:mysql:database=test;host=127.0.0.1;port=$port",
                user => 'root',
                pass => undef,
                attr => $attr,
            };

            Alpaca::Config->add($label => $params);

            for my $dbname (keys %$schema) {
                $handler->dbh->do("CREATE DATABASE IF NOT EXISTS $dbname");
                $handler->dbh->do("USE test");

                my $queries = $schema->{$dbname};
                $handler->dbh->do($_ =~ s/\s+/ /gr) for @$queries;

            }
        }
    }

    note "Launched mysqld";

    return guard {
        note "Shutdown mysqld...";
        undef $mysqld;
    };
}

sub launch_memcached { # TODO
}

sub launch_redis { # TODO
}

sub init_database {
    my ($class, %dataset) = @_;

    note "Initialize database";
    for my $label (keys %dataset) {
        for my $table (keys %{$dataset{$label}}) {
            my $values = $dataset{$label}->{$table};

            my $config = Alpaca::Config->resolve($label)
                or Alpaca::Exception->throw("No such label: $label");

            my $handler = DBIx::Handler->new(@$config{qw/ dsn user pass attr /});

            $handler->txn(sub {
                my $dbh = shift;
                my ($stmt, @bind) = SQL::Format->new->insert_multi_from_hash($table => $values);
                $dbh->do($stmt, undef, @bind);
            });
        }
    }

    return guard {
        note "Clean up database";
        for my $label (keys %dataset) {
            my $config = Alpaca::Config->resolve($label)
                or Alpaca::Exception->throw("No such label: $label");

            my $handler = DBIx::Handler->new(@$config{qw/ dsn user pass attr /});

            my $rows = $handler->dbh->selectall_arrayref('SHOW TABLES');
            my @tables = map { @$_ } @$rows;
            $handler->dbh->do("TRUNCATE TABLE $_") for @tables;
        }
    };
}

sub test_is_deeply {
    my ($testname, $run, $expect) = @_;

    subtest $testname => sub {
        my $retval = eval { $run->() };

        if (my $e = $@) {
            fail "Exception: " . explain($e);
        } else {
            is_deeply($retval, $expect, $testname) or do {
                note 'Expected: ' => explain $expect;
                note 'Got: '      => explain $retval;
            };
        }
    };
}

sub test_cmp_deeply {
    my ($testname, $run, $expect) = @_;

    subtest $testname => sub {
        my $retval = eval { $run->() };

        if (my $e = $@) {
            fail "Exception: " . explain($e);
        } else {
            cmp_deeply($retval, $expect, $testname) or do {
                note 'Expected: ' => explain $expect;
                note 'Got: '      => explain $retval;
            };
        }
    };
}

sub test_exception {
    my ($testname, $run, $handler) = @_;

    subtest $testname => sub {
        my $retval = eval { $run->() };

        if (my $e = $@) {
            $handler->($e);
        } else {
            fail "No exception: $testname";
        }
    };
}

1;
__END__

