/*
pio (Process I/O, Ver 1.4): Process I/O, shows I/O statistics for processes.
(C) Yong Huang, 2002-2004
yong321.freeshell.org/freeware/pio.html
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <procfs.h>
#include <sys/types.h>
#include <dirent.h>

static char *command;
static int probe_one(pid_t);
void print_usage(void);
void probe_all(void);

int nl = 1;

main(int argc, char **argv)
{
  pid_t pid;
  int hdr = 1, probeall = 0, i;

  if ((command = strrchr(argv[0], '/')) != NULL)
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
    printf("PID\tInpBlk\tOutpBlk\tRWChar\tMjPgFlt\tComm\n");

  if (pid)
    probe_one(pid);
  else if (probeall)
    probe_all();

  exit(0);
}

int probe_one(pid_t pid)
{
  char pathname[100];
  int rval = 0;
  int fd;
  prusage_t prusage;
  psinfo_t  psinfo;

  prusage_t *pup = &prusage;
  psinfo_t  *pip = &psinfo; 

  /* Get all needed statistics */
  (void) sprintf(pathname, "/proc/%d/usage", (int)pid);
  if ((fd = open(pathname, O_RDONLY)) < 0)
  { perror("open usage");
    return (1);
  }
  if (read(fd, &prusage, sizeof (prusage)) != sizeof (prusage))
  { perror("read usage");
    return (2);
  }
  else
  {
    printf("%d\t",  pid);
    printf("%lu\t", pup->pr_inblk); /* input blocks */
    printf("%lu\t", pup->pr_oublk); /* output blocks */
    printf("%lu\t", pup->pr_ioch);  /* chars read and written */
    printf("%lu\t", pup->pr_majf);  /* major page faults */
  }
  (void) close(fd);
  
  /* ps comm is from psinfo.pr_psargs, not prusage. So have to open psinfo. */
  (void) sprintf(pathname, "/proc/%d/psinfo", (int)pid);
  if ((fd = open(pathname, O_RDONLY)) < 0)
  { perror("open psinfo");
    return (1);
  }
  if (read(fd, &psinfo, sizeof (psinfo)) != sizeof (psinfo))
  { perror("read psinfo");
    return (2);
  }
  else
  {
    printf("%s", pip->pr_psargs);
  }
  (void) close(fd);

  if (nl == 1)
    printf("\n");
  return (rval);
}

void probe_all()
{
  pid_t pid = 1;
  DIR *dp;
  struct dirent *d;

  if ((dp = opendir("/proc")) == NULL)
  {
    perror("/proc");
    exit(2);		/* Can't open /proc */
  }
    
  while ((d = readdir(dp)) != NULL)
  {
    pid = atoi(d->d_name);
    if ( pid != 0 )
    {
    probe_one(pid);
    }
  }
}

void print_usage()
{
  (void) fprintf(stderr, "Usage: %s [-Hhn] -p <PID>\n\t-H: no header\n\t-h: help\n\t-n: no newline at line end\n\t-p: process ID follows\n\t-A: print I/O stats for all processes\n", command);
}
