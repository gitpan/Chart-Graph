## Graph.pm is a graphing package that supports on-the-fly graphing 
## from the gnuplot and xrt graphing packages.
##
## $Id: Graph.pm,v 1.26 1999/04/27 01:49:17 mhyoung Exp $ $Name: graph_RELEASE_1_1 $
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
package Chart::Graph;
require Exporter;

$VERSION = 1.1;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(&gnuplot &xrt3d);

$cvs_Id = '$Id: Graph.pm,v 1.26 1999/04/27 01:49:17 mhyoung Exp $';
$cvs_Author = '$Author: mhyoung $';
$cvs_Name = '$Name: graph_RELEASE_1_1 $';
$cvs_Revision = '$Revision: 1.26 $';

use Chart::Graph::Utils qw(:USER);
use Chart::Graph::Gnuplot qw(&gnuplot);
use Chart::Graph::Xrt3d qw(&xrt3d);

1;
__END__

=head1 NAME

 Chart::Graph - Perl extension for a front-end to gnuplot and XRT.

 23/4/99
 Version 1.1

=head1 SYNOPSIS

 #make sure to include Chart::Graph
 use Chart::Graph;

 gnuplot(\%global_options, [\%data_set_options, \@matrix], 
                           [\%data_set_options, \@x_column, \@y_column],
                           [\%data_set_options, < filename >], ... );

 #make sure to include Chart::Graph
 use Chart::Graph;

 xrt3d(\%options, \@data_set);

 #say for example we have a 3 by 4 matrix -> dataxy
 xrt3d(\%options, 
       [[data11, data12, data13, data14],
       [data21, data22, data23, data24],
       [data31, data32, data33, data34]])

=head1 DESCRIPTION

 use Chart::Graph;

 Graph.pm is a module that allows easy generation of graphs within 
 perl. Currently Graph.pm supports two packages, gnuplot and xrt, 
 both of which you need to have installed on your system.

 Currently the xrt3d package is not being supported, although
 it works. It is still in the development stage. Feel free to 
 give it a try though.

=head1 INSTALLATION

 To install Graph.pm on your system you need to run:

         perl Makefile.PL
         make
         make install

 If you want to use the xrt3d package, you need to build the "graph"
 binary in the xrt3d directory. 

=head1 USAGE

 Graph.pm will probe your path if you do not supply paths to the 
 programs that it needs. 

 You need to set these variables if they are not in your path:

 For gnuplot():
 $Chart::Graph::gnuplot    # path to gnuplot 
 $Chart::Graph::ppmtogif   # path to ppmtogif

 For xrt():
 $Chart::Graph::ppmtogif   # path to ppmtogif
 $Chart::Graph::xrt        # path to "graph"(the xrt wrapper)
 $Chart::Graph::xwdtopnm   # path to xwdtopnm
 $Chart::Graph::xvfb       # path to Xvfb(the virtual frame 
                            # buffer required by XRT)

 Currently Chart::Graph supports two levels of debug, 0
 (no debug msgs) and 1(debug msgs). You need to set the 
 $Graph::debug flag accordingly. If you are having problems 
 with Graph.pm set the debug flag to 1. Also Graph.pm will check 
 $ENV{TMPDIR} for the temporary file storage. If you do not 
 specify, it will be set to /tmp automatically.
 
 All the documentation(in HTML, with examples) for Graph.pm 
 is located in doc/. Documentation is also available online 
 at http://www.caida.org/Tools/Graph. 

=head1 CONTENT SUMMARY

 Graph.pm        - top level file of Chart::Graph
 Graph/          - sub modules of Chart::Graph
 doc/            - documentation in HTML 
 graph_xrt/      - xrt wrapper executable code
 test_Graph.pl   - the test script used for debugging

=head1 MORE INFO

 For more information on gnuplot, please see the gnuplot web page:
 http://www.cs.dartmouth.edu/gnuplot_info.html.

=head1 CONTACT

 Send email to graph-request@caida.org is you have problems,
 questions, or comments. To subscribe to the mailing list send
 mail to graph-request@caida.org with a body of 
 "subscribe your@email.com"

=head1 AUTHOR

 Michael Young - mhyoung@caida.org

=head1 SEE ALSO

 gnuplot(1).

=cut
