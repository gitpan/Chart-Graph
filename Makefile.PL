use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use strict;

my @xrt3d = "undef"; 
my $xrt3d;
my @xvfb = "undef";
my $xvfb;
my @drivers = qw(gnuplot xrt3d);
print "Enter (space seperated) graphing drivers to test: [@drivers] ";
my $drivers = <STDIN>;
chop $drivers;
@drivers = split /\s/,$drivers if $drivers ne '';

for (@drivers) {
    if($_ eq "xrt3d") {
        print "Enter path to xrt3d binary (built from xrt3d/): ";
        $xrt3d = <STDIN>;
	chop $xrt3d;
	@xrt3d = $xrt3d;
        print "Enter path to X virtual frame buffer(Xvfb): "; 
        $xvfb = <STDIN>; 
        chop $xvfb; 
        @xvfb = $xvfb; 
    }
}	

my $config = 't/Config.pm';
open(CONFIG,">$config") || die "Couldn't open config file: $config: $!";
print STDERR "Writing config file: $config\n";
print CONFIG qq{
package t::Config;
\@drivers    = qw(@drivers);
\$xrt3d      = "@xrt3d";
\$xvfb      = "@xvfb";

1;
};

close CONFIG;

WriteMakefile(
	      'NAME'      => 'Chart::Graph',
	      'VERSION_FROM' => 'Graph.pm', # finds $VERSION
	      dist => {
		       TARFLAGS => 'cvf',
		       COMPRESS => 'gzip',
		       SUFFIX => 'gz',
		      }
	     );
