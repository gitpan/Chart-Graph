package Chart::Graph;
require Exporter;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = 1.0;
@ISA = qw(Exporter);
@EXPORT = qw(gnuplot xrt);
@EXPORT_OK = qw();

## Graph.pm is a graphing package that supports on-the-fly graphing 
## from the gnuplot and xrt graphing packages.
##
## $Id: Graph.pm,v 1.17 1999/04/05 23:46:57 mhyoung Exp $ $Name:  $
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
use FileHandle;			# to create generic filehandles
use Carp;			# for carp() and croak()
use File::Path;	                # for rmtree()
use POSIX ":sys_wait_h";	# for waitpid()

use vars qw($cvs_Id $cvs_Author $cvs_Name $cvs_Revision);

$cvs_Id = '$Id: Graph.pm,v 1.17 1999/04/05 23:46:57 mhyoung Exp $';
$cvs_Author = '$Author: mhyoung $';
$cvs_Name = '$Name:  $';
$cvs_Revision = '$Revision: 1.17 $';


# debug level, people can set this with $Graph::debug = 1; after the
# use Graph; to increase debug output..
use vars qw($debug);
$debug = 0;			# turn debug mesg off by default

# hold paths to programs 
# user may choose to set paths to these programs
# if paths are not set then we will attempt to search
# PATH for the programs                                    
use vars qw($gnuplot $ppmtogif $xrt $xwdtopnm $xvfb); 
				
#
# remove tmp files in case program exits abnormally
#
END {
    cleanup_tmpdir();
}

#
# general purpose global variables
#								

my $tmpcount = 0;	# used to create uniqute tmp filenames	
my $tmpdir;         # where to store tmpfiles




#
# gnuplot graphing package
#


# these variables  hold default options for gnuplot
my %def_gnu_global_opts = (
			   "title" => "untitled",
			   "output type" => "gif",
			   "output file" => "gnuplot.gif",
			   "x-axis label" => "x-axis",
			   "y-axis label" => "y-axis",
			   "x2-axis label" => undef,
			   "y2-axis label" => undef,
			   "logscale x" => "0",
         		   "logscale y" => "0",
			   "logscale x2" => "0",
			   "logscale y2" => "0",
			   "xtics" => undef,
			   "ytics" => undef,
			   "x2tics" => undef,
			   "y2tics" => undef
			  );


my %def_gnu_data_opts = (
			 "title" => "untitled data",
			 "style" => "points", # points, lines...
			 "axes" => "x1y1", 
			 "type" => undef,
			);
#
#
# Subroutine: gnuplot()
#
# Description: this is the main function you will be calling from
#              our scripts. please see 
#              www.caida.org/~mhyoung/graph for a full description
#              and how-to of this subroutine
#

