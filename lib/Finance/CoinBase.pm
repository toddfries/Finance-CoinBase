# Copyright (c) 2014 Todd T. Fries <todd@fries.net>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package Finance::CoinBase;

use 5.012004;
use strict;
use warnings;
use POSIX; # for INT_MAX
use Net::HTTP::Spore;
use Carp qw(croak);

#use Digest::SHA qw(hmac_sha512_hex);
#use MIME::Base64;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our $VERSION = '0.0';

# maybe these bits can go away?
use JSON;
use WWW::Mechanize;
our $json = JSON->new->allow_nonref;


our $user_agent = "Mozilla/4.76 [en] (Win98; U)";

our $apiurl = "https://coinbase.com/api/v1";

sub api
{
	my ($self, $func) = @_;

	my $resp;
	eval {
		$resp = $self->{api}->$func;
	};
	if ($@) {
		printf STDERR "api(%s): %s\n", $func, $@;
		return undef;
	}
	if (!defined($resp)) {
		return $resp;
	}
	if (! (ref($resp) eq "Net::HTTP::Spore::Response")) {
		return undef;
	}
	return $resp->body;
}

### Authenticated API calls

sub new
{
	my ($class, $args) = @_;

	my $self = {
		mech => WWW::Mechanize->new(stack_depth => 0, quiet=>0),
		apikey => $args->{'apikey'},
		secret => $args->{'secret'},
	};

	$self->{api} = Net::HTTP::Spore->new_from_spec('cb.json',
		base_url => $apiurl);
	$self->{api}->enable('Net::HTTP::Spore::Middleware::Format::JSON');
	# $self->{api}->enable('Auth::HMACSHA512', key => $args->{'apikey'},
	#    secret => $args->{$secret});

	my $ret = bless $self, $class;
	$self->set('user_agent', 'Windows IE 6');
	return $ret;
}

sub set
{
	my ($self, $var, @vals)  = @_;

	if ($var eq "user_agent") {
		$self->{mech}->agent_alias($vals[0]);
		return;
	}

}

sub get
{
	my ($self, $var, @args) = @_;
}


#private methods

sub _apikey
{
	my ($self) = @_;
	return $self->{'apikey'};
}

sub _apiprice
{
	my ($self, $type) = @_;
	if (!defined($type)) {
		my %i;
		return  \%i;
	}

	my $ret = $self->_apiget($apiurl."/prices/".$type);
	if (!defined($ret)) {
		my %i;
		return \%i;
	}
	my %price = %{$ret};
	return \%price;
}

# A word about nonces.  Nowhere can I find this documented, but through
# experience I have figured out that the nonce is a unique integer per api key
# that must be incremented per request.  Whatever one starts out with, one must
# increment.  Thus unix time seems appropriate for most use cases.
# In the event multiple apps are using the same api key (debug daemon +
# cli app) then we recover and set the nonce from the server which kindly
# tells us what the next one should be.

# Initially int(rand(INT_MAX)) was used, but hitting the max acceptable value
# is undefined, worst case have to get a new api key.

# so, instead, choose INT_MAX/4 to ensure the initial value is in the lower
# 1/4 of our integer range, pleanty of room if randomly we hit a high number
# to start with.
sub _createnonce
{
	my ($self) = @_;
	if (!defined($self->{nonce})) {
		$self->{nonce} = int(rand(INT_MAX/4));
	} else {
		$self->{nonce}++;
	}
	return $self->{nonce};
}

sub _decode
{
	my ($self) = @_;

	my %apireturn = %{$json->decode( $self->_mech->content )};

	return \%apireturn;
}

sub _known_error
{
	my ($self, $string) = @_;

	my @known_errs = (
			'Connection timed out',
	);

	foreach my $err (@known_errs) {
		if ($string =~ /$err/) {
			return 1;
		}
	}
	return 0;
}

sub _mech
{
	my ($self) = @_;

	return $self->{mech};
}

sub _newagent
{
	my ($self) = @_;
	my $version = $user_agent;
	my $agent = LWP::UserAgent->new(ssl_opts => {verify_hostname => 1}, env_proxy => 1);
	if (defined($version)) {
		$agent->agent($version);
	}
	return $agent;
}

sub _post
{
	my ($self, $method, $args) = @_;
	retrynonce:
	my $uri = URI->new($apiurl."/".$method);
	my $req = HTTP::Request->new( 'POST', $uri );
	my $query = "method=${method}";
	if (defined($args)) {
		foreach my $var (keys %{$args}) {
			my $val = ${$args}{$var};
			if (!defined($val)) {
				next;
			}
			$query .= "&".$var."=".$val;
		}
	}
	$query .= "&nonce=".$self->_createnonce;
	$uri->query(undef);
	$req->header( 'Content-Type' => 'application/x-www-form-urlencoded');
	$req->content($query);
	$req->header('Key' => $self->_apikey);
	$req->header('Sign' => $self->_sign($query));
	my $retrycount = 0;
	retrypost:
	eval {
		$self->_mech->request($req);
	};
	if ($@) {
		if ($self->_known_error($@)) {
			print STDERR "!";
			if ($retrycount++ < 30) {
				sleep(5+int($retrycount/3));
				goto retrypost;
			}
		}
		printf STDERR "_post: request: unknown error: %s\n", $@;
		my %empty;
		return \%empty;
	}
	#printf STDERR "_post: self->_decode content='%s'\n",
	#    $self->_mech->content;
	my %result;
	my $res;
	eval {
		$res = $self->_decode;
	};
	if ($@) {
		printf STDERR "_post: self->_decode: %s\n", $@;
		printf STDERR "_post: self->_decode content='%s'\n",
		    $self->_mech->content;
		return \%result;
	}
	%result = %{$res};
	if (defined($result{success}) && defined($result{error})) {
		if ($result{success} == 0 && $result{error} =~
		    /invalid nonce parameter; on key:([0-9]+),/) {
			my $newnonce = $1;
			$self->{nonce} = $newnonce;
			printf STDERR "using new nonce %d\n", $newnonce;
			goto retrynonce;
		}
	}

	return \%result;
}

sub _secretkey
{
	my ($self) = @_;
	return $self->{'secret'};
}

sub _sign
{
	my ($self, $params) = @_;
	return hmac_sha512_hex($params,$self->_secretkey);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::CoinBase - Perl extension for interfacing with the BTC-e bitcoin exchange

=head1 Version

Version 0.01

=head1 SYNOPSIS

  use Finance::CoinBase;

  my $CoinBase = Finance::CoinBase->new({apikey => 'key',
	secret => 'secret',});

  #public API calls

  #Prices for Bitcoin to USD
  my %price = %{Conversion('sell')};

  #Prices for USD to Bitcoin
  my %price = %{Conversion('buy')};

  #Authenticated API Calls

=head2 EXPORT

None by default.

=head1 BUGS

Please report all bug and feature requests through github
at L<https://github.com/toddfries/Finance-CoinBase/issues>

=head1 AUTHOR

Todd T. Fries, E<lt>todd@fries.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Todd T. Fries <todd@fries.net>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut
