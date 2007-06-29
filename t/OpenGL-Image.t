#!/usr/bin/perl -w
use strict;

# Image used for testing
my $src_image = 'test.png';
my $dst_image = 'test.jpg';
my $width = 128;
my $height = 128;

# Init tests
my $t = new MyTests(15,'Testing OpenGL::Image');


#1 Get module version
my $ogi_ver;
my $exec = qq
{
  use OpenGL::Image;
  \$ogi_ver = \$OpenGL::Image::VERSION;
};
eval($exec);
$t->bail("OpenGL::Image failed to load: $@") if ($@ || !$ogi_ver);
$t->ok("OpenGL::Image module loaded: v$ogi_ver");


#2 Get OpenGL version
my $has_pogl = 0;
my $pogl_ver = 0;
$exec = qq
{
  use OpenGL;
  \$pogl_ver = \$OpenGL::VERSION;
};
eval($exec);
$t->status("OpenGL module not installed: $@") if ($@ || !$pogl_ver);
if ($pogl_ver lt '0.5503')
{
  $t->skip("Requires OpenGL 0.55_03 or newer to use");
}
else
{
  use OpenGL(':all');
  $has_pogl = 1;
  $t->ok("OpenGL module installed: v$pogl_ver");
}


#3 Get ImageMagick version
my $im_ver = 0;
$exec = qq
{
  use Image::Magick;
  \$im_ver = \$Image::Magick::VERSION;
};
eval($exec);
if ($@ || !$im_ver)
{
  $t->skip("Image::Magick module not installed: $@") 
}
elsif ($im_ver lt '6.3.5' )
{
  $t->skip("Image::Magick module installed: v$im_ver - recommend 6.3.5 or newer");
}
else
{
  $t->ok("Image::Magick module installed: v$im_ver");
}


#4 Enumerate installed engines
$t->status("Testing OpenGL::Image::GetEngines():");
my $engines = OpenGL::Image::GetEngines();
my @engines = keys(%$engines);
$t->bail("No imaging engines installed!") if (!scalar(@engines));
my $had_engine = 0;
my $has_IM = 0;
foreach my $engine (sort @engines)
{
  $t->status("  $engine: ".$engines->{$engine});
  $has_IM = 1 if ($engine eq 'Magick');
}
$t->status('Magick is ' . ($has_IM ? '' : 'NOT ') . "installed");
$t->ok("At least one imaging engine is installed");


#5 Test HasEngine()
my $engine_ver = OpenGL::Image::HasEngine($engines[0]);
if ($engine_ver)
{
  $t->ok("HasEngine('$engines[0]') returned '$engine_ver'")
}
else
{
  $t->fail("HasEngine('$engines[0]') failed to return a version");
}


# Test module
my $has_image = -e $src_image;
$t->status("Test image '$src_image' not found") if (!$has_image);

