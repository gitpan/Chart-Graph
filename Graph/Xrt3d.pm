## Gnuplot.pm is a sub-module of Graph.pm. It has all the subroutines 
## needed for the gnuplot part of the package.
##
## $Id: Xrt3d.pm,v 1.7 1999/04/23 20:12:43 mhyoung Exp $ $Name: graph_RELEASE_1_1 $
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
## Contact: graph@caida.org
##
package Chart::Graph::Xrt3d;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(&xrt3d);

use FileHandle;			# to create generic filehandles
use Carp;			# for carp() and croak()
use POSIX ":sys_wait_h";	# for waitpid()
use Chart::Graph::Utils qw(:UTILS);	# get global subs and variables

$cvs_Id = '$Id: Xrt3d.pm,v 1.7 1999/04/23 20:12:43 mhyoung Exp $';
$cvs_Author = '$Author: mhyoung $';
$cvs_Name = '$Name: graph_RELEASE_1_1 $';
$cvs_Revision = '$Revision: 1.7 $';

use strict;

#
# xrt graphing package
#


my %def_xrt_global_opts;		# xrt spceific globals

%def_xrt_global_opts = (
			"output file" =>  "untitled-xrt3d.gif",
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
#              www.caida.org/Tools/Graph/ for a full description
#              and how-to of this subroutine
#

sub xrt3d {
    my ($user_global_opts_ref, $data_set_ref) = @_;
    my (%global_opts,);
    
    # variables to be written to the command file
    my ($plot_file, $x_axis, $y_axis, $z_axis, $x_step, $y_step);
    my ($x_min, $y_min, $x_ticks, $y_ticks, $header, $footer);
    my ($x_cnt, $y_cnt, $hdr_cnt, $ftr_cnt);
    my ($output_file);
    
    _make_tmpdir();

    # set paths for external programs
    if (not _set_xrtpaths()) {
	_cleanup_tmpdir();
	return 0;
    }
    
    
    # check first arg for hash
    if (ref($user_global_opts_ref) ne "HASH") {
	carp "Global options must be a hash.";
	_cleanup_tmpdir();
	return 0;
    }

    # call to combine user options with default options 
    %global_opts = _mesh_opts($user_global_opts_ref, \%def_xrt_global_opts);
    
    # check for values in command file
    while (my ($key, $value) = each %global_opts) {
	
		if ($key eq "output file") {
		    if(defined($value)) {
			$output_file = $value;
			$plot_file = _make_tmpfile("plot", "xwd");
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
	    _cleanup_tmpdir();
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
    
    if (not _verify_ticks($x_cnt, $global_opts{"x-ticks"})) {
	_cleanup_tmpdir();
	return 0;
    }
    
    if (not _verify_ticks($y_cnt, $global_opts{"y-ticks"})) {
	_cleanup_tmpdir();
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
    my $command_file = _make_tmpfile("command");
    my $handle = new FileHandle;
    if (not $handle->open(">$command_file")) {
	carp "could not open $command_file";
	_cleanup_tmpdir();
	return 0;
    }
    
    print $handle "$plot_file\n";
    print $handle "$x_min\n";
    print $handle "$y_min\n";
    print $handle "$x_step\n";
    print $handle "$y_step\n";
    print $handle "$x_cnt\n";
    print $handle "$y_cnt\n";
    _print_matrix($handle, @{$data_set_ref});
    print $handle "$hdr_cnt\n";
    _print_array($handle, @{$header});
    print $handle "$ftr_cnt\n";
    _print_array($handle, @{$footer});	
    print $handle "$x_axis\n";
    print $handle "$y_axis\n";
    print $handle "$z_axis\n";
    _print_array($handle, @{$x_ticks});	
    _print_array($handle, @{$y_ticks});
    $handle->close();

    # call xrt and convert file to gif
    if (not _exec_xrt($command_file)) {
	_cleanup_tmpdir();
	return 0;
    }
    
    if(not _exec_xwdtogif($plot_file, $output_file)) {
	_cleanup_tmpdir();
	return 0;
		}
    _cleanup_tmpdir();
    return 1;
}

# 
# Subroutine: set_xrtpaths()
# 
# Description: set paths for external programs required by xrt()
#              if they are not defined already
#
sub _set_xrtpaths {

    if (not defined($ppmtogif)) {
	if (not $ppmtogif = _get_path("ppmtogif")) {
	    return 0;
	}
    }

    if (not defined($xrt)) {
	if (not $xrt = _get_path("xrt")) {
	    return 0;
	}
    }

    if (not defined($xwdtopnm)) {
	if (!($xwdtopnm = _get_path("xwdtopnm"))) {
	    return 0;
	}
    }

    if (not defined($xvfb)) {
	if (not $xvfb = _get_path("Xvfb")) {
	    return 0;
	}
    }

    # make sure /usr/dt/lib is in the library path
    _set_ldpath("/usr/dt/lib");

    return 1;
}

#
# Subroutine: set_ldpath()
#
# Description: Xvfb has trouble finding libMrm, so we have to add
#              /usr/dt/lib to LD_LIBRARY_PATH
#

sub _set_ldpath {
    my ($libpath) = @_;
    
    if (not defined($ENV{LD_LIBRARY_PATH})) {
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

sub _print_matrix {
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

sub _print_array {
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
#              as many ticks as the number of rows or columns
#              we make this subroutine so that the calling subroutine
#              is kept cleaner.

sub _verify_ticks {
    my ($cnt, $ticks_ref) = @_;

    # if no ticks are given then just
    # give the xrt binary "1, 2,..."
    if (not defined($ticks_ref)) {
	my @def_ticks;
	for (my $i = 0; $i < $cnt; $i++) {
	    $def_ticks[$i] = $i + 1;
        }
	$ticks_ref = \@def_ticks;
    }

    my $tick_cnt = @{$ticks_ref};

    if ($cnt ne $tick_cnt){
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
sub _exec_xrt {
    my ($command_file) = @_;
    my ($output);
    
    # start the virtual X server
    my ($childpid, $port) = _exec_xvfb();
    
    my $status = system("$xrt -display :$port.0 < $command_file");
    if (not _chk_status($status)) {
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
sub _exec_xwdtogif {
    my ($xwd_file, $gif_file) = @_;
    my ($status);
    
    if ($debug) {
	$status = system("$xwdtopnm $xwd_file | $ppmtogif > $gif_file");
    } else {
	$status = system("( $xwdtopnm $xwd_file | $ppmtogif > $gif_file; ) 2> /dev/null");
    }
    
    if (not _chk_status($status)) {
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
sub _exec_xvfb {
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
    while (_childpid_dead($childpid)) {
	$port++;
	$childpid = _try_port($port);
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
sub _try_port {

    my ($port) = @_;
    my ($childpid);
    
    #fork a process
    if (not defined($childpid = fork())){
	# the fork failed
	carp "cannot fork: $!";
	return 0;
    } elsif ($childpid == 0) {
	# we are in the child process
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
sub _childpid_dead {
    my ($childpid) = @_;
    
    if (not defined($childpid)) {
	return 1;
    }

    # WNOHANG: waitpid() will not suspend execution  of
    # the  calling  process  if  status is not
    # immediately available  for  one  of  the
    #  child processes specified by pid.
    return waitpid($childpid, &WNOHANG);
}

1;