sub gnuplot {
    my ($user_global_opts_ref, @data_sets) = @_;
    my (%data_opts, %global_opts,);
    my ($plottype, $output_file, $plot_file, $output_type, $data_set_ref);

    # create tmpdir
    make_tmpdir();

    # set paths for external programs
    if (!(set_gnupaths())) {
	cleanup_tmpdir();
	return 0;
    }
    
    # check first arg for hash
    if (!(ref($user_global_opts_ref ) eq "HASH")) {
	carp "Global options must be a hash.";
	cleanup_tmpdir();
	return 0;
    }
    
    # call to combine user options with default options
    %global_opts = mesh_opts($user_global_opts_ref, \%def_gnu_global_opts);
    
    my $command_file = make_tmpfile("command");
    
    #remember to close the file if we return
    if (!(open(COMMAND, ">$command_file"))) {
	carp "could not open file: $command_file";
	cleanup_tmpdir();
	return 0;
	}
    
    # write global options to command file
    while (my ($key, $value) = each %global_opts) {
	
	if ($key eq "title") {
	    print COMMAND "set title \"$value\"\n";
	}
	
	if ($key eq "x-axis label") {
	    print COMMAND "set xlabel \"$value\"\n";
	}
	
	if ($key eq "y-axis label") {
	    print COMMAND "set ylabel \"$value\"\n";
	}
	
	if ($key eq "x2-axis label") {
	    if (defined($value)) {
		print COMMAND "set x2label \"$value\"\n";
	    }
	}
	
	if ($key eq "y2-axis label") {
	    if (defined($value)) {
		print COMMAND "set y2label \"$value\"\n";
	    }
	}
	
	if ($key eq "logscale x") {
	    if ($value == 1) {
		print COMMAND "set logscale x\n";
	    }
	}
	
	if ($key eq "logscale y") {
	    if ($value == 1) {
		print COMMAND "set logscale y\n";
			}
	}
	if ($key eq "logscale x2") {
	    if ($value == 1) {
		print COMMAND "set logscale x2\n";
	    }
	}
	
	if ($key eq "logscale y2") {
	    if ($value == 1) {
		print COMMAND "set logscale y2\n";
	    }
	}
	
	if ($key eq "xtics") {
	    if (defined($value) && ref($value) eq "ARRAY") {
		print_tics($key, @{$value});
	    }
	}
	
	if ($key eq "ytics") {
	    if (defined($value) && ref($value) eq "ARRAY") {
		print_tics($key, @{$value});
	    }
	}		
	
	if ($key eq "x2tics") {
	    if (defined($value) && ref($value) eq "ARRAY") {
		print_tics($key, @{$value});
	    }
	}
	
	if ($key eq "y2tics") {
	    if (defined($value) && ref($value) eq "ARRAY") {
		print_tics($key, @{$value});
	    }
	}		
	
	
	if ($key eq "output file") {
	    $output_file = $value;
	    $plot_file = make_tmpfile("plot","pbm");
	    print COMMAND "set output \"$plot_file\"\n";
	    print COMMAND "set terminal pbm small color\n";
	}
	
	if ($key eq "output type") {
	    if (!($value eq "pbm" || $value eq "gif")) {
		carp "invalid output type: $value";
		close COMMAND;
		cleanup_tmpdir();
		return 0;
	    }
	    $output_type = $value;
	}
    }
    
    
    
    
    # process data sets
    if (!@data_sets) {
	carp "no data sets";
	close COMMAND;
	cleanup_tmpdir();
	return 0;
    }
    
    print COMMAND "plot ";
    
    while (@data_sets) {
	
	$data_set_ref = shift @data_sets;
	
	if (!(ref($data_set_ref ) eq "ARRAY")) {
	    carp "Data set must be an array";
	    close COMMAND;
	    cleanup_tmpdir();
	    return 0;
	}
	
	if (!gnuplot_data_set(@{$data_set_ref})) {
	    ## already printed error message
	    close COMMAND;
	    cleanup_tmpdir();
	    return 0;
	}
	
	if (@data_sets) {
	    print COMMAND ", ";
	}
    }	
    
    close COMMAND;
	
    # gnuplot and convert pbm file to gif
    if (!exec_gnuplot($command_file)) {
	cleanup_tmpdir();
	return 0;
    }
    
    if ($output_type eq "gif") {
	if(!exec_pbmtogif($plot_file, $output_file)) {
	    cleanup_tmpdir();
	    return 0;
	}
    } elsif ($output_type eq "pbm") {
	if (!rename($plot_file, $output_file)) {
	    cleanup_tmpdir();
	    return 0;
	}
    } 
    cleanup_tmpdir();
    return 1;
}

