## Graph.pm is a graphing package that supports on-the-fly graphing 
## from the gnuplot and xrt graphing packages.
##
## $Id: Utils.pm,v 1.6 1999/04/23 20:12:42 mhyoung Exp $ $Name: graph_RELEASE_1_1 $
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
package Chart::Graph::Utils;
require Exporter;


@ISA = qw(Exporter);
%EXPORT_TAGS = (UTILS => [qw($gnuplot $ppmtogif $xwdtopnm $xrt $xvfb $tmpdir 
			     $debug 
			     $tmpcount
			     &_make_tmpdir &_cleanup_tmpdir &_get_path 
			     &_chk_status &_mesh_opts &_make_tmpfile)],

                 	     # variables that user may set
		USER => [qw($gnuplot $ppmtogif $xwdtopnm $xrt $xvfb $tmpdir
			    $debug)]
	       );

# add symbols from tags into @EXPORT_OK
Exporter::export_ok_tags('UTILS');

use Carp;			# for carp() and croak()
use File::Path;	                # for rmtree()

$cvs_Id = '$Id: Utils.pm,v 1.6 1999/04/23 20:12:42 mhyoung Exp $';
$cvs_Author = '$Author: mhyoung $';
$cvs_Name = '$Name: graph_RELEASE_1_1 $';
$cvs_Revision = '$Revision: 1.6 $';

use strict;

# debug level, people can set this with $Graph::debug = 1; after the
# use Graph; to increase debug output.
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
    _cleanup_tmpdir();
}

#
# general purpose global variables
#								

use vars qw($tmpcount $tmpdir);
$tmpcount = 0;	# used to create unique tmp filenames	

#
#
# general purpose subroutines - these are subroutines shared across
#                               all packages     
#

# 
# Subroutine: make_tmpdir()
# 
# Description: creates temporary dir for storage 
#              of temporary files with read, write,
#              and execute for user and group
sub _make_tmpdir {
    if (not defined($ENV{TMPDIR})) {
	$tmpdir = "/tmp/Graph$$";
    } else {
	$tmpdir = "$ENV{TMPDIR}/Graph$$";
    }

    if (not mkdir($tmpdir, 0770)) {
	$tmpdir = undef;
	croak "could not make temporary directory: $tmpdir";
    }

    return $tmpdir;
}

# 
# Subroutine: cleanup_tmpdir()
# 
# Description: remove the tmp dir we created for
#              tmp files

sub _cleanup_tmpdir {
    if (defined($tmpdir) and -d $tmpdir ) {
	rmtree ($tmpdir);
    }
}

# 
# Subroutine: make_tmpfile() 
# Description: create temporary filenames with unique extensions
#
#
sub _make_tmpfile {
    my ($file, $ext) = @_;
    $tmpcount++;
    if (not defined($ext)) {
	$ext = "";
    } elsif ($ext ne "") {
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
sub _get_path {
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
sub _chk_status {
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

sub _mesh_opts {
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
	carp "unknown option: $key";
    }
    
    return %opts;
}
1;
