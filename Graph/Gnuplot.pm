## Gnuplot.pm is a sub-module of Graph.pm. It has all the subroutines 
## needed for the gnuplot part of the package.
##
## $Id: Gnuplot.pm,v 1.7 1999/04/23 20:12:41 mhyoung Exp $ $Name: graph_RELEASE_1_1 $
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
package Chart::Graph::Gnuplot;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(&gnuplot);

use Carp;			# for carp() and croak()
use Chart::Graph::Utils qw(:UTILS);	# get global subs and variable

$cvs_Id = '$Id: Gnuplot.pm,v 1.7 1999/04/23 20:12:41 mhyoung Exp $';
$cvs_Author = '$Author: mhyoung $';
$cvs_Name = '$Name: graph_RELEASE_1_1 $';
$cvs_Revision = '$Revision: 1.7 $';

use strict;

# these variables  hold default options for gnuplot
my %def_gnu_global_opts = (
			   "title" => "untitled",
			   "output type" => "gif",
			   "output file" => "untitled-gnuplot.gif",
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
#              www.caida.org/Tools/Graph/ for a full description
#              and how-to of this subroutine
#

sub gnuplot {
    my ($user_global_opts_ref, @data_sets) = @_;
    my (%data_opts, %global_opts,);
    my ($plottype, $output_file, $plot_file, $output_type, $data_set_ref);

    # create tmpdir
    _make_tmpdir();

    # set paths for external programs
    if (not _set_gnupaths()) {
	_cleanup_tmpdir();
	return 0;
    }
    
    # check first arg for hash
    if (ref($user_global_opts_ref) ne "HASH") {
	carp "Global options must be a hash";
	_cleanup_tmpdir();
	return 0;
    }

    # check for data sets
    if (not @data_sets) {
	carp "no data sets";
	close COMMAND;
	_cleanup_tmpdir();
	return 0;
    }
    
    # call to combine user options with default options
    %global_opts = _mesh_opts($user_global_opts_ref, \%def_gnu_global_opts);
    
    my $command_file = _make_tmpfile("command");
    
    #remember to close the file if we return
    if (not open(COMMAND, ">$command_file")) {
	carp "could not open file: $command_file";
	_cleanup_tmpdir();
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
	
	# tics are not required so we can fall through if we want 
	if ($key eq "xtics") {
	    if (defined($value) and ref($value) eq "ARRAY") {
		_print_tics($key, @{$value});
	    }
	}
	
	if ($key eq "ytics") {
	    if (defined($value) and ref($value) eq "ARRAY") {
		_print_tics($key, @{$value});
	    }
	}		
	
	if ($key eq "x2tics") {
	    if (defined($value) and ref($value) eq "ARRAY") {
		_print_tics($key, @{$value});
	    }
	}
	
	if ($key eq "y2tics") {
	    if (defined($value) and ref($value) eq "ARRAY") {
		_print_tics($key, @{$value});
	    }
	}		
	
	
	if ($key eq "output file") {
	    $output_file = $value;
	    $plot_file = _make_tmpfile("plot","pbm");
	    print COMMAND "set output \"$plot_file\"\n";
	    print COMMAND "set terminal pbm small color\n";
	}
	
	if ($key eq "output type") {
	    if (!($value eq "pbm" || $value eq "gif")) {
		carp "invalid output type: $value";
		close COMMAND;
		_cleanup_tmpdir();
		return 0;
	    }
	    $output_type = $value;
	}
    }
    
    # process data sets    
    print COMMAND "plot ";    
    while (@data_sets) {
	
	$data_set_ref = shift @data_sets;
	
	if (ref($data_set_ref) ne "ARRAY") {
	    carp "Data set must be an array";
	    close COMMAND;
	    _cleanup_tmpdir();
	    return 0;
	}
	
	if (not _gnuplot_data_set(@{$data_set_ref})) {
	    ## already printed error message
	    close COMMAND;
	    _cleanup_tmpdir();
	    return 0;
	}
	
	if (@data_sets) {
	    print COMMAND ", ";
	}
    }	
    
    close COMMAND;
	
    # gnuplot and convert pbm file to gif
    if (not _exec_gnuplot($command_file)) {
	_cleanup_tmpdir();
	return 0;
    }
    
    if ($output_type eq "gif") {
	if(not _exec_pbmtogif($plot_file, $output_file)) {
	    _cleanup_tmpdir();
	    return 0;
	}
    } elsif ($output_type eq "pbm") {
	if (not rename($plot_file, $output_file)) {
	    _cleanup_tmpdir();
	    return 0;
	}
    } 
    _cleanup_tmpdir();
    return 1;
}

#
#
# Subroutine: gnuplot_data_set()
# 
# Description: this functions processes the X number
#              of data sets that a user gives as 
#              arguments to gnuplot(). Again, please
#              see http://www.caida.org/Tools/Graph/
#              for the format of the dataset.
#


 
sub _gnuplot_data_set {
    my ($user_data_opts_ref, @data) = @_;
    my (%data_opts);
    
    # set these values with empty string because we print them out later 
    # we don't want perl to complain of uninitialized value. 
    my ($title, $style, $axes, $ranges, $type,) = ("", "", "", "", "");
    my $result;
    my $filename = _make_tmpfile("data");
    
    ## check first arg for hash
    if (ref($user_data_opts_ref) ne "HASH") {
	carp "Data options must be a hash.";
	return 0;
    }

    # call to combine user options with default options   
    %data_opts = _mesh_opts($user_data_opts_ref, \%def_gnu_data_opts);

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
	$result = _matrix_to_file($filename, @data);
    } elsif ($type eq "columns") {
	$result = _columns_to_file($filename, @data);
    } elsif ($type eq "file") {
	$result = _file_to_file($filename, @data);
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

sub _set_gnupaths {

    if (not defined($gnuplot)) {
	if (not $gnuplot = _get_path("gnuplot")) {
	    return 0;
	}
    }
   
    if (not defined($ppmtogif)) {
	if (not $ppmtogif = _get_path("ppmtogif")) {
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

sub _print_tics {
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
sub _matrix_to_file {
    my ($file, $matrix_ref) = @_;
    my $entry_ref;
    my $matrix_len;
    
    if (ref($matrix_ref) ne "ARRAY") {
	carp "Matrix data must be an array";
	return 0;
    }
    
    open (DATA, ">$file");
    
    $matrix_len = @{$matrix_ref};
    for (my $i = 0; $i < $matrix_len; $i++) {
	$entry_ref = $matrix_ref->[$i];
	
	if (ref($entry_ref) ne "ARRAY") {
	    carp "Matrix entry must be an array";
	    close DATA;
	    return 0;
	}
	
	# check that each entry ONLY has two entries
	if (@{$entry_ref} != 2) {
	    carp "Each entry must be an array of size 2";
	    return 0;
	}
      	print DATA $entry_ref->[0], "\t", $entry_ref->[1], "\n";
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

sub _columns_to_file {
    my ($file, $x_col, $y_col) = @_; 
    my ($x_len, $y_len);
    
    $x_len = @{$x_col};
    $y_len = @{$y_col};
    
    if (ref($x_col) ne "ARRAY" and ref($y_col) ne "ARRAY") {
	carp "Column data must be an array";
	return 0;
    }
    
    if ($x_len != $y_len) {
	carp "x and y columns must be of same length";
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
# Description: If a gnuplot data set was given in
#               file format, we simply ma 
#
#

sub _file_to_file {
    my ($file_out, $file_in) = @_;
    
    if (!(-f $file_in)) {
	carp "file not exist: $file_in";
	return 0;
    }
    
    my $status = system("cp", "$file_in", "$file_out");
    
    if (not _chk_status($status)) {
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

sub _exec_gnuplot {
    my ($command_file) = @_;
    my $status = system("$gnuplot", "$command_file");
    
    if (not _chk_status($status)) {
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
sub _exec_pbmtogif {
    my ($pbm_file, $gif_file) = @_;
    my $status;
    
    if ($debug) {
	$status = system("$ppmtogif $pbm_file > $gif_file");
    } else {
	$status = system("$ppmtogif $pbm_file > $gif_file 2> /dev/null");
    }
    
    if (not _chk_status($status)) {
	return 0;
    }
    
    return 1;
}

1;
