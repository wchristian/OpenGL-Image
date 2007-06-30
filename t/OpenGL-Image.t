#!/usr/bin/perl -w
use strict;

# Image used for testing
my $src_image = 'test.png';
my $dst_image = 'test.jpg';
my $tga_image = 'test.tga';
my $width = 128;
my $height = 128;
my $deviation = 0.01;

# Init tests
my $t = new MyTests(27,'Testing OpenGL::Image');


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
  use OpenGL\(':all');
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
my $has_TGA = 0;
my $has_IM = 0;
my $has_IM635 = 0;
foreach my $engine (sort @engines)
{
  $t->status("  $engine: ".$engines->{$engine});
  if ($engine eq 'Targa')
  {
    $has_TGA = 1;
  }
  elsif ($engine eq 'Magick')
  {
    $has_IM = 1;
    $has_IM635 = $engines->{'Magick'} ge '6.3.5';
  }
}
$t->status('Targa is ' . ($has_TGA ? '' : 'NOT ') . "installed");
$t->status('Magick is ' . ($has_IM ? '' : 'NOT ') . "installed");
$t->ok("At least one imaging engine is installed");


#5 Test HasEngine()
my $engine_ver = OpenGL::Image::HasEngine($engines[0]);
$t->bail("HasEngine('$engines[0]') failed to return a version") if (!$engine_ver);
$t->ok("HasEngine('$engines[0]') returned '$engine_ver'");


# Skip the rest if no POGL
if (!$has_pogl)
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
  $t->skip("#16 - No OpenGL");
  $t->skip("#17 - No OpenGL");
  $t->skip("#18 - No OpenGL");
  $t->skip("#19 - No OpenGL");
  $t->skip("#20 - No OpenGL");
  $t->skip("#21 - No OpenGL");
  $t->skip("#22 - No OpenGL");
  $t->skip("#23 - No OpenGL");
  $t->skip("#24 - No OpenGL");
  $t->skip("#25 - No OpenGL");
  $t->skip("#26 - No OpenGL");
  $t->skip("#27 - No OpenGL");

  $t->done();
  exit 0;
}


#6 Test OpenGL::Array
my $oga = OpenGL::Array->new_list(GL_UNSIGNED_BYTE,1,2,3,4);
$t->bail("Unable to instantiate OpenGL::Array") if (!$oga);
$t->bail("OpenGL::Array returned invalid element count") if (4 != $oga->elements());
$t->ok("Instantiated OpenGL::Array");


#7 Test image object instantiation
my $tga = new OpenGL::Image(width=>$width,height=>$height);
$t->bail("Unable to instantiate OpenGL::Image") if (!$tga);
$t->ok("Instantiated OpenGL::Image(width\=>$width,height\=>$height)");


#8 Test Get/Set Pixel
$tga->SetPixel(0,0, 0.1, 0.2, 0.3, 0.4);
my($v0,$v1,$v2,$v3) = $tga->GetPixel(0,0);

# Normalized values introduce rounding errors
my $dev = (abs($v0 - 0.1) + abs($v1 - 0.2) + abs($v2 - 0.3) + abs($v3 - 0.4)) / 4;
#$t->status("Get/SetPixel deviation: $dev");
if ($dev > $deviation)
{
  $t->bail("GetPixel failed to return values used with SetPixel");
}
$t->ok("GetPixel returns valid values used with SetPixel");


# set up test pixels
my @pixels = ();
my $x0 = 1.0 / $width;
my $y0 = 1.0 / $height;
my $r = 1.0;
my $g = 0.0;
for (my $y=0; $y<$height; $y++)
{
  $b = 1.0;
  $a = 0.0;
  for (my $x=0; $x<$width; $x++)
  {
    push(@pixels,[$x,$y, $r,$g,$b,$a]);
    $b -= $x0;
    $a += $x0;
  }
  $r -= $y0;
  $g += $y0;
}

