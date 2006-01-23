
package Class::MOP::Attribute;

use strict;
use warnings;

use Carp 'confess';

our $VERSION = '0.01';

sub new {
    my $class   = shift;
    my $name    = shift;
    my %options = @_;    
        
    (defined $name && $name ne '')
        || confess "You must provide a name for the attribute";
    
    bless {
        name     => $name,
        accessor => $options{accessor},
        reader   => $options{reader},
        writer   => $options{writer},
        init_arg => $options{init_arg},
        default  => $options{default}
    } => $class;
}

sub name         { (shift)->{name}             }

sub has_accessor { (shift)->{accessor} ? 1 : 0 }
sub accessor     { (shift)->{accessor}         } 

sub has_reader   { (shift)->{reader}   ? 1 : 0 }
sub reader       { (shift)->{reader}           }

sub has_writer   { (shift)->{writer}   ? 1 : 0 }
sub writer       { (shift)->{writer}           }

sub has_init_arg { (shift)->{init_arg} ? 1 : 0 }
sub init_arg     { (shift)->{init_arg}         }

sub has_default  { (shift)->{default}  ? 1 : 0 }
sub default      { (shift)->{default}          }

sub generate_accessor {
    my $self = shift;
    # ... 
}

1;

__END__

=pod

=head1 NAME 

Class::MOP::Attribute - Attribute Meta Object

=head1 SYNOPSIS
  
  Class::MOP::Attribute->new('$foo' => (
      accessor => 'foo',        # dual purpose get/set accessor
      init_arg => '-foo',       # class->new will look for a -foo key
      default  => 'BAR IS BAZ!' # if no -foo key is provided, use this
  ));
  
  Class::MOP::Attribute->new('$.bar' => (
      reader   => 'bar',        # getter
      writer   => 'set_bar',    # setter      
      init_arg => '-bar',       # class->new will look for a -bar key
      # no default value means it is undef
  ));

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<gt>stevan@iinteractive.comE<lt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut