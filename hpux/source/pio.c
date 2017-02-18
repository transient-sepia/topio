/*
pio (Process I/O, Ver 1.1): Process I/O, shows I/O statistics for processes.
(C) Yong Huang, 2006
yong321.freeshell.org/freeware/pio.html
Thanks to Don Morris and Christof Meerwald for helping with HPUX port
http://groups.google.com/group/comp.sys.hp.hpux/browse_frm/thread/fa83e5a31c9864a6
*/

#include <stdio.h>
#include <sys/pstat.h>

static char *command;
void probe_one(pid_t);
void print_usage(void);
void probe_all(void);

int nl = 1;

main(int argc, char **argv)
{
  pid_t pid;
  int hdr = 1, probeall = 0, i;

  if ((command = (char *)strrchr(argv[0], '/')) != NULL)
    command++;
  else
    command = argv[0];

  if (argc <= 1)
  {
    print_usage();
    exit(1);
  }

  while ((i = getopt(argc, argv, "HhnAp:")) != EOF)
   {
    switch(i)
    {
      case 'H':			/* No header */
	hdr = 0;
	break;
      case 'h':			/* Show Help or Usage */
	print_usage();
	exit(1);
	break;
      case 'n':			/* No Newline at line end */
	nl = 0;
	break;
      case 'p':			/* Process to be Probed */
	pid = atoi(optarg);
	break;
      case 'A':
	probeall = 1;		/* All processes to be probed */
	pid = 0;
	hdr = 0;
	break;
     }
   }

  if (hdr == 1)
    printf("PID\tComm\tInpOps\tOutpOps\tMjPgFlt\n");

  if (pid)
    probe_one(pid);
  else if (probeall)
    probe_all();

  exit(0);
}

void probe_one(pid_t pid)
{
  struct pst_status pst;

  if (pstat_getproc(&pst, sizeof(pst), (size_t)0, pid) != -1)
    //printf("%d\t%s\t%lu\t%lu\t%lu\n", (int)pst.pst_pid, pst.pst_ucomm, (long)pst.pst_inblock, (long)pst.pst_oublock, (long)pst.pst_majorfaults);
    printf("%d\t%s\t%lu\t%lu\t%lu\n", (int)pst.pst_pid, pst.pst_cmd, (long)pst.pst_inblock, (long)pst.pst_oublock, (long)pst.pst_majorfaults);
  else
    perror("pstat_getproc");

  if (nl == 1)
    printf("\n");
}

void probe_all()
{ /* modified from Example 5 of `man pstat` */
#define BURST ((size_t)10)

  struct pst_status pst[BURST];
  int i, count;
  int idx = 0; /* index within the context */

  /* loop until count == 0, will occur when all have been returned */
  while ((count=pstat_getproc(pst, sizeof(pst[0]),BURST,idx))>0) {
    /* got count (max of BURST) this time. process them */
    for (i = 0; i < count; i++) {
      //printf("%d\t%s\t%lu\t%lu\t%lu\n", (int)pst[i].pst_pid, pst[i].pst_ucomm, (long)pst[i].pst_inblock, (long)pst[i].pst_oublock, (long)pst[i].pst_majorfaults);
      printf("%d\t%s\t%lu\t%lu\t%lu\n", (int)pst[i].pst_pid, pst[i].pst_cmd, (long)pst[i].pst_inblock, (long)pst[i].pst_oublock, (long)pst[i].pst_majorfaults);
    }

    /*
     * now go back and do it again, using the next index after
     * the current 'burst'
     */
    idx = pst[count-1].pst_idx + 1;
  }

  if (count == -1)
    perror("pstat_getproc()");

#undef BURST
}

void print_usage()
{
  (void) fprintf(stderr, "Usage: %s [-Hhn] -p <PID>\n\t-H: no header\n\t-h: help\n\t-n: no newline at line end\n\t-p: process ID follows\n\t-A: print I/O stats for all processes\n", command);
}

