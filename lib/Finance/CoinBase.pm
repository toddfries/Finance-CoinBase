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
		if (ref($extra) eq "HASH") {
			printf STDERR "api: %s(HASH) %s\n", $func, $@;
			print STDERR $self->dumpit($extra);
		} else {
			printf STDERR "api: %s(%s) %s\n", $func, $extra, $@;
		}
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

	$self->{api} = Net::HTTP::Spore->new_from_spec($apifile);
	$self->{api}->enable('Format::JSON');

	my $ret = bless $self, $class;

	return $ret;
}

sub dumpit
{
	my ($self, $info, $indent, $oindent) = @_;

	my $ai = "    ";

	if (!defined($indent)) {
		$indent = "";
	}
	if (!defined($oindent)) {
		$oindent = "";
	}
	if (!defined($info)) {
		$info = "<undef>";
	}

	my $type = ref($info);

	unless ($type) {
		printf " %s\n", $info;
		return;
	}

	if ($type eq "ARRAY") {
		printf "ARRAY (\n";
		foreach my $a (@{$info}) {
			print $indent;
			$self->dumpit($a, $indent.$ai, $indent);
		}
		printf "%s),\n", substr($indent,0,length($indent)-5);;
		return;
	}
	if ($type eq "HASH") {
		print "HASH {";
		my @keylist = keys %{$info};
		if (! @keylist || $#keylist < 0) {
			print " <empty> }\n";
			return;
		}
		print "\n";
		foreach my $k (keys %{$info}) {
			printf "%s '%s' => ", $indent.$ai, $k;
			$self->dumpit($info->{$k}, $indent.$ai.$ai, $indent);
		}
		printf "%s},\n", substr($indent,0,length($indent)-5);;
		return;
	}
	if ($type eq "Net::HTTP::Spore::Response") {
		print "Net::HTTP::Spore::Response {\n";
		# check $info->status
		$self->dumpit($info->body, $indent.$ai.$ai, $indent);
		printf "%s},\n", substr($indent,0,length($indent)-5);;
		return;
	}
	printf "%s %s (unhandled)\n", $indent, $type;
	return;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::CoinBase - Perl extension for interfacing with the CoinBase bitcoin exchange

=head1 Version

Version 0.01

=head1 SYNOPSIS

  use Finance::CoinBase;

  my $CoinBase = Finance::CoinBase->new({apikey => 'key',
	secret => 'secret', keyname => 'api_key' });

  #public API calls

  #Prices for Bitcoin to USD
  my %price = $CoinBase->api('buyrate');

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

Donations (not required or requested, but incase desired..):

For Todd T. Fries BTC 1Bv3F86y2Vpj8fcV2ZU4EwhDuMiaYDswy7

=cut
