#!/usr/local/bin/perl -w 
## gnuplot.t is a test script for the graphing package Graph.pm
##
## $Id: gnuplot.t,v 1.1 1999/04/27 01:49:19 mhyoung Exp $ $name$
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

# assign $PNAME to the actual program name
# $script_path is the path to the directory the script is in
use vars qw($script_name $script_path $script_suffix $PNAME);

($script_name, $script_path, $script_suffix) = fileparse($0, ".pl");
$PNAME = "$script_name$script_suffix";

use vars qw($package);


#
#
# test script for the gnuplot package
#
#
print "1..1\n";

my @drivers = @t::Config::drivers;
my $test_gnuplot = 0;

for (@drivers) {
   if ($_ eq "gnuplot") {
	$test_gnuplot = 1;
    }
}

if ($test_gnuplot) {
    if (gnuplot({"title" => "foo",
	     "x2-axis label" => "bar",
	     "logscale x2" => "1",
	     "logscale y" => "1",
	     "xtics" => [ ["small\\nfoo", 10], 
			  ["medium\\nfoo", 20], 
			  ["large\\nfoo", 30]],
	     "ytics" => [10,20,30,40,50]},
	    [{"title" => "data1",
	      "type" => "matrix"}, 
	     [[1, 10], 
	      [2, 20], 
	      [3, 30]] ],
	    [{"title" => "data2", 
	      "style" => "lines",
	      "type" => "columns"}, 
	     [8, 26, 50, 60, 70], 
	     [5, 28, 50, 60, 70] ],
	    [{"title" => "data3",
	      "style" => "lines",
	      "type" => "file"}, 
	     "sample"],)) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok\n";
}
