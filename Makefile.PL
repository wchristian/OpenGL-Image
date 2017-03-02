use strictures;
use 5.006001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME         => 'OpenGL::Modern::Image',
    DISTNAME     => 'OpenGL-Modern-Image',
    VERSION_FROM => 'lib/OpenGL/Modern/Image.pm',
    PREREQ_PM    => {
        OpenGL          => '0.55_03',
        'Capture::Tiny' => 0,
    },
    dist => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    (
        $] >= 5.005
        ? (
            ABSTRACT => 'Image Load/Modify/Save Support for the OpenGL Module',
            AUTHOR   => 'Bob "grafman" Free (grafman@grafcomp.com)'
          )
        : ()
    ),
);
