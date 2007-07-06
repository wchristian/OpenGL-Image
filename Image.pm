############################################################
#
# OpenGL::Image - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Image;

require Exporter;

use Carp;

use vars qw($VERSION @ISA);
$VERSION = '1.00';

@ISA = qw(Exporter);


=head1 NAME

  OpenGL::Image - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This module is an extensible wrapper to abstract imaging interfaces

  By default, this module uses the Image::Magick module; support for
  other imaging libraries may be added by providing plug-in modules
  in the OpenGL/Image folder.

  For the best performance, ImageMagick 6.3.5 or newer should be installed.


=head1 SYNOPSIS


  ##########
  # Check for installed imaging engines
  use OpenGL::Image;

  # Get hashref of installed imaging engines
  # Keys are engine names; values are versions
  my $engines = OpenGL::Image::GetEngines();

  # Check for a specific engine and optional version support
  my $ok = OpenGL::Image::HasEngine('Magick','6.3.5');


  ##########
  # Load texture (engine defaults to Image::Targa if not specified)
  my $tex = new OpenGL::Image(source=>'test.tga');

  # Get GL info
  my($ifmt,$fmt,$type) = $tex->Get('gl_internalformat','gl_format','gl_type');
  my($w,$h) = $tex->Get('width','height');

  # Test if power of 2
  if (!$tex->PowerOf2()) return;

  # Set texture  
  glTexImage2D_c(GL_TEXTURE_2D, 0, $ifmt, $w, $h, 0, $fmt, $type, $tex->Ptr());


  ##########
  # Modify GL frame using ImageMagick
  my $frame = new OpenGL::Image(engine=>'Magick',width=>$width,height=>$height);

  # Get default GL info
  my($def_fmt,$def_type) = $tex->Get('gl_format','gl_type');

  # Read frame pixels
  glReadPixels_c(0, 0, $width, $height, $def_fmt, $def_type, $frame->Ptr());

  # Sync cache
  $frame->Sync();

  # Modify frame pixels
  $frame->Native->Blur();

  # Draw back to frame
  glDrawPixels_c(0, 0, $width, $height, $def_fmt, $def_type, $frame->Ptr());


  ##########
  # Save GL frame
  my $image = new OpenGL::Image(width=>$width,height=>$height);

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
  # Methods defined in OpenGL::Image::Common:

  # Get native engine object
  my $obj = $img->Native;
  $obj->Quantize() if ($obj);

  # Alternately (Assuming the native engine supports Blur):
  $img->Native->Blur();

  # Test if image width is a power of 2
  if ($img->IsPowerOf2())

  # Test if all listed values are a power of 2
  if ($img->IsPowerOf2(@list))

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

  # version  version of the engine
  # source - source image, if defined
  # width - width of image in pixels
  # height - height of image in pixels
  # pixels - number of pixels
  # components - number of pixel components
  # size - bytes per component
  # length - cache size in bytes
  # endian - 1 if big endian; otherwise 0
  # alpha - 1 if has alpha channel, -1 if has inverted alpha channel; 0 if none
  # flipped - 1 bit set if cache scanlines are top to bottom; others reserved
  # gl_internalformat - internal GL pixel format. eg: GL_RGBA8, GL_RGBA16
  # gl_format - GL pixel format. eg: GL_RGBA, GL_BGRA
  # gl_type - GL data type.  eg: GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT


  ##########
  # APIs and Methods defined in engine modules:

  # Get engine version
  my $ver = OpenGL::Image::ENGINE_MODULE::EngineVersion();

  # Sync the image cache after a write.
  # Used by some engines for paged caches; otherwise a NOP.
  $img->Sync();

  # Save the image to a PNG file (assuming the native engine supports PNGs).
  $img->Save('MyImage.png');

  # Get image blob.
  my $blob = $img->GetBlob();


=cut



# Return hashref of installed imaging engines
# Use OpenGL/Image/Engines.lst if exists
sub GetEngines
{
  my $dir = __FILE__;
  return undef if ($dir !~ s|\.pm$||);

  @engines = ();
  # Use engine list if exists
  my $list = "$dir/Engines.lst";
  if (open(LIST,$list))
  {
    foreach my $engine (<LIST>)
    {
      $engine =~ s|[\r\n]+||g;
      next if (!-e "$dir/$engine.pm");
      push(@engines,$engine);
    }
    close(LIST);
  }
  # Otherwise grab OpenGL/Image modules
  elsif (opendir(DIR,$dir))
  {
    foreach my $engine (readdir(DIR))
    {
      next if ($engine !~ s|\.pm$||);
      push(@engines,$engine);
    }
    closedir(DIR);
  }
  return undef if (!scalar(@engines));

  $engines = {};
  # Get module versions
  foreach my $engine (@engines)
  {
    next if ($engine eq 'Common');
    my $version = HasEngine($engine);
    next if (!$version);
    $engines->{$engine} = $version;
  }

  return $engines;
}


# Check for engine availability; returns installed version
sub HasEngine
{
  my($engine,$min_ver,$max_var) = @_;
  return undef if (!$engine);

  my $version;
  my $module = GetEngineModule($engine);

  # Redirect Perl errors if module can't be loaded
  open(OLD_STDERR,">&STDERR");
  close(STDERR);

  my $exec = qq
  {
    use $module;
    \$version = $module\::EngineVersion();
  };
  eval($exec);

  # Restore STDERR
  open(STDERR,">&OLD_STDERR");

  return undef if (!$version);
  return undef if ($min_ver && $version lt $min_ver);
  return undef if ($max_ver && $version gt $max_ver);

  return $version;
}


# Get module name for engine
sub GetEngineModule
{
  my($engine) = @_;
  return undef if (!$engine);
  return __PACKAGE__."::$engine";
}


# Constructor wrapper for imaging engine
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless($self,$class);

  my %params = @_;
  my $engine = $params{engine};
  if ($engine)
  {
    return undef if ($engine eq 'Common');
    return NewEngine($engine,%params);
  }

  my $obj = NewEngine('Targa',%params);
  return $obj if ($obj);

  my $engines = GetEngines();
  foreach my $engine (keys(%$engines))
  {
    next if ($engine eq 'Targa');
    $obj = NewEngine($engine,%params);
    return $obj if ($obj);
  }
  return undef;
}


# Instantiate engine
sub NewEngine
{
  my($engine,%params) = @_;
  return undef if (!$engine);

  my $obj;
  my $module = GetEngineModule($engine);

  my $exec = qq
  {
    use $module;
    \$obj = new $module\(\%params);
  };
  eval($exec);

  return $obj;
}


1;
__END__

