#!/usr/bin/env perl
# Modify the line below ($PIO =...) as needed.
# topio: This Perl script launches pio (Process I/O) to probe all processes
# on the system and sort them based on a desired I/O counter.
# (C) Yong Huang, 2010
# http://yong321.freeshell.org/freeware/pio.html

unless (-e "/proc/self/io") { print "This Linux kernel doesn't support TASK_IO_ACCOUNTING!\n"; exit 1; }
$PIO = "./pio.pl";	# path to pio; absolute path is recommended, e.g., "/usr/local/bin/pio"

########## No need to modify below this line but hacking is welcome. ##########

use Getopt::Std;
use Term::ANSIColor;

getopts('s:n:k:h');

if (defined $opt_h) {
  print "Usage: $0 [-s Delay] [-n Top_n_lines] [-k sortkey] [-h]
    -s: Number of seconds delay between calls (default 5)
    -n: Only show top n processes (default 10)
    -k: sort key (default DltRB)
        rb: DltRB (delta read bytes);
        wb: DltWB;
        RB: RBytes;
        WB: WBytes;
	See www.mjmwired.net/kernel/Documentation/filesystems/proc.txt#1282 for detailed description
	\"read/write bytes\" is about I/O from/to physical storage; 
    -h: Show this Usage
    Example (show top 3 processes every 2 seconds, sorted by DltRB): $0 -s2 -n3 -krb
    Best viewed with terminal width 150 or greater\n";
  exit;
}

$opt_s = 5 if !defined $opt_s;
$opt_n = 10 if !defined $opt_n;
$opt_k = "rb" if !defined $opt_k;

# Format to be used by write:
# pid, name, rchars, dlt
# -PID ProcName------------ ------RdBytes -----DltRBts----- -----WtByts DtWB ---CWBts DltCWB
format =
@>>>> @<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>>> @>>>>>>>>>>>> @>>>>>>>>>>>> @>>>>>>>>>>>>
$_,$HoA{$_}[0],$HoA{$_}[5],$dltrb{$_},$HoA{$_}[6],$dltwb{$_}
.

undef $/;
while (1) {
  $_ = qx{$PIO};	# slurp in all `pio' output

  @lines = split /\n/;
  %allpids = ();	# %allpids is used to delete pid's that're gone between calls to pio
  foreach (@lines) {
    # Each line is: pid ProcName RdChars WtChars Rds Wts RdBytes WtBytes CnclWtBytes
    next unless /^(\d+)\t(.*)/;
    $pid = $1;
    # @pval: all last 8 columns of one line, i.e. values for this pid
    # pval[0]:ProcName; [1]:Rds; [2]:Wts; [3]:RdBytes; [4]:WtBytes; [5]:CnclWtBytes
    @pval = split /\t/,$2;

    if (defined $HoA{$pid}[2]) { # it's not defined in first iteration
      $dltrb{$pid} = $pval[5] - $HoA{$pid}[5];   # Delta RdBytes
      $dltwb{$pid} = $pval[6] - $HoA{$pid}[6];   # Delta WtBytes
    }
    $HoA{$pid} = [ @pval ];	# $pid is key to this Hash of Array

    $allpids{$pid} = 1;	# hash for all current processes
  }

  foreach (keys %HoA) {
    if (! exists $allpids{$_}) { # this process has disappeared, clean the hashes
      delete $HoA{$_};
      delete $dltrb{$_}; delete $dltwb{$_};
    }
  }

    if (defined $show) {	# prevent printing all 0's the first time around
      $n = 0;
      #print "--PID ProcName------------ -------Rds -DltRds ------Wts DltW ------RdBytes DltRBts -----WtByts DtWB\n";
      my $totalinput = "  PID ProcName                   RdBytes       DltRBts       WtBytes       DltWBts";
      my $coloredText = colored($totalinput, 'bold underline');
      print $coloredText."\n";

      if ($opt_k eq "rb") {   # sort on delta rbytes
        foreach (sort { $dltrb{$b} <=> $dltrb{$a} } keys %dltrb)
          { write; last if ++$n == $opt_n; }
      }
      elsif ($opt_k eq "wb") { # sort on delta wbytes
        foreach (sort { $dltwb{$b} <=> $dltwb{$a} } keys %dltwb)
          { write; last if ++$n == $opt_n; }
      }
      elsif ($opt_k eq "RB") { # sort on rbytes
        foreach (sort { $HoA{$b}[5] <=> $HoA{$a}[5] } keys %HoA)
          { write; last if ++$n == $opt_n; }
      }
      elsif ($opt_k eq "WB") { # sort on wbytes
        foreach (sort { $HoA{$b}[6] <=> $HoA{$a}[6] } keys %HoA)
          { write; last if ++$n == $opt_n; }
      }
   }
   $show = 1;
   sleep $opt_s;
}