foreach my $pixel (@pixels)
{
  $tga->SetPixel(@$pixel);
}


#9 Test image saving
$tga->Save($tga_image);
$t->bail("Save('$tga_image') failed to create $tga_image") if (!-e $tga_image);
$t->ok("Save('$tga_image') created image");


#10 Test image loading
my $sav = new OpenGL::Image(source=>$tga_image);
$t->bail("Unable to instantiate OpenGL::Image") if (!$sav);
$t->ok("Instantiated OpenGL::Image(source=>'$tga_image')");
unlink($tga_image);


#11 Test image parameters
my $params = $sav->Get();
$t->fail("Get() failed to return a parameter hashref") if (!$params);
my @params = keys(%$params);
$t->fail("Get() failed to return parameters") if (!scalar(@params));

$t->status("Testing object parameters:");
foreach my $key (sort @params)
{
  $t->status("  $key: ".$params->{$key});
}
$t->ok("Get() returned parameters");


#12 Test image size
my($w,$h,$p,$c,$s) = $sav->Get('width','height','pixels','components','size');
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


#13 Test pixel deviation
my $d = 0;
my $i = 0;
for (my $y=0; $y<$height; $y++)
{
  for (my $x=0; $x<$width; $x++)
  {
     my($r,$g,$b,$a) = $sav->GetPixel($x,$y);
     my $pixel = $pixels[$i++];
     $d += abs($r - (@$pixel)[2]);
     $d += abs($g - (@$pixel)[3]);
     $d += abs($b - (@$pixel)[4]);
     $d += abs($a - (@$pixel)[5]);
  }
}

$d /= ($i * 4);
if ($d > $deviation)
{
  $t->fail("Set/Get Pixels deviation out of range: $d")
}
elsif ($d)
{
  $t->ok("Set/Get Pixels within acceptable deviation: $d");
}
else
{
  $t->ok("Set/Get Pixels resulted in no deviation");
}


#14 Test IsPowerOf2()
if (!$sav->IsPowerOf2(256))
{
  $t->fail("IsPowerOf2(256) returned false");
}
elsif ($sav->IsPowerOf2(13))
{
  $t->fail("IsPowerOf2(13) returned true");
}
elsif (!$sav->IsPowerOf2())
{
  $t->fail("IsPowerOf2() returned false");
}
else
{
  $t->ok("IsPowerOf2() returned true");
}


#15 Test GetArray()
$oga = $sav->GetArray();
$t->bail("GetArray() failed to return an OpenGL::Array object") if (!$oga);
my $elements = $oga->elements();
if ($elements != $p * $c)
{
  $t->bail("GetArray() contains invalid number of elements: $elements");
}
$t->ok("GetArray() contains $elements elements");


#16 Test Ptr()
if ($oga->ptr() && $oga->ptr() != $sav->Ptr())
{
  $t->bail("Ptr() returned invalid pointer: ".$oga->ptr().', '.$sav->Ptr())."\n";
}
$t->ok("Ptr() returned a valid pointer");


#17 Test GetBlob()
my $blob = $sav->GetBlob();
$t->bail("GetBlob() failed to return blob\n") if (!$blob);
my $blob_len = length($blob);

if ('Targa' eq $sav->Get('engine'))
{
  if ($blob_len != $p * $c * $s)
  {
    $t->bail("GetBlob() returned invalid blob length: $blob_len\n");
  }
}
$t->ok("GetBlob() returned a blob of length: $blob_len");


# Test Magick engine
my $has_image = -e $src_image;
if (!$has_IM || !$has_image)
{
  my $msg = $has_IM ? "Test image '$src_image' not found" : 'No ImageMagick';

  $t->skip("#18 - $msg");
  $t->skip("#19 - $msg");
  $t->skip("#20 - $msg");
  $t->skip("#21 - $msg");
  $t->skip("#22 - $msg");
  $t->skip("#23 - $msg");
  $t->skip("#24 - $msg");
  $t->skip("#25 - $msg");
  $t->skip("#26 - $msg");
  $t->skip("#27 - $msg");

  $t->done();
  exit 0;
}