#
#
# Subroutine: gnuplot_data_set()
# 
# Description: this functions processes the X number
#              of data sets that a user gives as 
#              arguments to gnuplot(). Again, please
#              see http://www.caida.org/~mhyoung/graph
#              for the format of the dataset.
#


 
sub gnuplot_data_set {
    my ($user_data_opts_ref, @data) = @_;
    my (%data_opts);
    
    # set these values with empty string because we print them out later 
    # we don't want perl to complain of uninitialized value. 
    my ($title, $style, $axes, $ranges, $type,) = ("", "", "", "", "");
    my $result;
    my $filename = make_tmpfile("data");
    
    ## check first arg for hash
    if (!(ref($user_data_opts_ref) eq "HASH")) {
	carp "Data options must be a hash.";
	return 0;
    }

    # call to combine user options with default options   
    %data_opts = mesh_opts($user_data_opts_ref, \%def_gnu_data_opts);

    # write data options to command file
    while (my ($key, $value) = each %data_opts) {
	
	if ($key eq "title") {
	    $title = "title \"$value\"";
	}
	
	if ($key eq "style") {
	    $style = "with $value"
	}
		
	if ($key eq "axes") {
	    $axes = "axes $value";
		}
	
	if ($key eq "type") {
	    $type = $value;
	}
    }
    
    print COMMAND "$ranges \"$filename\" $axes $title $style";

    # we give the user 3 formats for supplying the data set
    # 1) matrix
    # 2) column
    # 3) file
    # please see the online docs for a description of these 
    # formats
    if ($type eq "matrix") {
	$result = matrix_to_file($filename, @data);
    } elsif ($type eq "columns") {
	$result = columns_to_file($filename, @data);
    } elsif ($type eq "file") {
	$result = file_to_file($filename, @data);
    } elsif ($type eq "") {
	carp "Need to specify data set type";
	return 0;
    } else {
	carp "Illegal data set type: $type"; 
        return 0;
    }
    return $result;
}

# 
# Subroutine: set_gnupaths()
# 
# Description: set paths for external programs required by gnuplot()
#              if they are not defined already
#

sub set_gnupaths {

    if (!(defined($gnuplot))) {
	if (!($gnuplot = get_path("gnuplot"))) {
	    return 0;
	}
    }
   
    if (!(defined($ppmtogif))) {
	if (!($ppmtogif = get_path("ppmtogif"))) {
	    return 0;
	}
    }
    return 1;
}

#
#
#  Subroutine: print_tics()
#  Description: this subroutine takes an array 
#               of graph tic labels and prints 
#               them to the gnuplot command file.
#               This subroutine is called by gnuplot().
#
#  Arguments: $tic_type: which axis to print the tics on
#             @tics: the array of tics to print to the file
#

sub print_tics {
    my ($tic_type, @tics) = @_;
    my (@tic_array, $tics_formatted, $tic_label, $tic_index);
    
    foreach my $tic (@tics) {
	#tics can come in two formats
	#this one is [["label1", 10], ["label2", 20],...]
	if (ref($tic) eq "ARRAY") {
	    
	    if ($#{$tic} != 1) {
		carp "invalid tic format";
		return 0;
	    }
	    $tic_label = $tic->[0];
	    $tic_index = $tic->[1];
	    push (@tic_array, "\"$tic_label\" $tic_index");
	    # this one is [10, 20,...]
	} else {
	    push (@tic_array, "$tic");
	}
    }
    $tics_formatted = join(",", @tic_array);
    print COMMAND "set $tic_type ($tics_formatted)\n";
    return 1;
}

#
#
# Subroutine: matrix_to_file()
#
# Description: converts the matrix data input into a the gnuplot
#              data file format. See www for the specific on the 
#              matrix format
# 
# 
sub matrix_to_file {
    my ($file, $matrix_ref) = @_;
    my $entry_ref;
    my $matrix_len;
    my ($x, $y);
    
    if (!(ref($matrix_ref ) eq "ARRAY")) {
	carp "Matrix data must be an array";
	return 0;
    }
    
    open (DATA, ">$file");
    
    $matrix_len = @{$matrix_ref};
    for (my $i = 0; $i < $matrix_len; $i++) {
	$entry_ref = $matrix_ref->[$i];
	
	if (!(ref($entry_ref ) eq "ARRAY")) {
	    carp "Matrix entry must be an array";
	    close DATA;
	    return 0;
	}
	
	# check that each entry ONLY has two entries
	if (@{$entry_ref} != 2) {
	    carp "Each entry must be an array of size 2";
	}
	
	$x = $entry_ref->[0];
	$y = $entry_ref->[1];
      	print DATA "$x\t$y\n";
    }
    close DATA;
    return 1;
}

