## xrt3d.t is a test script for the graphing package Graph.pm
##
## $Id: xrt3d.t,v 1.2 1999/04/27 01:53:19 mhyoung Exp $ $name$
##
## This software product is developed by Michael Young and David Moore,
## and copyrighted(C) 1998 by the University of California, San Diego
## (UCSD), with all rights reserved. UCSD administers the CAIDA grant,
## NCR-9711092, under which part of this code was developed.
##
## There is no charge for this software. You can redistribute it and/or
## modify it under the terms of the GNU General Public License, v. 2 dated
## June 1991 which is incorporated by reference herein. This software is
## distributed WITHOUT ANY WARRANTY, IMPLIED OR EXPRESS, OF MERCHANTABILITY
## OR FITNESS FOR A PARTICULAR PURPOSE or that the use of it will not
## infringe on any third party's intellectual property rights.
##
## You should have received a copy of the GNU GPL along with this program.
##
## Contact: graph-request@caida.org
##
use t::Config;
use Chart::Graph qw(gnuplot xrt3d);
use strict;
use File::Basename;

$Chart::Graph::debug = 0; 
$Chart::Graph::xrt = $t::Config::xrt3d;
$Chart::Graph::xvfb = $t::Config::xvfb;

# assign $PNAME to the actual program name
# $script_path is the path to the directory the script is in
use vars qw($script_name $script_path $script_suffix $PNAME);

($script_name, $script_path, $script_suffix) = fileparse($0, ".pl");
$PNAME = "$script_name$script_suffix";

#
#
# test script for the xrt3d package
#
#
print "1..1\n";

my @drivers = @t::Config::drivers;
my $test_xrt3d = 0;

for (@drivers) {
   if ($_ eq "xrt3d") {
	$test_xrt3d = 1;
    }
}

if ($test_xrt3d) {
    if (xrt3d({"x-ticks"=>["a", "b", "c"],
	       "y-ticks"=>["w", "x", "y", "z"],},
	      [["10", "15", "23", "10"],
	       ["4", "13", "35", "45"],
	       ["29", "15", "64", "24"]])) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok\n";
}

