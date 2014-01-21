package Net::HTTP::Spore::Middleware::Auth::ApiKey;

use strict;
use warnings;
{
  $Net::HTTP::Spore::Middleware::Auth::ApiKey::VERSION = '0.01';
}

# ABSTRACT: middleware for authentication with apikey

use Moose;
use MIME::Base64;
use Digest::SHA qw(hmac_sha512_hex);
extends 'Net::HTTP::Spore::Middleware::Auth';

has key_name => (isa => 'Str', is => 'rw', required => 0);
has api_key => (isa => 'Str', is => 'rw', required => 1);
has api_secret => (isa => 'Str', is => 'rw', required => 1);

sub call {
    my ($self, $req) = @_;


    return unless $self->should_authenticate($req);

    print STDERR "Auth::ApiKey::call(0)\n";

    my $keyname = $self->key_name;
    if (!defined($keyname)) {
        $keyname = 'Key';
    }

    print STDERR "Auth::ApiKey::call(1)\n";
    my $nonce = time(); # XXX need $nonce++ and error handling to do more than
			# one query per second
    printf STDERR "Auth::ApiKey::call(2): \$req is a %s\n", ref($req);
    my $content = $req->body;
    if (!defined($content) || length($content) == 0) {
	$content = "method=getInfo";
    } else {
        $content = "method=getInfo&".$content;
    }
    $content .= "&nonce=".$nonce;
    $req->body($content);
    print STDERR "Auth::ApiKey::call(3)\n";
    $req->header('Content-Type' => 'application/x-www-form-urlencoded');
    $req->header($self->key_name => $self->api_key);
    $req->header('Sign' => hmac_sha512_hex($content, $self->api_secret));
}

1;

__END__

=pod

=head1 NAME

Net::HTTP::Spore::Middleware::Auth::ApiKey - middleware for authentication with specific header

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('api.json');
    $client->enable(
        'Auth::ApiKey',
        api_key  => 'apikey',
        api_secret => 'api_secret'
    );

=head1 DESCRIPTION

Net::HTTP::Spore::Middleware::Auth::ApiKey is a middleware to handle authentication mechanism that requires a specific header name.

=head1 AUTHORS

=over 4

=item *

franck cuny <franck@lumberjaph.net>

=item *

Ash Berlin <ash@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