#
#
# Subroutine: columns_to_file()
#
# Description: converts the column data input into a the gnuplot
#              data file format. please see www page for specifics
#              on this format.
#

sub columns_to_file {
    my ($file, $x_col, $y_col) = @_; 
    my ($x_len, $y_len);
    
    $x_len = @{$x_col};
    $y_len = @{$y_col};
    
    if (!(ref($x_col) eq "ARRAY" && ref($y_col) eq "ARRAY")) {
	carp "Column data must be an array";
	return 0;
    }
    
    if ($x_len != $y_len) {
	carp "x and y columns must be the same length";
	return 0;
    }
    
    open (DATA, ">$file");
    
    for (my $i = 0; $i < $x_len; $i++) {
      	print DATA "$x_col->[$i]\t$y_col->[$i]\n";
    }
    close DATA;
    return 1;
}



#
# Subroutine: file_to_file()
#
# Descriptiion: If a gnuplot data set was given in
#               file format, we simply ma 
#
#

sub file_to_file {
    my ($file_out, $file_in) = @_;
    
    if (!(-f $file_in)) {
	carp "file not exist: $file_in";
    }
    
    my $status = system("cp", "$file_in", "$file_out");
    
    if (!(chk_status($status))) {
	return 0;
    }
    
    return 1;
}

# 
# Subroutine: exec_gnuplot()
#
# Description: this executes gnuplot on the command file 
#              and data sets that we have generated.
#

sub exec_gnuplot {
    my ($command_file) = @_;
    my $status = system("$gnuplot", "$command_file");
    
    if (!(chk_status($status))) {
	return 0;
    }
    
    return 1;
}	

#
# Subroutine: exec_pbmtogif()
# 
# Description: convert pbm file that gnuplot makes into
#              a gif. usually used for web pages
#
sub exec_pbmtogif {
    my ($pbm_file, $gif_file) = @_;
    my $status;
    
    if ($debug) {
	$status = system("$ppmtogif $pbm_file > $gif_file");
    } else {
	$status = system("$ppmtogif $pbm_file > $gif_file 2> /dev/null");
    }
    
    if (!(chk_status($status))) {
	return 0;
    }
    
    return 1;
}




#
# xrt graphing package
#


my %def_xrt_global_opts;		# xrt spceific globals

%def_xrt_global_opts = (
			"output file" =>  "xrt.gif",
			"x-axis title" => "x-axis",
			"y-axis title" => "y-axis",
			"z-axis title" => "z-axis",
			"x-min" => "0",
			"y-min" => "0",
			"x-step" => "1",
			"y-step" => "1",
			"x-ticks" => undef,
			"y-ticks" => undef,
			"header" => ["header"],
			"footer" => ["footer"],
		       );
#
#
# Subroutine: xrt()
#
# Description: this is the main function you will be calling from
#              our scripts. please see 
#              www.caida.org/~mhyoung/graph for a full description
#              and how-to of this subroutine
#

