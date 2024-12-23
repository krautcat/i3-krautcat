use strict;
use warnings;
use 5.016;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => "App::I3::Krautcat",
    license             => "perl",
    dist_author         => "Georgiy Odisharia <georgiy.odisharia\@gmail.com>",
    dist_abstract       => "Application for i3 window manager",
    create_makefile_pl  => 0,
    script_files        => "bin/i3-krautcat",
    create_readme       => 0,
);

$builder->create_build_script();
