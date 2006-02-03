#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;
use Test::Exception;

BEGIN { 
    use_ok('Class::MOP', ':universal'); 
}

my $FOO_ATTR = Class::MOP::Attribute->new('$foo');
my $BAR_ATTR = Class::MOP::Attribute->new('$bar' => (
    accessor => 'bar'
));
my $BAZ_ATTR = Class::MOP::Attribute->new('$baz' => (
    reader => 'get_baz',
    writer => 'set_baz',    
));

{
    package Foo;

    my $meta = Foo->meta;
    ::lives_ok {
        $meta->add_attribute($FOO_ATTR);
    } '... we added an attribute to Foo successfully';
    ::ok($meta->has_attribute('$foo'), '... Foo has $foo attribute');
    ::is($meta->get_attribute('$foo'), $FOO_ATTR, '... got the right attribute back for Foo');
    
    ::ok(!$meta->has_method('foo'), '... no accessor created');
}
{
    package Bar;
    our @ISA = ('Foo');
    
    my $meta = Bar->meta;
    ::lives_ok {
        $meta->add_attribute($BAR_ATTR);
    } '... we added an attribute to Bar successfully';
    ::ok($meta->has_attribute('$bar'), '... Bar has $bar attribute');
    ::is($meta->get_attribute('$bar'), $BAR_ATTR, '... got the right attribute back for Bar');

    ::ok($meta->has_method('bar'), '... an accessor has been created');
    ::isa_ok($meta->get_method('bar'), 'Class::MOP::Attribute::Accessor');    
}
{
    package Baz;
    our @ISA = ('Bar');
    
    my $meta = Baz->meta;
    ::lives_ok {
        $meta->add_attribute($BAZ_ATTR);
    } '... we added an attribute to Baz successfully';
    ::ok($meta->has_attribute('$baz'), '... Baz has $baz attribute');    
    ::is($meta->get_attribute('$baz'), $BAZ_ATTR, '... got the right attribute back for Baz');

    ::ok($meta->has_method('get_baz'), '... a reader has been created');
    ::ok($meta->has_method('set_baz'), '... a writer has been created');

    ::isa_ok($meta->get_method('get_baz'), 'Class::MOP::Attribute::Accessor');
    ::isa_ok($meta->get_method('set_baz'), 'Class::MOP::Attribute::Accessor');
}

{
    my $meta = Baz->meta;
    isa_ok($meta, 'Class::MOP::Class');
    
    is_deeply(
        [ sort { $a->{name} cmp $b->{name} } $meta->compute_all_applicable_attributes() ],
        [ 
            {
                name      => '$bar',
                class     => 'Bar',
                attribute => $BAR_ATTR
            },
            {
                name      => '$baz',
                class     => 'Baz',
                attribute => $BAZ_ATTR
            },
            {
                name      => '$foo',
                class     => 'Foo',
                attribute => $FOO_ATTR
            },                        
        ],
        '... got the right list of applicable attributes for Baz');
    
    my $attr;
    lives_ok {
        $attr = $meta->remove_attribute('$baz');
    } '... removed the $baz attribute successfully';
    is($attr, $BAZ_ATTR, '... got the right attribute back for Baz');           
    
    ok(!$meta->has_attribute('$baz'), '... Baz no longer has $baz attribute'); 

    ok(!$meta->has_method('get_baz'), '... a reader has been removed');
    ok(!$meta->has_method('set_baz'), '... a writer has been removed');

    is_deeply(
        [ sort { $a->{name} cmp $b->{name} } $meta->compute_all_applicable_attributes() ],
        [ 
            {
                name      => '$bar',
                class     => 'Bar',
                attribute => $BAR_ATTR
            },
            {
                name      => '$foo',
                class     => 'Foo',
                attribute => $FOO_ATTR
            },                        
        ],
        '... got the right list of applicable attributes for Baz');

     {
         my $attr;
         lives_ok {
             $attr = Bar->meta->remove_attribute('$bar');
         } '... removed the $bar attribute successfully';
         is($attr, $BAR_ATTR, '... got the right attribute back for Bar');           

         ok(!Bar->meta->has_attribute('$bar'), '... Bar no longer has $bar attribute'); 

         ok(!Bar->meta->has_method('bar'), '... a accessor has been removed');
     }

     is_deeply(
         [ sort { $a->{name} cmp $b->{name} } $meta->compute_all_applicable_attributes() ],
         [ 
             {
                 name      => '$foo',
                 class     => 'Foo',
                 attribute => $FOO_ATTR
             },                        
         ],
         '... got the right list of applicable attributes for Baz');

}