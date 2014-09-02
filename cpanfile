requires 'perl', '5.008005';

requires 'sane';

requires 'Text::ASCIITable';
requires 'Term::ANSIColor';

requires 'DBIx::QueryLog';
requires 'DBIx::Handler';
requires 'SQL::Format';
requires 'RedisDB';
requires 'Guard';

requires 'Test::More';
requires 'Test::Deep';
requires 'Test::Deep::Matcher';
requires 'Module::Load';
requires 'Test::Docker::MySQL';

requires 'Data::Validator';
requires 'MouseX::Types::Mouse';
requires 'Mouse::Util::TypeConstraints';

on test => sub {
    requires 'Test::More', '1.001003';
    requires 'DBD::SQLite';
};
