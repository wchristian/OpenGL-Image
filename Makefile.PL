use strictures;
use 5.006001;
use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME         => 'OpenGL::Modern::Image',
    DISTNAME     => 'OpenGL-Modern-Image',
    VERSION_FROM => 'lib/OpenGL/Modern/Image.pm',
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    (
        $] >= 5.005
        ? (
            ABSTRACT => 'Image Load/Modify/Save Support for OpenGL::Modern',
            AUTHOR   => 'Bob "grafman" Free (grafman@grafcomp.com)'
          )
        : ()
    ),
);
