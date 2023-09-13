#!/usr/bin/perl

use strict;
use warnings;

my $container = shift // 'valheim.service';
my $currentcount = 0;
my $i = 0;
my $line = '';
my @lineArr = [];
my $usercount = 0;
my $logdate;
my $logtime;
my $userid;
my $sessionid;
my %userlog;

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
    next if ("$sessionid" eq '0:0');
    $userlog{$sessionid}{'userid'}=$userid;
    $userlog{$sessionid}{'logon'}=$logdate.".".$logtime;
    $userlog{$sessionid}{'logoff'}="STILL LOGGED IN";
    $usercount += 1;
    $userlog{$sessionid}{'logoncount'} = $usercount;
    $userlog{$sessionid}{'logoffcount'} = $usercount;
    #print "logdate $logdate logtime $logtime userid $userid sessionid $sessionid count $usercount\n"
  }
  # if the line contains "Destroying abandoned non persistent zdo", then this
  # is a termination of an existing session, referenced by the sessionid.
  elsif ($line =~ m/Destroying abandoned non persistent zdo /) {
    @lineArr = split(/\s+/, $line);
    ($logdate, $logtime, $sessionid)=@lineArr[5, 6, 12];
    # Note that there can be a whole bunch of these lines for a single session
    # termination.  The one we're interested in is one that matches an already
    # existing logon sessionid.
    if (exists $userlog{$sessionid}) {
      # logtime ends in a `:`.  Trim that off.
      chop($logtime);
      $userlog{$sessionid}{'logoff'} = $logdate.".".$logtime;
      $usercount -= 1;
      $userlog{$sessionid}{'logoffcount'} = $usercount;
      #print "logdate $logdate logtime $logtime sessionid $sessionid userid $userid count $usercount\n"
    }
  }
}
close(DOCKERLOG);

# bad hack to sort then print data by date of "event".
# first read entire hash flattened somewhat into an array.  This looks like
# [ datetime_of_event, username, 'logon/out at:', count_current_users ]
# Each sessionid will have a "logged in" event (which includes the date and the 
# userid logged in, and will have a "logged out" event which only has the 
# sessionid.  The userid has to be inferred.
my @printarr;
foreach $sessionid (keys %userlog) {
  @printarr[$i] = [("$userlog{$sessionid}{'logon'}", "$userlog{$sessionid}{'userid'}", 'logon', $userlog{$sessionid}{'logoncount'})]; 
  $i++;
  @printarr[$i] = [("$userlog{$sessionid}{'logoff'}", "$userlog{$sessionid}{'userid'}", 'logoff', $userlog{$sessionid}{'logoffcount'})]; 
  $i++;
}

# sorting can be weird in perl for multidimensional arrays, mostly because the
# arrays are really arrays of references to other arrays.  In this case, I
# constructed the @printarr array to have the "date" as the first field, so
# that's what we sort by - namely the dereferenced value of the first 
# element of the array.
my @by_date = sort {$a->[0] cmp $b->[0]} @printarr;
printf("%-10s %-7s %-20s %-4s\n", "UserId", "Status", "mm/dd/YYYY.HH:MM:SS", "usercount");
for my $row (@by_date) {
  printf("%-10s %-7s %-20s %-4d\n", $row->[1], $row->[2], $row->[0], $row->[3]);
}

if ( $usercount == 1 ) {
  print "there is 1 user logged in\n";
} else {
  print "there are $usercount users logged in\n";
}

