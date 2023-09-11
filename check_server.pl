#!/usr/bin/perl

use strict;
use warnings;

my $container = shift // 'valheim.service';
my $currentcount = 0;
my $i = 0;
my $line = '';
my @linearr = [];
my $usercount = 0;
my $logdate;
my $logtime;
my $userid;
my $sessionid;
my %userlog;

open DOCKERLOG, "docker logs $container |";
while ($line=<DOCKERLOG>) {
  chomp $line;
  if ($line =~ m/Got character ZDOID from/) {
    @linearr = split(/\s+/, $line);
    ($logdate, $logtime, $userid, $sessionid)=@linearr[5, 6, 11, 13];
    chop($logtime);
    $userlog{$sessionid}{'userid'}=$userid;
    $userlog{$sessionid}{'login'}=$logdate."-".$logtime;
    $userlog{$sessionid}{'logoff'}="NOT YET";
    $usercount += 1;
    $userlog{$sessionid}{'logincount'} = $usercount;
    #print "logdate $logdate logtime $logtime userid $userid sessionid $sessionid count $usercount\n"
  }
  elsif ($line =~ m/Destroying abandoned non persistent zdo /) {
    #print "$line\n";
    @linearr = split(/\s+/, $line);
    ($logdate, $logtime, $sessionid)=@linearr[5, 6, 12];
    chop($logtime);
    if (exists $userlog{$sessionid}) {
      $userlog{$sessionid}{'logoff'}=$logdate."-".$logtime;
      $usercount -= 1;
      $userlog{$sessionid}{'logoffcount'}=$usercount;
      #print "logdate $logdate logtime $logtime sessionid $sessionid userid $userid count $usercount\n"
    }
  }
}
close(DOCKERLOG);

# bad hack to print data by date of "event".
# first read entire hash flattened somewhat into an array.  This looks like
# [ datetime_of_event, username, 'login/out at:', count_current_users ]
# Each sessionid will have a "logged in" event (which includes the date and the 
# userid logged in, and will have a "logged out" event which only has the 
# sessionid.
my @printarr;
foreach $sessionid (keys %userlog) {
  @printarr[$i] = [("$userlog{$sessionid}{'login'}", "$userlog{$sessionid}{'userid'}", 'login', $userlog{$sessionid}{'logincount'})]; 
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
printf("%-10s %-7s %-20s %-4s\n", "UserId", "Status", "Date-Time", "usercount");
for my $row (@by_date) {
  printf("%-10s %-7s %-20s %-4d\n", $row->[1], $row->[2], $row->[0], $row->[3]);
}

if ( $usercount == 1 ) {
  print "there is 1 user logged in\n";
} else {
  print "there are $usercount users logged in\n";
}

