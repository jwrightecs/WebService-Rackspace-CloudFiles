package Net::Mosso::CloudFiles::Object;
use Moose;
use MooseX::StrictConstructor;
use Digest::MD5 qw(md5_hex);

has 'cloudfiles' =>
    ( is => 'ro', isa => 'Net::Mosso::CloudFiles', required => 1 );
has 'container' =>
    ( is => 'ro', isa => 'Net::Mosso::CloudFiles::Container', required => 1 );
has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

sub url {
    my ($self) = @_;
    $self->cloudfiles->storage_url . '/'
        . $self->container->name . '/'
        . $self->name;
}

sub size {
    my $self    = shift;
    my $request = HTTP::Request->new( 'HEAD', $self->url,
        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
    my $response = $self->cloudfiles->request($request);
    confess 'Unknown error' if $response->code != 204;
    return $response->header('Content-Length');
}

sub md5 {
    my $self    = shift;
    my $request = HTTP::Request->new( 'HEAD', $self->url,
        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
    my $response = $self->cloudfiles->request($request);
    confess 'Unknown error' if $response->code != 204;
    return $response->header('ETag');
}

sub value {
    my $self    = shift;
    my $request = HTTP::Request->new( 'GET', $self->url,
        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
    my $response = $self->cloudfiles->request($request);
    confess 'Unknown error' if $response->code != 200;
    confess 'Data corruption error'
        if $response->header('ETag') ne md5_hex( $response->content );
    return $response->content;
}

sub delete {
    my $self    = shift;
    my $request = HTTP::Request->new( 'DELETE', $self->url,
        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
    my $response = $self->cloudfiles->request($request);
    confess 'Unknown error' if $response->code != 204;
}

1;