sub xrt {
    my ($user_global_opts_ref, $data_set_ref) = @_;
    my (%global_opts,);
    
    # variables to be written to the command file
    my ($plot_file, $x_axis, $y_axis, $z_axis, $x_step, $y_step);
    my ($x_min, $y_min, $x_ticks, $y_ticks, $header, $footer);
    my ($x_cnt, $y_cnt, $hdr_cnt, $ftr_cnt);
    my ($output_file);
    
    make_tmpdir();

    # set paths for external programs
    if (!(set_xrtpaths())) {
	cleanup_tmpdir();
	return 0;
    }
    
    
    # check first arg for hash
    if (!(ref($user_global_opts_ref ) eq "HASH")) {
	carp "Global options must be a hash.";
	cleanup_tmpdir();
	return 0;
    }

    # call to combine user options with default options 
    %global_opts = mesh_opts($user_global_opts_ref, \%def_xrt_global_opts);
    
    # check for values in command file
    while (my ($key, $value) = each %global_opts) {
	
		if ($key eq "output file") {
		    if(defined($value)) {
			$output_file = $value;
			$plot_file = make_tmpfile("plot", "xwd");
		    }
		}
		
		if ($key eq "x-axis title") {
		    if(defined($value)) {
			$x_axis = $value;
		    }
		}
		
		if ($key eq "y-axis title") {
		    if(defined($value)) {
			$y_axis = $value;
		    }
		}
		
		if ($key eq "z-axis title") {
		    if(defined($value)) {
			$z_axis = $value;
		    }
		}
		
		if ($key eq "x-min") {
		    if(defined($value)) {
			$x_min = $value;
		    }
		}
		
		if ($key eq "y-min") {
		    if(defined($value)) {
			$y_min = $value;
		    }
		}
		
		if ($key eq "x-step") {
		    if(defined($value)) {
			$x_step = $value;
		    }
		}
		
		if ($key eq "y-step") {
		    if(defined($value)) {
			$y_step = $value;
		    }
		}
		
		if ($key eq "x-ticks") {
		    if(defined($value)) {
			$x_ticks = $value;
		    }
		}
		
		if ($key eq "y-ticks") {
		    if(defined($value)) {
			$y_ticks = $value;
		    }
		}
		
		if ($key eq "header") {
		    if(defined($value)) {
			$header = $value;
		    }
		}
		
		if ($key eq "footer") {
		    if(defined($value)) {
			$footer = $value;
		    }
		}
	    }
    
    # get the number of columns and number of rows
    # and verify that each row has same number of 
    # columns
    
    $x_cnt = $#{$data_set_ref} + 1;
    my $tmp = $#{$data_set_ref->[0]} + 1;
    
    foreach my $i (@{$data_set_ref}) {
	if ($tmp != $#{$i} + 1) {
	    carp "each row must have the same number of columns";
	    cleanup_tmpdir();
	    return 0;
	} 
    }
    
    $y_cnt = $tmp;
    
    # because xrt allows multiline headers
    # get the length of the header array
    # each line of the header is one index
    # in the array
    $hdr_cnt = $#{$global_opts{"header"}} + 1;
    $ftr_cnt = $#{$global_opts{"footer"}} + 1;
    
    # verify that number of tick marks == corresponds
    # to that of xy matrix. One tick mark for every x
    # y.
    
    if (!(verify_ticks($x_cnt, $global_opts{"x-ticks"}))) {
	cleanup_tmpdir();
	return 0;
    }
    
    if (!(verify_ticks($y_cnt, $global_opts{"y-ticks"}))) {
	cleanup_tmpdir();
	return 0;
    }
    
    ##
    ## print command file using this format
    ##
    
    # output.file						
    # x_min (normally 0)
    # y_min (normally 0)
    # x_step (normally 1)
    # y_step (normally 1)
    # x_cnt (number of rows of input)
    # y_cnt (number of columns of input)
    # data11 data12 data13 data14 .... (x by y matrix of doubles)
    # data21 data22 data23 ....
    # .
    # .
    # .
    # datax1 datax2 ... dataxy
    # Number of header lines (multiple header lines available)
    # header1
    # header2
    # ...
    # Number of header lines (multiple header lines available)
    # foot1
    # foot2
    # ...
    # Title of x-axis
    # Title of y-axis
    # Title of z-axis
    # xlabel0 (x_cnt number of labels for ticks along x-axis)
    # ...
    # xlabelx
    # ylabel0 (y_cnt number of labels for ticks along y-axis)
    # ...
    # ylabely
    
    # create command file and open file handle 
    my $command_file = make_tmpfile("command");
    my $handle = new FileHandle;
    if (!($handle->open(">$command_file"))) {
	carp "could not open $command_file";
	cleanup_tmpdir();
	return 0;
    }
    
    print $handle "$plot_file\n";
    print $handle "$x_min\n";
    print $handle "$y_min\n";
    print $handle "$x_step\n";
    print $handle "$y_step\n";
    print $handle "$x_cnt\n";
    print $handle "$y_cnt\n";
    print_matrix($handle, @{$data_set_ref});
    print $handle "$hdr_cnt\n";
    print_array($handle, @{$header});
    print $handle "$ftr_cnt\n";
    print_array($handle, @{$footer});	
    print $handle "$x_axis\n";
    print $handle "$y_axis\n";
    print $handle "$z_axis\n";
    print_array($handle, @{$x_ticks});	
    print_array($handle, @{$y_ticks});
    $handle->close();

    # call xrt and convert file to gif
    if (!exec_xrt($command_file)) {
	cleanup_tmpdir();
	return 0;
    }
    
    if(!exec_xwdtogif($plot_file, $output_file)) {
	cleanup_tmpdir();
	return 0;
		}
    cleanup_tmpdir();
    return 1;
}

