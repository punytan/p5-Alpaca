package MyApp::Service::User;
use sane;
use parent 'MyApp::Service';
use MyApp::Service::Types qw/ UserID Password Username /;

__PACKAGE__->add_validator(
    get => {
        user_ids => {
            isa => 'ArrayRef[Int]'
        }
    }
);

sub get_users {
    my $class = shift;
    my $args  = $class->validate(get => @_);

    my $users = $class->connect('DB_SLAVE')->run(sub {
        my $dbh = shift;
        my ($stmt, @bind) = $class->sql->select(
            users => [qw/ user_id username /], {
                user_id => { IN => $args->{user_ids} }
            },
        );
        $dbh->selectall_hashref($stmt, 'user_id', { Slice => {} }, @bind)
    });

    return $users;
}

__PACKAGE__->add_validator(
    create => {
        username => {
            isa => Username,
        },
        password => {
            isa => Password,
        },
    }
);

sub create_user {
    my $class = shift;
    my $args  = $class->validate(create => @_);

    $class->connect('DB_MASTER')->txn(sub {
        my $dbh = shift;
        my ($stmt, @bind) = $class->sql->insert(
            users => {
                username => $args->{username},
                password => $args->{password},
            }
        );
        $dbh->do($stmt, undef, @bind);
    });

    return;
}

1;
__END__

