############################################################
#
# OpenGL::Modern::Image - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Modern::Image;
use strictures;
use Carp;
use Capture::Tiny 'capture';
use vars qw($VERSION @ISA);

require Exporter;
$VERSION = '1.03';
@ISA     = qw(Exporter);

# Return hashref of installed imaging engines
# Use OpenGL/Image/Engines.lst if exists
sub GetEngines {
    my $dir = __FILE__;
    return if ( $dir !~ s|\.pm$|| );

    my @engines;

    # Use engine list if exists
    my $list = "$dir/Engines.lst";
    if ( open( my $LIST, $list ) ) {
        foreach my $engine ( <$LIST> ) {
            $engine =~ s|[\r\n]+||g;
            next if ( !-e "$dir/$engine.pm" );
            push( @engines, $engine );
        }
        close( $LIST );
    }

    # Otherwise grab OpenGL/Image modules
    elsif ( opendir( my $DIR, $dir ) ) {
        foreach my $engine ( readdir( $DIR ) ) {
            next if ( $engine !~ s|\.pm$|| );
            push( @engines, $engine );
        }
        closedir( $DIR );

        # Targa engine gets priority when no Engines.lst exists
        @engines = ( ( grep { $_ eq 'Targa' } @engines ), grep { $_ ne 'Targa' } @engines );
    }
    return if ( !@engines );

    my @info;
    my $engines  = {};
    my $priority = 1;
    foreach my $engine ( @engines ) {
        next if ( $engine eq 'Common' );
        my $info = HasEngine( $engine );
        next if ( !$info );

        if ( wantarray ) {
            push( @info, $info );
        }
        else {
            $info->{priority} = $priority++;
            $engines->{$engine} = $info;
        }
    }

    return wantarray ? @info : $engines;
}

# Check for engine availability; returns installed version
sub HasEngine {
    my ( $engine, $min_ver, $max_ver ) = @_;
    return if ( !$engine );

    my ( $version, $desc );
    my $module = GetEngineModule( $engine );

    capture {
        my $exec = qq{
            use $module;
            \$version = $module\::EngineVersion();
            \$desc = $module\::EngineDescription();
        };
        eval( $exec );
    };

    return if ( !$version );
    return if ( $min_ver && $version lt $min_ver );
    return if ( $max_ver && $version gt $max_ver );

    my $info = {};
    $info->{name}        = $engine;
    $info->{module}      = $module;
    $info->{version}     = $version;
    $info->{description} = $desc;

    return $info;
}

# Get module name for engine
sub GetEngineModule {
    my ( $engine ) = @_;
    return if ( !$engine );
    return __PACKAGE__ . "::$engine";
}

# Constructor wrapper for imaging engine
sub new {
    my $this  = shift;
    my $class = ref( $this ) || $this;
    my $self  = {};
    bless( $self, $class );

    my %params = @_;
    my $engine = $params{engine};
    if ( $engine ) {
        return if ( $engine eq 'Common' );
        return NewEngine( $engine, %params );
    }

    my @engines = GetEngines();
    foreach my $info ( @engines ) {
        my $obj = NewEngine( $info->{name}, %params );
        return $obj if ( $obj );
    }
    return undef;
}

# Instantiate engine
sub NewEngine {
    my ( $engine, %params ) = @_;
    return undef if ( !$engine );

    my $obj;
    my $module = GetEngineModule( $engine );

    my $exec = qq
  {
    use $module;
    \$obj = new $module\(\%params);
  };
    eval( $exec );

    return $obj;
}

1;

__END__

=head1 NAME

  OpenGL::Modern::Image - v1.03 copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com
  Contributor: Geoff Broadwell

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This module is an extensible wrapper to abstract imaging interfaces

  By default, this module uses the OpenGL::Modern::Image::Targa module; support for
  other imaging libraries may be added by providing plug-in modules
  in the OpenGL/Image folder.

  An OpenGL::Modern::Image::Magick module is also provided for use with
  PerlMagick.  For best performance, ImageMagick 6.3.5 or newer should
  be installed.


