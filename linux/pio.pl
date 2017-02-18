#!/usr/bin/env perl
# pio: This script provides I/O-related counters for all processes to be used by topio.
# (C) Yong Huang, 2010
# yong321.freeshell.org/freeware/pio.html

use warnings;

@procs = `find /proc -name io -user \$(whoami) 2>/dev/null | egrep -v "task"`;

foreach my $wline (@procs) {
  chomp($wline);
  if (open IO, "<", $wline) {
    #open IO, $wline or die "Can't open file $wline: $!";
    while (defined ($_=<IO>)) {
      last if /^rchar: 0/;	# skip pseudo procs that are kernel threads; their rchar must be 0
      my $cmdline = substr($wline,0,-3);
      print substr($wline,6,-3)."\t" . qx(cat $cmdline/cmdline) . "\t" if /^rc/;	# print pid when first line of io file
      chomp;
      print substr $_,(index $_,":")+2;
      print (/^c/ ? "\n" : "\t") ;	# line begins with cancelled_write_bytes
    }
    close IO;
  }
}

#As of this writing, /proc/<pid>/io is like
#rchar: 6297
#wchar: 0
#syscr: 15
#syscw: 0
#read_bytes: 0
#write_bytes: 0
#cancelled_write_bytes: 0

