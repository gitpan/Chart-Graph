#!/usr/local/bin/perl -w 
## gnuplot.t is a test script for the graphing package Graph.pm
##
## $Id: gnuplot.t,v 1.8 2001/10/24 18:41:09 elagache Exp $ $name$
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

$Chart::Graph::save_tmpfiles = 0;
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
print "1..4\n";

my @drivers = @t::Config::drivers;
my $test_gnuplot = 0;

for (@drivers) {
   if ($_ eq "gnuplot") {
	$test_gnuplot = 1;
    }
}

if ($test_gnuplot) {
    if (gnuplot({"output file" => "test_results/gnuplot1.png",
				 "output type" => "png",
				 "title" => "foo",
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
    print "ok # skip Not available on this platform\n";
}

if ($test_gnuplot) {
    if( gnuplot({"title" => "Examples of Errorbars",
              "xrange" => "[:11]",
              "yrange" => "[:45]",
              "output file" => "test_results/gnuplot2.gif",
	      "output type" => "gif",
             },
             # dataset 1
             [{"title" => "yerrorbars",
               "style" => "yerrorbars",
               "using" => "1:2:3:4",
               "type" => "columns"},
              [ 1, 2, 3, 4, 5, 6 ], # x
              [ 5, 7, 12, 19, 28, 39 ], # y
              [ 3, 5, 10, 17, 26, 38 ], # ylow
              [ 6, 8, 13, 20, 30, 40 ] ], # yhigh
             # dataset 2
             [{"title" => "xerrorbars",
               "style" => "xerrorbars",
               "using" => "1:2:3:4",
               "type" => "columns"},
              [ 4, 5, 6, 7, 8, 9 ], # x
              [ 1, 4, 5, 6, 7, 10 ], # y
              [ 3.3, 4.4, 5.5, 6.6, 7.7, 8.8 ], # xlow
              [ 4.1, 5.2, 6.1, 7.3, 8.1, 10 ] ], # xhigh
             # dataset 3
             [{"title" => "xyerrorbars",
               "style" => "xyerrorbars",
               "using" => "1:2:3:4:5:6",
               "type" => "columns"},
              [ 1.5, 2.5, 3.5, 4.5, 5.5, 6.5 ], # x
              [ 2, 3.5, 7.0, 14, 15, 20 ], # y
              [ 0.9, 1.9, 2.8, 3.7, 4.9, 5.8 ], # xlow
              [ 1.6, 2.7, 3.7, 4.8, 5.6, 6.7 ], # xhigh
              [ 1, 2, 3, 5, 7, 8 ], # ylow
              [ 5, 7, 10, 17, 18, 24 ] ], # yhigh
             # dataset 4
             [{"title" => "xerrorbars w/ xdelta",
               "style" => "xerrorbars",
               "using" => "1:2:3",
               "type" => "columns"},
              [ 4, 5, 6, 7, 8, 9 ], # x
              [ 2.5, 5.5, 6.5, 7.5, 8.6, 11.7 ], # y
              [ .2, .2, .1, .1, .3, .3 ] ], # xdelta
             # dataset 5
             [{"title" => "yerrorbars w/ ydelta",
               "style" => "yerrorbars",
               "using" => "1:2:3",
               "type" => "columns"},
              [ .7, 1.7, 2.7, 3.7, 4.7, 5.7 ], # x
              [ 10, 15, 20, 25, 30, 35 ], # y
              [ .8, 1.2, 1.1, 2.1, 1.3, 3.3 ] ], # ydelta
             # dataset 6
             [{"title" => "dummy data",
               "type" => "matrix"},
              [ [1,1] ]],
             # dataset 7
             [{"title" => "xyerrorbars w/ xydelta",
               "style" => "xyerrorbars",
               "using" => "1:2:3:4",
               "type" => "columns"},
               [ 7.5, 8.0, 8.5, 9.0, 9.5, 10.0 ], # x
               [ 30, 27, 25, 23, 27, 33 ], # y
               [ .2, .1, .3, .6, .4, .3 ], # xdelta
              [ .8, .7, .3, .6, 1.0, .3 ] ], # ydelta
           )

) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}


if ($test_gnuplot) {
    if(gnuplot({"title" => "Corporate stock values for major computer maker",
           "x-axis label" => "Month and Year",
	   "y-axis label" => "Stock price",
	   "output type" => "png",
           "output file" => "test_results/gnuplot3.png",
	   "xdata" => "time",
	   "timefmt" => "%m/%d/%Y",
	   "xrange" => "[\"06/01/2000\":\"08/01/2001\"]",
	   "format" => ["x", "%m/%d/%Y"],
	   "extra_opts" => join("\n", "set grid", "set timestamp"),


	  },

	  # Data for when stock opened
          [{"title" => "open",
            "type" => "matrix",
	    "style" => "lines",
	   },
	   [
	    ["06/01/2000",  "81.75"],
	    ["07/01/2000", "52.125"],
	    ["08/01/2000", "50.3125"],
	    ["09/01/2000", "61.3125"],
	    ["10/01/2000", "26.6875"],
	    ["11/01/2000", "19.4375"],
	    ["12/01/2000", "17"],
	    ["01/01/2001", "14.875"],
	    ["02/01/2001", "20.6875"],
	    ["03/01/2001", "17.8125"],
	    ["04/01/2001", "22.09"],
	    ["05/01/2001", "25.41"],
	    ["06/01/2001", "20.13"],
	    ["07/01/2001", "23.64"],
	    ["08/01/2001", "19.01"],
	   ]
	  ],


	  # Data for stock high
          [{"title" => "high",
            "type" => "matrix",
	    "style" => "lines",
	   },
	   [
	    ["06/01/2000", "103.9375"],
	    ["07/01/2000", "60.625"],
	    ["08/01/2000", "61.50"],
	    ["09/01/2000", "64.125"],
	    ["10/01/2000", "26.75"],
	    ["11/01/2000", "23"],
	    ["12/01/2000", "17.50"],
	    ["01/01/2001", "22.50"],
	    ["02/01/2001", "21.9375"],
	    ["03/01/2001", "23.75"],
	    ["04/01/2001", "27.12"],
	    ["05/01/2001", "26.70"],
	    ["06/01/2001", "25.10"],
	    ["07/01/2001", "25.22"],
	    ["08/01/2001", "19.90"],
	   ]
	   ],


	  # Data for stock close
          [{"title" => "close",
            "type" => "matrix",
	    "style" => "lines",
	   },
	   [

	    ["06/01/2000", "52.375"],
	    ["07/01/2000", "50.8125"],
	    ["08/01/2000", "60.9375"],
	    ["09/01/2000", "25.75"],
	    ["10/01/2000", "19.5625"],
	    ["11/01/2000", "16.50"],
	    ["12/01/2000", "14.875"],
	    ["01/01/2001", "21.625"],
	    ["02/01/2001", "18.25"],
	    ["03/01/2001", "22.07"],
	    ["04/01/2001", "25.49"],
	    ["05/01/2001", "19.95"],
	    ["06/01/2001", "23.25"],
	    ["07/01/2001", "18.79"],
	    ["08/01/2001", "18.55"],
	   ]
	  ]
		)
      )  {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}

# Test example #2 Example on UNIX time stamps.
if ($test_gnuplot) {
    if(gnuplot({"title" => "foo",
                 "output file" => "test_results/gnuplot4.gif",
		 "output type" =>"gif",
                 "x2-axis label" => "bar",
                 "xtics" => [ ["\\n10pm", 954795600] ],
                 "ytics" => [10,20,30,40,50],
                 "extra_opts" => "set nokey",
                 "uts" => [954791100, 954799300],
               },
	       [{"title" => "Your title",
		 "type" => "matrix"},
		[
		 [954792100, 10],
		 [954793100, 18],
		 [954794100, 12],
		 [954795100, 26],
		 [954795600, 13], # 22:00
		 [954796170, 23],
		 [954797500, 37],
		 [954799173, 20],
		 [954799300, 48],
		],
	       ]
	      )
      ) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "ok # skip Not available on this platform\n";
}