=head1 SYNOPSIS

  ##########
  # Check for installed imaging engines
  use OpenGL::Modern::Image;

  # Get hashref of installed imaging engines
  # Keys are engine names; values are info hashes, including version,
  # priority (1 .. n, 1 is highest), module (Perl module name)
  # and description.
  # Priority can be set using Engines.lst (see INSTALL); otherwise
  # 'Targa' has top priority, and others are in unspecified order.
  my $engine_hashref = OpenGL::Modern::Image::GetEngines();

  # In list context, returns list of info hashes sorted by engine
  # priority; info hash does not include a priority value.
  my @sorted_engine_info = OpenGL::Modern::Image::GetEngines();

  # Check for a specific engine and optional version support
  # Returns an info hashref for the engine if available; otherwise undef.
  my $info_hashref = OpenGL::Modern::Image::HasEngine('Magick','6.3.5');


  ##########
  # Load texture - defaults to highest priority engine if none specified;
  # if Engines.lst is not specified, the highest priority is the Targa engine.
  my $tex = new OpenGL::Modern::Image(source=>'test.tga');

  # Get GL info
  my($ifmt,$fmt,$type) = $tex->Get('gl_internalformat','gl_format','gl_type');
  my($w,$h) = $tex->Get('width','height');

  # Test if power of 2
  if (!$tex->IsPowerOf2()) return;

  # Set texture  
  glTexImage2D_c(GL_TEXTURE_2D, 0, $ifmt, $w, $h, 0, $fmt, $type, $tex->Ptr());


  ##########
  # Modify GL frame using ImageMagick
  my $frame = new OpenGL::Modern::Image(engine=>'Magick',width=>$w,height=>$h);

  # Get default GL info
  my($def_fmt,$def_type) = $tex->Get('gl_format','gl_type');

  # Read frame pixels
  glReadPixels_c(0, 0, $width, $height, $def_fmt, $def_type, $frame->Ptr());

  # Sync native image buffer
  # Must use this prior to making native calls
  $frame->Sync();

  # Modify frame pixels
  $frame->Native->Blur();

  # Sync OGA
  # Must use this atfer all native calls are done
  $frame->SyncOGA();

  # Draw back to frame
  glDrawPixels_c(0, 0, $width, $height, $def_fmt, $def_type, $frame->Ptr());


  ##########
  # Save GL frame
  my $image = new OpenGL::Modern::Image(width=>$width,height=>$height);

  # Read frame pixels
  glReadPixels_c(0, 0, $width, $height, $def_fmt, $def_type, $image->Ptr());

  # Save file - automatically does a Sync before write
  $image->Save('MyImage.tga');


  ##########
  # Get/Set normalized pixels

  my($r,$g,$b,$a) = $img->GetPixel($x,$y);

  $img->SetPixel($x,$y, 1.0, 0.5, 0.0, 1.0);

  # Sync cache after done modifying pixels
  $frame->Sync();


  ##########
  # Methods defined in OpenGL::Modern::Image::Common:

  # Get native engine object
  my $obj = $img->Native;
  $obj->Quantize() if ($obj);

  # Alternately (Assuming the native engine supports Blur):
  $img->Native->Blur();

  # Test if image width is a power of 2
  if ($img->IsPowerOf2());

  # Test if all listed values are a power of 2
  if ($img->IsPowerOf2(@list));

  # Get largest power of 2 size within dimensions of image
  my $size = $img->GetPowerOf2();

  # Get one or more parameter values
  my @values = $img->Get(@params);

  # Return the image's cache as an OpenGL::Array object.
  # Note: OGA may change after a cache update
  my $oga = $img->GetArray();

  # Return a C pointer to the image's cache.
  # For use with OpenGL's "_c" APIs.
  # Note: pointer may change after a cache update
  $img->Ptr();


  ##########
  # Supported parameters:

  # version - version of the engine
  # source - source image, if defined
  # width - width of image in pixels
  # height - height of image in pixels
  # pixels - number of pixels
  # components - number of pixel components
  # size - bytes per component
  # length - cache size in bytes
  # endian - 1 if big endian; otherwise 0
  # alpha - 1: normal alpha channel, -1: inverted alpha channel; 0: none
  # flipped - 1 bit set if cache ordered top to bottom; others reserved
  # gl_internalformat - internal GL pixel format. eg: GL_RGBA8, GL_RGBA16
  # gl_format - GL pixel format. eg: GL_RGBA, GL_BGRA
  # gl_type - GL data type.  eg: GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT


  ##########
  # APIs and Methods defined in engine modules:

  # Get engine version
  my $ver = OpenGL::Modern::Image::ENGINE_MODULE::EngineVersion();

  # Sync the image cache after a write.
  # Used by some engines for paged caches; otherwise a NOP.
  $img->Sync();

  # Save the image to a PNG file (assuming the engine supports PNGs)
  $img->Save('MyImage.png');

  # Get image blob.
  my $blob = $img->GetBlob();

=cut