# 
# Subroutine: set_xrtpaths()
# 
# Description: set paths for external programs required by xrt()
#              if they are not defined already
#
sub set_xrtpaths {

    if (!(defined($ppmtogif))) {
	if (!($ppmtogif = get_path("ppmtogif"))) {
	    return 0;
	}
    }

    if (!(defined($xrt))) {
	if (!($xrt = get_path("xrt"))) {
	    return 0;
	}
    }

    if (!(defined($xwdtopnm))) {
	if (!($xwdtopnm = get_path("xwdtopnm"))) {
	    return 0;
	}
    }

    if (!(defined($xvfb))) {
	if (!($xvfb = get_path("Xvfb"))) {
	    return 0;
	}
    }

    # make sure /usr/dt/lib is in the library path
    set_ldpath("/usr/dt/lib");

    return 1;
}

#
# Subroutine: set_ldpath()
#
# Description: Xvfb has trouble finding libMrm, so we have to add
#              /usr/dt/lib to LD_LIBRARY_PATH
#

sub set_ldpath {
    my ($libpath) = @_;
    
    if (!defined($ENV{LD_LIBRARY_PATH})) {
	$ENV{LD_LIBRARY_PATH} = "$libpath";
	return 1;
    }

    my @ldpath = split (/:/, $ENV{LD_LIBRARY_PATH});

    # make sure library path isn't already defined
    foreach my $i(@ldpath){
	if ($i eq $libpath) {
	    return 1;
	}
    }

    # add library path to LD_LIBRARY_PATH
    $ENV{LD_LIBRARY_PATH} = "$libpath:$ENV{LD_LIBRARY_PATH}";
    return 1;
}

# 
# Subroutine: print_matrix() 
# 
# Description: print out all the elements 
#              in a X by Y  matrix, row by row
#

sub print_matrix {
    my ($handle, @matrix) = @_;
    
    foreach my $row (@matrix){
	foreach my $i (@{$row}){
	    print $handle "$i ";
	}
	print $handle "\n";
    }
    return 1;
}
# 
# Subroutine: print_array()
# 
# Description:  print out each element of array, one per line
#

sub print_array {
    my ($handle, @array) = @_;
    my $i;
    
    foreach $i (@array) {
	print $handle "$i\n";
    }
    return 1;
}

# 
# Subroutine: verify_ticks();
#   
# Description: check that the number of tick labels is the same
#              as the number of xy rows and columns. we can only have
#              asm nay ticks as the number of rows or columns
#              we make this subroutine so that the calling subroutine
#              is kept cleaner.

sub verify_ticks {
    my ($cnt, $ticks_ref) = @_;

    # if no ticks are given then just
    # give the xrt binary "1, 2,..."
    if (!defined($ticks_ref)) {
	my @def_ticks;
	for (my $i = 0; $i < $cnt; $i++) {
	    $def_ticks[$i] = $i + 1;
        }
	$ticks_ref = \@def_ticks;
    }

    my $tick_cnt = @{$ticks_ref};

    if ($cnt != $tick_cnt){
	carp "number of tick labels must equal the number of xy rows and columns";
	return 0;
    }
    return 1;
}

