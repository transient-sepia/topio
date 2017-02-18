#!/usr/bin/env perl
# Modify the first line and the line below ($PIO =...) as needed.
# topio for HP-UX 1.1: This Perl script launches pio (Process I/O) to probe all
# processes on the system and sort them based on delta Read/Write Operations
# for each process.
# (C) Yong Huang, 2006,2010
# http://yong321.freeshell.org/freeware/pio.html

$PIO = "./pio";	#path to pio; absolute path is recommended, e.g., "/usr/local/bin/pio"

########## No need to modify below this line but hacking is welcome. ##########

use Getopt::Std;
use Term::ANSIColor;

getopts('s:n:k:h');

if (defined $opt_h) {
  print "Usage: $0 [-s Delay] [-n Top_n_lines] [-k sortkey] [-h]
    -s: Number of seconds delay between calls (default 5)
    -n: Only show top n processes (default 10)
    -k: sort key (default DltR)
        R: DltR (delta reads); I: Reads;
        W: DltW (delta writes); O: Writes
        f: DltPF (delta page faults); F: PF
    -h: Show this Usage
    Example (show top 3 processes every 2 seconds, sorted by DltW): perl $0 -s2 -n3 -kW\n";
  exit;
}

$opt_s = 5 if !defined $opt_s;
$opt_n = 10 if !defined $opt_n;
$opt_k = "R" if !defined $opt_k;

# Format to be used by write:
# pid, name, reads, delta reads, writes, delta writes, pagefaults, delta pagefaults
format =
@>>>> @<<<<<<<<<<<<<<<< @>>>>>>>>> @>>>>>> @>>>>>>>>> @>>>>>> @>>>>>>>>> @>>>>>>
$_,$HoA{$_}[0],$HoA{$_}[1],$dltrd{$_},$HoA{$_}[2],$dltwt{$_},$HoA{$_}[3],$dltpf{$_}
.

undef $/;
while (1) {
  $_ = qx{$PIO -A};	# slurp in all pio -A output

  @lines = split /\n/;
  %allpids = ();	# @allpids is used to delete pid's that're gone between
			# calls to pio
  foreach (@lines) {
    # Each line is: pid ProcName Rds Wts MjPgFlt
    next unless /^(\d+)\t(.*)/;
    $pid = $1;
    # @pval: all last 4 columns of one line, i.e. values for this pid
    # pval[0]:ProcName; [1]:Rds; [2]:Wts; [3]:MjPgFlt
    @pval = split /\t/,$2;
    #foreach my $hehe (@pval) { print "line: $hehe\n"; }

    if (defined $HoA{$pid}[1]) { # it's not defined in first iteration
      $dltrd{$pid} = $pval[1] - $HoA{$pid}[1];    #Delta Rds
      $dltwt{$pid} = $pval[2] - $HoA{$pid}[2];    #Delta Wts
      $dltpf{$pid} = $pval[3] - $HoA{$pid}[3];    #Delta PFs
    }
    $HoA{$pid} = [ @pval ];	# $pid is key to this Hash of Array

    $allpids{$pid} = 1;	# hash for all current processes
  }

  foreach (keys %HoA) {
    if (! exists $allpids{$_}) { # this process has disappeared, clean the hashes
      delete $HoA{$pid}; delete $dltrd{$_};
      delete $dltwt{$_}; delete $dltpf{$_};
    }
  }

  if (defined $show) {	# prevent printing all 0's the first time around
    $n = 0;
    #print "--PID ProcName--------- -----Reads ---DltR -----Writs ---DltW -----PFlts ---DltF\n";
    my $totalinput = "  PID ProcName               Reads    DltR      Writs    DltW      PFlts    DltF";
    my $coloredText = colored($totalinput, 'bold underline');
    print $coloredText."\n";

    if ($opt_k eq "R") { # sort on delta reads
      foreach (sort { $dltrd{$b} <=> $dltrd{$a} } keys %dltrd)
        { write; last if ++$n == $opt_n; }
    }
    elsif ($opt_k eq "I") { # sort on reads
      foreach (sort { $HoA{$b}[1] <=> $HoA{$a}[1] } keys %HoA)
        { write; last if ++$n == $opt_n; }
    }
    elsif ($opt_k eq "W") { # sort on delta writes
      foreach (sort { $dltwt{$b} <=> $dltwt{$a} } keys %dltwt)
        { write; last if ++$n == $opt_n; }
    }
    elsif ($opt_k eq "O") { # sort on writes
      foreach (sort { $HoA{$b}[2] <=> $HoA{$a}[2] } keys %HoA)
        { write; last if ++$n == $opt_n; }
    }
    elsif ($opt_k eq "f") { # sort on delta pagefaults
      foreach (sort { $dltpf{$b} <=> $dltpf{$a} } keys %dltpf)
        { write; last if ++$n == $opt_n; }
    }
    elsif ($opt_k eq "F") { # sort on pagefaults
      foreach (sort { $HoA{$b}[3] <=> $HoA{$a}[3] } keys %HoA)
        { write; last if ++$n == $opt_n; }
    }

  }
  $show = 1;

  sleep $opt_s;
}

