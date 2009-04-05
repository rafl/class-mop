
package Class::MOP::Method::Constructor;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken', 'looks_like_number';

our $VERSION   = '0.80';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Class::MOP::Method::Generated';

sub new {
    my $class   = shift;
    my %options = @_;

    (blessed $options{metaclass} && $options{metaclass}->isa('Class::MOP::Class'))
        || confess "You must pass a metaclass instance if you want to inline"
            if $options{is_inline};

    ($options{package_name} && $options{name})
        || confess "You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT";

    my $self = $class->_new(\%options);

    # we don't want this creating
    # a cycle in the code, if not
    # needed
    weaken($self->{'associated_metaclass'});

    $self->_initialize_body;

    return $self;
}

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    bless {
        # from our superclass
        'body'                 => undef,
        'package_name'         => $options->{package_name},
        'name'                 => $options->{name},        
        # specific to this subclass
        'options'              => $options->{options} || {},
        'associated_metaclass' => $options->{metaclass},
        'is_inline'            => ($options->{is_inline} || 0),
    }, $class;
}

sub can_be_inlined { 1 }

## accessors

sub options              { (shift)->{'options'}              }
sub associated_metaclass { (shift)->{'associated_metaclass'} }

## cached values ...

sub meta_instance {
    warn 'The meta_instance method has been made private.'
        . " The public version is deprecated and will be removed in a future release.\n";
    shift->_meta_instance;
}

sub _meta_instance {
    my $self = shift;
    $self->{'meta_instance'} ||= $self->associated_metaclass->get_meta_instance;
}

sub attributes {
    warn 'The attributes method is deprecated.'
        . " Use ->associated_metaclass->get_all_attributes instead.\n";

    my $self = shift;
    $self->{'attributes'} ||= [ $self->associated_metaclass->get_all_attributes ]
}

## method

sub initialize_body {
    warn 'The initialize_body method has been made private.'
        . " The public version is deprecated and will be removed in a future release.\n";
    shift->_initialize_body;
}

sub _initialize_body {
    my $self        = shift;
    my $method_name = '_generate_constructor_method';

    $method_name .= '_inline' if $self->is_inline;

    $self->{'body'} = $self->$method_name;
}

sub generate_constructor_method {
    warn 'The generate_constructor_method method has been made private.'
        . " The public version is deprecated and will be removed in a future release.\n";
    shift->_generate_constructor_method;
}

sub _generate_constructor_method {
    return sub { Class::MOP::Class->initialize(shift)->new_object(@_) }
}

sub generate_constructor_method_inline {
    warn 'The generate_constructor_method_inline method has been made private.'
        . " The public version is deprecated and will be removed in a future release.\n";
    shift->_generate_constructor_method_inline;
}

sub _generate_constructor_method_inline {
    my $self = shift;

    my $close_over = {};

    my $source = 'sub {';
    $source .= "\n" . 'my $class = shift;';

    $source .= "\n" . 'return Class::MOP::Class->initialize($class)->new_object(@_)';
    $source .= "\n" . '    if $class ne \'' . $self->associated_metaclass->name . '\';';

    $source .= "\n" . 'my $params = @_ == 1 ? $_[0] : {@_};';

    $source .= "\n" . 'my $instance = ' . $self->_meta_instance->inline_create_instance('$class');
    $source .= ";\n" . (join ";\n" => map {
        $self->_generate_slot_initializer($_, $close_over)
    } $self->associated_metaclass->get_all_attributes);
    $source .= ";\n" . 'return $instance';
    $source .= ";\n" . '}';
    warn $source if $self->options->{debug};

    my $code = $self->_eval_closure(
        $close_over,
        $source
    );
    confess "Could not eval the constructor :\n\n$source\n\nbecause :\n\n$@" if $@;

    return $code;
}

sub _generate_slot_initializer {
    my $self  = shift;
    my $attr  = shift;
    my $close = shift;

    my $default;
    if ($attr->has_default) {
        # NOTE:
        # default values can either be CODE refs
        # in which case we need to call them. Or
        # they can be scalars (strings/numbers)
        # in which case we can just deal with them
        # in the code we eval.
        if ($attr->is_default_a_coderef) {
            my $idx = @{$close->{'@defaults'}||=[]};
            push(@{$close->{'@defaults'}}, $attr->default);
            $default = '$defaults[' . $idx . ']->($instance)';
        }
        else {
            $default = $attr->default;
            # make sure to quote strings ...
            unless (looks_like_number($default)) {
                $default = "'$default'";
            }
        }
    } elsif( $attr->has_builder ) {
        $default = '$instance->'.$attr->builder;
    }

    if ( defined $attr->init_arg ) {
      return (
          'if(exists $params->{\'' . $attr->init_arg . '\'}){' . "\n" .
                $self->_meta_instance->inline_set_slot_value(
                    '$instance',
                    $attr->name,
                    '$params->{\'' . $attr->init_arg . '\'}' ) . "\n" .
           '} ' . (!defined $default ? '' : 'else {' . "\n" .
                $self->_meta_instance->inline_set_slot_value(
                    '$instance',
                    $attr->name,
                     $default ) . "\n" .
           '}')
        );
    } elsif ( defined $default ) {
        return (
            $self->_meta_instance->inline_set_slot_value(
                '$instance',
                $attr->name,
                 $default ) . "\n"
        );
    } else { return '' }
}

1;

__END__

=pod

=head1 NAME

Class::MOP::Method::Constructor - Method Meta Object for constructors

=head1 SYNOPSIS

  use Class::MOP::Method::Constructor;

  my $constructor = Class::MOP::Method::Constructor->new(
      metaclass => $metaclass,
      options   => {
          debug => 1, # this is all for now
      },
  );

  # calling the constructor ...
  $constructor->body->execute($metaclass->name, %params);

=head1 DESCRIPTION

This is a subclass of C<Class::MOP::Method> which generates
constructor methods.

=head1 METHODS

=over 4

=item B<< Class::MOP::Method::Constructor->new(%options) >>

This creates a new constructor object. It accepts a hash reference of
options.

=over 8

=item * metaclass

This should be a L<Class::MOP::Class> object. It is required.

=item * name

The method name (without a package name). This is required.

=item * package_name

The package name for the method. This is required.

=item * is_inline

This indicates whether or not the constructor should be inlined. This
defaults to false.

=back

=item B<< $metamethod->is_inline >>

Returns a boolean indicating whether or not the constructor is
inlined.

=item B<< $metamethod->associated_metaclass >>

This returns the L<Class::MOP::Class> object for the method.

=item B<< $metamethod->can_be_inlined >>

This method always returns true in this class. It exists so that
subclasses (as in Moose) can do some sort of checking to determine
whether or not inlining the constructor is safe.

=back

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