# 
# Subroutine: exec_xrt()
#
# Description: execute the xrt program on the command file.
#              xrt generates a xwd file.
# 
sub exec_xrt {
    my ($command_file) = @_;
    my ($output);
    
    # start the virtual X server
    my ($childpid, $port) = exec_xvfb();
    
    my $status = system("$xrt -display :$port.0 < $command_file");
    if (!(chk_status($status))) {
	return 0;
    }

    kill('KILL', $childpid);
    return 1;
}
	
# 
# Subroutine: exec_xwdtogif 
# 
# Description: convert the xwd file generated by xrt into a gif
#              this is a 2-step process. the xwd must be converted into 
#              a pnm and then into a gif.
sub exec_xwdtogif {
    my ($xwd_file, $gif_file) = @_;
    my ($status);
    
    if ($debug) {
	$status = system("$xwdtopnm $xwd_file | $ppmtogif > $gif_file");
    } else {
	$status = system("( $xwdtopnm $xwd_file | $ppmtogif > $gif_file; ) 2> /dev/null");
    }
    
    if (!(chk_status($status))) {
	return 0;
    }
    return 1;
}

# 
# Subroutine: exec_xvfb()
#
# Description:  this starts the vitualX server(X is required by xrt, so 
#               we fake out xrt with Xvfb, for speed and compatability)
#
#
sub exec_xvfb {
    my $port = 99;
    my $childpid;
    my $sleep_time = 1;

    # starting with port 100, we try to start
    # the virtual server until we find an open port
    # because of the nature of the virtual x server
    # we use, in order to know if we have found an 
    # open port, we have to sleep.
    # we check the pid of the virtual x process we started
    # and see if it died or not.
    while (childpid_dead($childpid)) {
	$port++;
	$childpid = try_port($port);
	sleep($sleep_time);
    }

    # save the childpid so we can stop the virtual server later
    # save the $port so we can tell xrt where the virtual server is.
    return ($childpid, $port);
}
# 
# Subroutine: try_port();
#
# Description:  will try to start Xvfb on specified port
sub try_port {

    my ($port) = @_;
    my ($childpid);
    
    #fork a process
    if (!defined($childpid = fork())){
	# the fork failed
	warn "cannot fork: $!";
	return 0;
    } elsif ($childpid == 0) {
	# we are in the chile process
	if ($debug) {
	    exec "$xvfb :$port";
	}
	else {
	    exec "exec $xvfb :$port 2> /dev/null";
	}
    } else {
	# we are in the parent, return the childpid
	# so re can kill it later.
	return $childpid;
    }
    
}

# 
# Subroutine: childpid_dead
# 
# Description: check to see if a PID has died or not
#
#
sub childpid_dead {
    my ($childpid) = @_;
    
    if (!(defined($childpid))) {
	return 1;
    }

    # WNOHANG: waitpid() will not suspend execution  of
    # the  calling  process  if  status is not
    # immediately available  for  one  of  the
    #  child processes specified by pid.
    return waitpid($childpid, &WNOHANG);
}

#
#
# general purpose subroutines
#
#

# 
# Subroutine: make_tmpdir()
# 
# Description: creates temporary dir for storage 
#              of temporary files with read, write,
#              and execute for user and group
sub make_tmpdir {

    if (!defined($ENV{TMPDIR})) {
	$ENV{TMPDIR} = "/tmp"
    }

    $tmpdir = "$ENV{TMPDIR}/Graph$$";

    mkdir ($tmpdir, 0770);
    return $tmpdir;
}

# 
# Subroutine: cleanup_tmpdir()
# 
# Description: remove the tmp dir we created for
#              tmp files

sub cleanup_tmpdir {
    if (-d "$tmpdir") {
	rmtree ($tmpdir);
    }
}

# 
# Subroutine: make_tmpfile() 
# Description: create temporary filenames with unique extensions
#
#
sub make_tmpfile {
    my ($file, $ext) = @_;
    $tmpcount++;
    if (!defined($ext)) {
	$ext = "";
    } elsif (!($ext eq "")) {
	$ext = ".$ext"
    };
    return "$tmpdir/$file.$tmpcount$ext";
}

