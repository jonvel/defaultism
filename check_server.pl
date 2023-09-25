#!/usr/bin/perl

use strict;
use warnings;

my $container = shift // 'valheim.service';
my $i = 0;
my @lineArr = [];
my $usercount = 0;
my $line;
my $logdate;
my $logtime;
my $userid;
my $sessionid;
my $status;
my $deletesessionid;
my @userlog;
my %activeSessions;

# @userlog = [ name, sessionid, eventype, date, currentusers ]
# eventtype is [ logon, logoff, died ]

printf("%-12s %-7s %-20s %-4s\n", "userid", "status", "Event day.time", "usercount");
printf("%-12s %-7s %-20s %-4s\n", "======", "======", "==============", "=========");
open DOCKERLOG, "docker logs $container |";
while ($line=<DOCKERLOG>) {
  chomp $line;
  # if the line contains "Got character ZDOID from" then this is a new session
  # that has started up.  Includes date, userid and sessionid in the text
  # string (positions 5/6 (date), 11 (userid) 13 (sessionid) starting at 0)
  # Note that the sessionid can look like [-]\d+:\d+ (optiona -, then a number,
  # then a : and then a number.  It's a weird number that seems random in its
  # format.
  if ($line =~ m/Got character ZDOID from/) {
    @lineArr = split(/\s+/, $line);
    ($logdate, $logtime, $userid, $sessionid)=@lineArr[5, 6, 11, 13];
    # logtime ends in a `:`.  Trim that off.
    chop($logtime);
    # the sessionid looks like \d:\d - I'm only really interested in the number
    # before the :, since the number afterwards seems to have other "information"
    # about it, that I don't currently care about.
    ($sessionid, $deletesessionid) = split(/:/, $sessionid);
    if ( "$sessionid" == 0 ) {
      # this means a user died.  Set status to "died"
      $status = "DIED";
      printf("%-12s %-7s %-20s %-4s\n", "$userid", "$status", "$logdate.$logtime", "$usercount");
      #@userlog[$i] = [("$userid", $sessionid, $status, "$logdate.$logtime", "$usercount")];
      $i++;
      next;
    }
    if (exists($activeSessions{$sessionid})) {
      # this occurs if the user died (sessionid _was_ 0:0).  If so, just skip it.
      next;
    }
    $activeSessions{$sessionid} = $userid;
    $status = "logon";
    $usercount += 1;
    #@userlog[$i] = [("$userid", $sessionid, $status, "$logdate.$logtime", "$usercount")];
    printf("%-12s %-7s %-20s %-4s\n", "$userid", "$status", "$logdate.$logtime", "$usercount");
    $i++;
    next;
  }
  # if the line contains "Destroying abandoned non persistent zdo", then this
  # is a termination of an existing session, referenced by the sessionid.
  elsif ($line =~ m/Destroying abandoned non persistent zdo /) {
    @lineArr = split(/\s+/, $line);
    ($logdate, $logtime, $sessionid)=@lineArr[5, 6, 12];
    #chop($logtime);
    ($sessionid, $deletesessionid) = split(/:/, $sessionid);
    unless (exists($activeSessions{$sessionid})) {
      # block of logs seems to have a ton of closing sessions, but all under the same
      # Sessionid, so just skip the others.
      next;
    }
    # logtime ends in a `:`.  Trim that off.
    chop($logtime);
    $userid = $activeSessions{$sessionid};
    $usercount -= 1;
    $status = "logoff";
    #@userlog[$i] = [("$userid", $sessionid, $status, "$logdate.$logtime", "$usercount")];
    $i++;
    delete($activeSessions{$sessionid});
    printf("%-12s %-7s %-20s %-4s\n", $userid, "logoff", "$logdate.$logtime", "$usercount");
    next;
  }
  elsif ($line =~ m/Random event set:/) {
    @lineArr = split(/\s+/, $line);
    # OK, no sessionid, but need somethign to hold set:<creaturetype>
    ($logdate, $logtime, $userid)=@lineArr[5, 6, 9];
    chop($logtime);
    ($deletesessionid, $userid) = split(/:/, $userid);
    printf("%-12s %-7s %-20s %-4s\n", $userid, "RAID!", "$logdate.$logtime", "$usercount");
    next;
  }
}
close(DOCKERLOG);

if (%activeSessions) {
  foreach $sessionid (sort keys %activeSessions) {
    printf("$activeSessions{$sessionid} is still onine\n");
  }
}
