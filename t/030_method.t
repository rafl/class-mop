use strict;
use warnings;

use Test::More tests => 46;
use Test::Exception;

use Class::MOP;
use Class::MOP::Method;


my $method = Class::MOP::Method->wrap(
    sub { 1 },
    package_name => 'main',
    name         => '__ANON__',
);
is($method->meta, Class::MOP::Method->meta, '... instance and class both lead to the same meta');

is($method->package_name, 'main', '... our package is main::');
is($method->name, '__ANON__', '... our sub name is __ANON__');
is($method->fully_qualified_name, 'main::__ANON__', '... our subs full name is main::__ANON__');
is($method->original_method, undef, '... no original_method ');
is($method->original_package_name, 'main', '... the original_package_name is the same as package_name');
is($method->original_name, '__ANON__', '... the original_name is the same as name');
is($method->original_fully_qualified_name, 'main::__ANON__', '... the original_fully_qualified_name is the same as fully_qualified_name');

dies_ok { Class::MOP::Method->wrap } q{... can't call wrap() without some code};
dies_ok { Class::MOP::Method->wrap([]) } q{... can't call wrap() without some code};
dies_ok { Class::MOP::Method->wrap(bless {} => 'Fail') } q{... can't call wrap() without some code};

dies_ok { Class::MOP::Method->name } q{... can't call name() as a class method};
dies_ok { Class::MOP::Method->body } q{... can't call body() as a class method};
dies_ok { Class::MOP::Method->package_name } q{... can't call package_name() as a class method};
dies_ok { Class::MOP::Method->fully_qualified_name } q{... can't call fully_qualified_name() as a class method};

my $meta = Class::MOP::Method->meta;
isa_ok($meta, 'Class::MOP::Class');

foreach my $method_name (qw(
    wrap
	package_name
	name
    )) {
    ok($meta->has_method($method_name), '... Class::MOP::Method->has_method(' . $method_name . ')');
	my $method = $meta->get_method($method_name);
	is($method->package_name, 'Class::MOP::Method', '... our package is Class::MOP::Method');
	is($method->name, $method_name, '... our sub name is "' . $method_name . '"');	
}

dies_ok {
    Class::MOP::Method->wrap()
} '... bad args for &wrap';

dies_ok {
    Class::MOP::Method->wrap('Fail')
} '... bad args for &wrap';

dies_ok {
    Class::MOP::Method->wrap([])
} '... bad args for &wrap';

dies_ok {
    Class::MOP::Method->wrap(sub { 'FAIL' })
} '... bad args for &wrap';

dies_ok {
    Class::MOP::Method->wrap(sub { 'FAIL' }, package_name => 'main')
} '... bad args for &wrap';

dies_ok {
    Class::MOP::Method->wrap(sub { 'FAIL' }, name => '__ANON__')
} '... bad args for &wrap';

my $clone = $method->clone(
    package_name => 'NewPackage',
    name         => 'new_name',
);

isa_ok($clone, 'Class::MOP::Method');
is($clone->package_name, 'NewPackage', '... cloned method has new package name');
is($clone->name, 'new_name', '... cloned method has new sub name');
is($clone->fully_qualified_name, 'NewPackage::new_name', '... cloned method has new fq name');
is($clone->original_method, $method, '... cloned method has correct original_method');
is($clone->original_package_name, 'main', '... cloned method has correct original_package_name');
is($clone->original_name, '__ANON__', '... cloned method has correct original_name');
is($clone->original_fully_qualified_name, 'main::__ANON__', '... cloned method has correct original_fully_qualified_name');

my $clone2 = $clone->clone(
    package_name => 'NewerPackage',
    name         => 'newer_name',
);

is($clone2->package_name, 'NewerPackage', '... clone of clone has new package name');
is($clone2->name, 'newer_name', '... clone of clone has new sub name');
is($clone2->fully_qualified_name, 'NewerPackage::newer_name', '... clone of clone new fq name');
is($clone2->original_method, $clone, '... cloned method has correct original_method');
is($clone2->original_package_name, 'main', '... original_package_name follows clone chain');
is($clone2->original_name, '__ANON__', '... original_name follows clone chain');
is($clone2->original_fully_qualified_name, 'main::__ANON__', '... original_fully_qualified_name follows clone chain');
