package Net::HTTP::Spore::Middleware::Auth::debug;

use strict;
use warnings;
{
  $Net::HTTP::Spore::Middleware::Auth::debug::VERSION = '0.01';
}

# ABSTRACT: middleware for authentication with apikey

use Moose;
extends 'Net::HTTP::Spore::Middleware::Auth';

sub call {
    my ($self, $req) = @_;

    my $fh;
    if (!open($fh, ">", "/dev/tty")) {
	return;
    }
    printf $fh "req = { %s }\n", $req->as_string;
    close($fh);
}

1;

__END__

=pod

=head1 NAME

Net::HTTP::Spore::Middleware::Auth::debug - middleware for authentication with specific header

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('api.json');
    $client->enable(
        'Auth::debug',
        api_key  => 'apikey',
        api_secret => 'api_secret'
    );

=head1 DESCRIPTION

Net::HTTP::Spore::Middleware::Auth::debug is a middleware to handle authentication mechanism that requires a specific header name.

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
