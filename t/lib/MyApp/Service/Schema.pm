package MyApp::Service::Schema;
use parent 'Test::Alpaca::Schema';

__PACKAGE__->add(DB_MASTER => { test => <<SQL });
CREATE TABLE `users` (
    `user_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `username` varchar(32) NOT NULL,
    `password` varchar(32) NOT NULL,
    PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
SQL

1;
__END__