#18 Test Loading source image
my $src = new OpenGL::Image(engine=>'Magick',source=>$src_image);
$t->bail("Unable to instantiate OpenGL::Image(engine=>'Magick',source=>'$src_image')") if (!$src);
$t->ok("Instantiated OpenGL::Image(engine=>'Magick',source=>'$src_image')");


#19 Test source image size
my($ws,$hs,$ps,$cs,$ss) = $src->Get('width','height','pixels','components','size');
if ($ws != $width || $hs != $height)
{
  $t->fail("Get('width','height') returned invalid dimensions: $ws x $hs");
}
elsif($ps != $ws * $hs)
{
  $t->fail("Get('pixels') failed to return $ws x $hs: $ps");
}
else
{
  $t->ok("Get('width','height','pixels') returned: $ws x $hs = $ps");
}


#20 Test Save()
$src->Save($dst_image);
$t->bail("Save('$dst_image') failed to create file") if (!-e $dst_image);
$t->ok("Save('$dst_image') created image");


#21 Test Loading destination image
my $dst = new OpenGL::Image(engine=>'Magick',source=>$dst_image);
$t->bail("Unable to instantiate OpenGL::Image(engine=>'Magick',source=>'$dst_image')") if (!$dst);
$t->ok("Instantiated OpenGL::Image(engine=>'Magick',source=>'$dst_image')");
unlink($dst_image);


#22 Test destination image size
my($wd,$hd,$pd,$cd,$sd) = $dst->Get('width','height','pixels','components','size');
if ($wd != $ws || $hd != $hs)
{
  $t->fail("Get('width','height') returned invalid dimensions: $wd x $hd");
}
elsif($pd != $wd * $hd)
{
  $t->fail("Get('pixels') failed to return $wd x $hd: $pd");
}
else
{
  $t->ok("Get('width','height','pixels') returned: $wd x $hd = $pd");
}


#23 Test RGB deviation
$d = 0;
for (my $y=0; $y<$height; $y++)
{
  for (my $x=0; $x<$width; $x++)
  {
     my($rs,$gs,$bs,$as) = $src->GetPixel($x,$y);
     my($rd,$gd,$bd,$ad) = $dst->GetPixel($x,$y);
     $d += abs($rs-$rd) + abs($gs-$gd) + abs($bs-$bd);
  }
}

$d /= ($ps * 3);
if ($d > $deviation)
{
  $t->fail("Set/Get Pixels deviation out of range: $d")
}
elsif ($d)
{
  $t->ok("Set/Get Pixels within acceptable deviation: $d");
}
else
{
  $t->ok("Set/Get Pixels resulted in no deviation");
}


#24 Test Native()
$t->bail("Native() returned invalid PerlMagick object") if (!$src->Native());
my($x,$y) = $src->Native->Get('width','height');
if ($x != $w || $y != $h)
{
  $t->bail("Native->Get('width','height') returned invalid dimensions");
}
$t->ok("Native->Get('width','height') returned: $x x $y");


#25 Test GetBlob()
$blob = $src->GetBlob(magick=>'jpg');
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


#26 Test GetArray()
$oga = $src->GetArray();
$t->bail("GetArray() failed to return an OpenGL::Array object") if (!$oga);
$elements = $oga->elements();
if ($elements != $p * $c)
{
  $t->bail("GetArray() contains invalid number of elements: $elements");
}
$t->ok("GetArray() contains $elements elements");


#27 Test Ptr()
if ($oga->ptr() && $oga->ptr() != $src->Ptr())
{
  $t->bail("Ptr() returned invalid pointer: ".$oga->ptr().', '.$src->Ptr())."\n";
}
$t->ok("Ptr() returned a valid pointer");


# Test IM 6.3.5 APIs
if (!$has_IM635)
{
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
