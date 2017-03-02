requires 'strictures'     => 0;
requires 'Carp'           => 0;
requires 'OpenGL::Modern' => 0;
requires 'OpenGL::Array'  => 0;
requires 'Capture::Tiny'  => 0;

on configure => sub {
    requires 'ExtUtils::MakeMaker'           => '6.17';
    requires 'ExtUtils::MakeMaker::CPANfile' => 0;
};

on test => sub {
    requires 'Test::More'      => '0.88';
    requires 'IO::All'         => 0;
    requires 'Test::InDistDir' => 0;
};
