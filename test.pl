#!/usr/local/bin/perl -w 
## test_Graph.pl is a test script for the graphing package Graph.pm
##  
##
## USAGE: ./test_Graph <package>
##
## $Id: test_Graph.pl,v 1.7 1999/04/01 01:54:12 mhyoung Exp $ $name$
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
## Contact: dmoore@caida.org
##

use Chart::Graph;
use strict;
use File::Basename;

$Chart::Graph::debug = 0; 
$Chart::Graph::xrt = "/home/mhyoung/workspace/mhyoung/graph/graph";
#$Chart::Graph::xwdtopnm = " /usr/local/bin/xwdtopnm";    
$Chart::Graph::xvfb = "/ipn/dmoore/bin/Xvfb";

# assign $PNAME to the actual program name
# $script_path is the path to the directory the script is in
use vars qw($script_name $script_path $script_suffix $PNAME);

($script_name, $script_path, $script_suffix) = fileparse($0, ".pl");
$PNAME = "$script_name$script_suffix";

use vars qw($package);

## Check command-line arguments
if (@ARGV != 1) { 
    print STDERR " Invalid number of command-line arguments.\n";
    print STDERR " Usage: ${PNAME} <package>\n\n";
    exit(0);
}

$package = $ARGV[0];

#
#
# test script for the graph package
#
#

if ($package eq "gnuplot") {

    gnuplot({"title" => "foo",
	     "x2-axis label" => "bar",
	     "logscale x2" => "1",
	     "logscale y" => "1",
	     "xtics" => [ ["small\\nfoo", 10], ["medium\\nfoo", 20], ["large\\nfoo", 30]],
	     "ytics" => [10,20,30,40,50]},
	    [{"title" => "data1",
	      "type" => "matrix"}, [[1, 10], 
				    [2, 20], 
				    [3, 30]] ],
	    [{"title" => "data2", 
	      "style" => "lines",
	      "type" => "columns"}, [8, 26, 50, 60, 70], 
	     [5, 28, 50, 60, 70] ],
	    [{"title" => "data3",
	      "style" => "lines",
	      "type" => "file"}, "sample"],);


} elsif ($package eq "xrt") { 


    xrt({"x-ticks"=>["a", "b", "c"],
	 "y-ticks"=>["w", "x", "y", "z"],},
	[["10", "15", "23", "10"],
	 ["4", "13", "35", "45"],
	 ["29", "15", "64", "24"]]);

#    xrt({},
#	[["10", "15", "23", "10"],
#	 ["4", "13", "35", "45"],
#	 ["29", "15", "64", "24"]]);
}