if ($has_pogl && $has_image)
{
  #6 Test OpenGL::Array
  my $oga = OpenGL::Array->new_list(GL_UNSIGNED_BYTE,1,2,3,4);
  if (!$oga)
  {
    $t->bail("Unable to instantiate OpenGL::Array");
  }
  elsif (4 != $oga->elements())
  {
    $t->bail("OpenGL::Array returned invalid element count");
  }
  $t->ok("Instantiated OpenGL::Array");


  #7 Test image loading
  my $img = new OpenGL::Image(source=>$src_image);
  $t->bail("Unable to instantiate OpenGL::Image") if (!$img);
  $t->ok("Instantiated OpenGL::Image");


  #8 Test image parameters
  my $params = $img->Get();
  my @params = keys(%$params);
  if (scalar(@params))
  {
    $t->status("Testing object parameters:");
    foreach my $key (sort @params)
    {
      $t->status("  $key: ".$params->{$key});
    }
    $t->ok("Get() returned parameters");
  }
  else
  {
    $t->fail("Get() failed to return a parameter hashref");
  }


  #9 Test image size
  my($w,$h,$p,$c,$s) = $img->Get('width','height','pixels','components','size');
  if ($w != $width || $h != $height)
  {
    $t->fail("Get('width','height') returned invalid dimensions: $w x $h");
  }
  elsif($p != $w * $h)
  {
    $t->fail("Get('pixels') failed to return $w x $h: $p");
  }
  else
  {
    $t->ok("Get('width','height','pixels') returned: $w x $h = $p");
  }


  #10 Test IsPowerOf2()
  if (!$img->IsPowerOf2(256))
  {
    $t->fail("IsPowerOf2(256) returned false");
  }
  elsif ($img->IsPowerOf2(13))
  {
    $t->fail("IsPowerOf2(13) returned true");
  }
  elsif (!$img->IsPowerOf2())
  {
    $t->fail("IsPowerOf2() returned false");
  }
  else
  {
    $t->ok("IsPowerOf2() returned true");
  }


  #11 Test GetArray()
  $oga = $img->GetArray();
  $t->bail("GetArray() failed to return an OpenGL::Array object") if (!$oga);
  my $elements = $oga->elements();
  if ($elements != $p * $c)
  {
    $t->bail("GetArray() contains invalid number of elements: $elements");
  }
  $t->ok("GetArray() contains $elements elements");


  #12 Test Ptr()
  if ($oga->ptr() && $oga->ptr() != $img->Ptr())
  {
    $t->bail("Ptr() returned invalid pointer");
  }
  $t->ok("Ptr() returned a valid pointer");


  if ($has_IM)
  {
    #13 Test Ptr()
    $t->bail("Native() returned invalid PerlMagick object") if (!$img->Native());

    my($x,$y) = $img->Native->Get('width','height');
    if ($x != $w || $y != $h)
    {
      $t->bail("Native->Get('width','height') returned invalid dimensions");
    }
    $t->ok("Native->Get('width','height') returned: $x x $y");


    #14 Test GetBlob()
    my $blob = $img->GetBlob(magick=>'jpg');
    $t->bail("GetBlob(type=>'jpg') failed to return a blob") if (!$blob);

    my $im = Image::Magick->new(magick=>'jpg');
    $im->BlobToImage($blob);
    my($w0,$h0) = $im->Get('width','height');
    if (!$w0 || !$h0)
    {
      $t->bail("GetBlob(type=>'jpg') failed");
    }
    elsif ($w != $w0 || $h != $h0)
    {
      $t->bail("GetBlob(type=>'jpg') returns invalid dimensions: $w0 x $h0");
    }
    $t->ok("GetBlob(type=>'jpg') returned a blob of length: ".length($blob));


    #15 Test Save()
    $img->Save($dst_image);
    $t->bail("Save('$dst_image') failed to create file") if (!-e $dst_image);
    $t->ok("Save('$dst_image') created image... now deleting");
    unlink($dst_image);
  }
  else
  {
    $t->skip("#13 - No ImageMagick");
    $t->skip("#14 - No ImageMagick");
    $t->skip("#15 - No ImageMagick");
  }
}
else
{
  $t->skip("#6 - No OpenGL");
  $t->skip("#7 - No OpenGL");
  $t->skip("#8 - No OpenGL");
  $t->skip("#9 - No OpenGL");
  $t->skip("#10 - No OpenGL");
  $t->skip("#11 - No OpenGL");
  $t->skip("#12 - No OpenGL");
  $t->skip("#13 - No OpenGL");
  $t->skip("#14 - No OpenGL");
  $t->skip("#15 - No OpenGL");
}

$t->done();
exit 0;






package MyTests;
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {count=>0};
  bless($self,$class);

  my($tests,$title) = @_;
  print "1..$tests\n";
  $self->status("\n________________________________________");
  $self->status($title);
  $self->status("----------------------------------------");

  return $self;
}
sub status
{
  my($self,$msg) = @_;
  print STDERR "$msg\n";
}
sub ok
{
  my($self,$msg) = @_;
  $self->status("* ok: $msg");
  print 'ok '.++$self->{count}."\n";
}
sub skip
{
  my($self,$msg) = @_;
  $self->status("* skip: $msg");
  print 'ok '.++$self->{count}." \# skip $msg\n";
}
sub fail
{
  my($self,$msg) = @_;
  $self->status("* fail: $msg");
  print 'not ok '.++$self->{count}."\n";
}
sub bail
{
  my($self,$msg) = @_;
  $self->status("* bail: $msg\n");
  print "Bail out!\n";
  exit 0;
}
sub done
{
  my($self) = @_;
  $self->status("________________________________________");
}

__END__
