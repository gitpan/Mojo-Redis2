use Mojo::Base -strict;
use Test::More;
use Mojo::Redis2::Server;
my $pid;

plan skip_all => 'Cannot test on Win32' if $^O =~ /win/i;

{
  my $server = Mojo::Redis2::Server->new;
  local $ENV{REDIS_SERVER_BIN} = './does-not-exist-nope-for-sure-i-hope-not';
  eval { $server->start };
  like $@, qr{Failed to start}, 'No such file';
  is $server->url, '', 'url is not set';
}

SKIP: {
  my $server = eval { Mojo::Redis2::Server->start };
  skip "redis-server is not installed: $@", 1 if $@;
  like $server->config->{port}, qr{\d+}, 'port was generated';
  is $ENV{MOJO_REDIS_URL}, "redis://x:\@$server->{config}{bind}:$server->{config}{port}/", 'MOJO_REDIS_URL was generated';
  ok kill(0, $server->pid), 'server is running';

  is(Mojo::Redis2::Server->stop, Mojo::Redis2::Server->singleton, 'stop');
  ok !kill(0, $server->pid), 'server was stopped';
  like $server->url, qr{redis://x:\@[\w\.:]+/?$}, 'url is set';
}

SKIP: {
  my $server = Mojo::Redis2::Server->new;
  eval { $server->start };
  skip "redis-server is not installed: $@", 1 if $@;
  $pid = $server->pid;
}

if ($pid) {
  ok !kill(0, $pid), 'server was stopped on DESTROY';
}

done_testing;
