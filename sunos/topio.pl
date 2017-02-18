#!/usr/bin/env perl
# Modify the first line and the line below ($PIO =...) as needed.
# topio 1.4: This Perl script launches pio (Process I/O) to probe all processes
# on the system and sort them based on absolute or delta Read/Write Characters
# for each process. Hopefully major page faults can be used as an indicator of
# how much I/O is physical, i.e. against disks instead of page cache.
# (C) Yong Huang, 2002-2004,2010
# http://yong321.freeshell.org/freeware/pio.html

$PIO = "./pio";	# path to pio; absolute path is recommended, e.g., "/usr/local/bin/pio"

########## No need to modify below this line but hacking is welcome. ##########

use Getopt::Std;
use Term::ANSIColor;

getopts('ds:n:h');

if (defined $opt_h) {
  print "Usage: $0 [-d] [-s Delay] [-n Top_n_lines] [-h]
    -d: Show delta Read/Write Characters and delta Major Page Faults between
        calls to pio
    -s: Number of seconds delay between calls (default 5)
    -n: Only show processes of top n RWChar or (if -d) deltaRWChar (default 10)
    -h: Show this Usage\n";
  exit;
}

$opt_s = 5 if !defined $opt_s;
$opt_n = 10 if !defined $opt_n;

if (defined $opt_d) {
  # Format to be used by write:
  # pid, rwchars, delta chars, page faults, delta faults, command
format = 
@>>>> @>>>>>>>>>>> @>>>>>>>>> @>>>>>>>>>> @>>>>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$_,   $HoA{$_}[2], $dltio{$_},$HoA{$_}[3],$dltmf{$_},$HoA{$_}[4]
.

  undef $/;
  while (1) {
    $_ = qx{$PIO -A};	# slurp in all pio -A output

    @lines = split /\n/;
    %allpids = ();	# @allpids is used to delete pid's that're gone between
			# calls to pio
    foreach (@lines) {
      # Each line is: pid InpBlock OutpBlk RWChar MjPgFlt Comm
      next unless /^(\d+)\t(.*)/;
      $pid = $1;
      # @pval: all last 5 columns of one line, i.e. values for this pid
      # pval[0]:InpBlk; [1]:OutpBlk; [2]:RWChar; [3]:MjPgFlt; [4]:Comm
      @pval = split /\t/,$2;

      if (defined $HoA{$pid}[2]) { # it's not defined in first iteration
        $dltio{$pid} = $pval[2] - $HoA{$pid}[2];
        $dltmf{$pid} = $pval[3] - $HoA{$pid}[3];
      }
      $HoA{$pid} = [ @pval ];	# $pid is key to this Hash of Array

      $allpids{$pid} = 1;	# hash for all current processes
    }

    foreach (keys %HoA) {
      if (! exists $allpids{$_}) { # this process has disappeared, clean the hashes
         delete $HoA{$_}; delete $dltio{$_}; delete $dltmf{$_};
      }
    }

    if (defined $show) {	# prevent printing all 0's the first time around
      $n = 0;
      # Even though %HoA also has InpBlock,OutpBlk, their values don't look
      # interesting to me, especially their delta values. But let's put them in
      # %HoA for easy reading and future expansion.
      # print "--PID-------RWChar-----DltRWC-----MjPgFlt-DltMPF Command------------------------\n";
      my $totalinput = "  PID       RWChar     DltRWC     MjPgFlt DltMPF Command                        ";
      my $coloredText = colored($totalinput, 'bold underline');
      print $coloredText."\n";

      # assuming sort on dltio instead of dltmf
      foreach (sort { $dltio{$b} <=> $dltio{$a} } keys %dltio) {
        write;
        last if ++$n == $opt_n;
      }
    }
    $show = 1;
    sleep $opt_s;
  }
}
else {
  # Why reinvent the wheel? Using shell sort command is easier in this case.
  # Change sort -k 4,4 to 5,5 if you like to sort on MjPgFlt.
  warn "** WARNING: Running topio without -d may not be **
  ** what you want. Type topio -h for help.       **\n";
  system("
    while true; do
      echo 'PID\tInpBlk\tOutpBlk\tRWChar\tMjPgFlt\tCommand'
      $PIO -A | sort -nr -k 4,4 | head -$opt_n
      sleep $opt_s
    done
  ");
}

