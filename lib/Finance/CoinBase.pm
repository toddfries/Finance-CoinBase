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
use Net::HTTP::Spore;

#use Digest::SHA qw(hmac_sha512_hex);
#use MIME::Base64;

our $VERSION = '0.0';

sub api
{
	my ($self, $func, $extra) = @_;

	my $resp;
	eval {
		if (!defined($extra)) {
			$resp = $self->{api}->$func;
		} elsif (ref($extra) eq "HASH") {
			$resp = $self->{api}->$func(%{$extra});
		}
	};
	if ($@) {
		if (!defined($extra)) {
			$extra = "";
		}
		printf STDERR "api: %s(%s) %s\n", $func, $extra, $@;
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

	my $self = { };

	my $apifile = $args->{'apifile'};
	if (!defined($apifile)) {
		print STDERR "This requires an apifile\n";
		return undef;
	}

	my $keyname = $args->{'keyname'};
	if (!defined($keyname)) {
		$keyname = 'Key';
	}
	$self->{api} = Net::HTTP::Spore->new_from_spec($apifile);
	$self->{api}->enable('Net::HTTP::Spore::Middleware::Format::JSON');
	$self->{api}->enable('Net::HTTP::Spore::Middleware::Auth::debug');
	if (0) {
	if (defined($args->{'apikey'}) && defined($args->{'secret'})) {
		print STDERR "apikey && secret exist, enabling Auth::ApiKey\n";
		$self->{api}->enable('Auth::ApiKey',
			keyname => $keyname,
        		api_key  => $args->{'apikey'},
        		api_secret => $args->{'secret'},
		);
	}
	}


	# $self->{api}->enable('Auth::HMACSHA512', key => $args->{'apikey'},
	#    secret => $args->{$secret});

	my $ret = bless $self, $class;

	return $ret;
}

#private methods


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
