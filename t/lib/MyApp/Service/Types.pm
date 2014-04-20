package MyApp::Service::Types;
use sane;
use MouseX::Types::Mouse qw/ Int Str /;
use MouseX::Types -declare => [ qw/ UserID Username Password / ];

subtype UserID,
    as Int,
    where { $_ > 0 };

subtype Username,
    as Str,
    where { length $_ > 0 && length $_ < 32};

subtype Password,
    as Str,
    where { length $_ > 6 };

1;