# 
# Subroutine: get_path()
# 
# Description: searches PATH for specified program given as arg 
#
#
#
#
sub get_path {
    my ($exe) = @_;
    my @path = split (/:/, $ENV{PATH});
    my $program;	
    
    foreach my $i(@path){
	$program = "$i/$exe";
	if (-x $program) {
	    return $program;
	}
    }

    carp "program not found in search path: $exe";
    
    return 0;
}

# 
# Subroutine: chk_status
# 
# Description: checks the exit status of system() calls for errors
#
#
sub chk_status {
    my ($status) = @_;
    if ($status) { 
	my $exit_value = $? >> 8;
	my $signal_num = $? & 127;
	my $dumped_core = $? & 128;
	carp "exit value = $exit_value\n
              signal number = $signal_num\n
              dumped core = $dumped_core\n";
	return 0;
    }
    return 1;
}

# 
# Subroutine: mesh_opts
#
# Description: merges user and default option for 
#              gnuplot and or xrt options
#

sub mesh_opts {
    my ($user_opts_ref, $default_opts_ref) = @_;
    my %user_opts = %{$user_opts_ref};
    my %default_opts = %{$default_opts_ref};
    my %opts;

    # check user opts against defaults and mesh
    # the basic algorithm here is to override the 
    # the default options against the ones that
    # the user has passed in. 
    while (my ($key, $value) = each %default_opts) {
	if (defined($user_opts{$key})) {
	    $opts{$key} = $user_opts{$key};
	    delete $user_opts{$key}; # remove options 
	    # that are matching
	} else {
	    $opts{$key} = $default_opts{$key};
	}
    }
    
    # any left over options in the table are unknown
    # if the user passes in illegal options then we 
    # warn them with an error message but still 
    # proceed.
    while (my ($key, $value) = each %user_opts) {
	carp "unknown global option: $key";
    }
    
    return %opts;
}
1;

__END__
=head1 NAME

Chart::Graph - Perl extension for a front-end to gnuplot and XRT.

=head1 SYNOPSIS

  use Chart::Graph;

  Graph.pm is a module that allows easy generation of graphs within 
  perl. Currently Graph.pm supports two packages, gnuplot and xrt, 
  both of which you need to have installed on your system.

=head1 INSTALLATION
  To install Graph.pm on your system you need to run:
 
          perl Makefile.PL
          make
          make install

  If you want support for xrt you need to compile the xrt wrapper 
  executable and move it into your path somewhere:

          cd graph_xrt
          make 

=head1 USING
  Graph.pm will probe your path if you do not supply paths to the 
  programs that it needs. 

  You need to set these variables if they are not in your path:

  For gnuplot():
  $Chart::Graph::gnuplot    # path to gnuplot 
  $Chart::Graph::ppmtogif   # path to ppmtogif

  For xrt():
  $Chart::Graph::ppmtogif   # path to ppmtogif
  $Chart::Graph::xrt        # path to graph(the xrt wrapper)
  $Chart::Graph::xwdtopnm   # path to xwdtopnm
  $Chart::Graph::xvfb       # path to Xvfb(the virutal frame 
                            #  buffer required by XRT)

  Currently Chart::Graph supports two levels of debug, 0
  (no debug msgs) and 1(debu msgs). You need to set the 
  $Graph::debug flag accordingly. If you are having problems 
  with Graph.pm set the debug flag to 1. Also Graph.pm will check 
  $ENV{TMPDIR} for the temporary file storage. If you do not 
  specify, it will be set to /tmp automatically.
 
  All the documentation(in HTML, with examples) for Graph.pm 
  is located in doc/. Documentation is also available online 
  at http://www.caida.org/Tools/Graph. 

=head1 CONTENT SUMMARY
  Graph.pm        - the acutal Graph module
  doc/            - documentation in HTML 
  graph_xrt/      - xrt wrapper executable code
  test_Graph.pl   - the test script used for debugging

=head1 AUTHOR

Michael Young - mhyoung@caida.org

=head1 SEE ALSO

gnuplot(1).

=cut
