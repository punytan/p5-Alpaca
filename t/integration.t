use sane;
use Test::Alpaca;
use lib 't/lib';
use MyApp::Service::User;
use MyApp::Service::Types;

my $guards = Test::Alpaca->setup(
    mysqld => {
        schema_class => 'MyApp::Service::Schema'
    }
);

subtest 'get users' => sub {
    test_is_deeply 'get users from database',
        sub {
            my $guard = Test::Alpaca->init_database(
                DB_MASTER => {
                    users => [
                        { username => 'foo', password => 'foofoo' },
                        { username => 'bar', password => 'barbar' },
                    ]
                }
            );

            MyApp::Service::User->get_users(user_ids => [ 1, 2 ]);
        },
        {
            1 => { user_id => 1, username => 'foo' },
            2 => { user_id => 2, username => 'bar' },
        };
};

subtest 'create user' => sub {
    test_is_deeply 'user should be created',
        sub {
            my $guard = Test::Alpaca->init_database;

            MyApp::Service::User->create_user(
                username => 'baz',
                password => 'password123'
            );

            return MyApp::Service->connect('DB_SLAVE')->run(sub {
                my $dbh = shift;
                my ($stmt, @bind) = MyApp::Service->sql->select(
                    users => ['*'],
                    { user_id => 1 },
                );
                $dbh->selectrow_hashref($stmt, undef, @bind);
            });
        },
        {
            user_id  => 1,
            username => 'baz',
            password => 'password123'
        };

    test_exception 'validation error',
        sub {
            MyApp::Service::User->create_user(
                password => 'bazbaz'
            );
        },
        sub {
            my $e = shift;
            like $e, qr/Missing parameter: 'username'/ or note $e;
        };
};

done_testing;

