#!/usr/bin/perl

##################################################
#   Brocade SAN FC switches health check script
##################################################
#   21.04.20 V0.1 (vs): Initial version
#   22.04.20 V1.0 (vs): check_health (switchstatusshow) implemented
#   20.05.20 V1.1 (vs): minor bug fixing
##################################################

=head1 NAME

B<check_brocade_fc.pl> - Brocade SAN FC switches monitoring health check script

=head1 AUTHOR

Vladimir Shapovalov <shapovalov@gmail.com>

=head1 SYNOPSIS

B<check_brocade_fc.pl> CHECK_COMMAND [SWITCH_IP/NAME] [USER] [PASS]

=head1 CHECK_COMMAND

=over 5

=item B<check_health>

Displays the overall status for a switch.

=back

=head1 DESCRIPTION

Script uses Expect to login to SAN switch via ssh. There is no additional software required.

  21.04.20 V0.1 (vs): Initial version
  22.04.20 V1.0 (vs): check_health (switchstatusshow) implemented
  20.05.20 V1.1 (vs): minor bug fixing

=head1 LICENSE

MIT License - feel free!

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 EXAMPLES

=cut

use strict;
use Data::Dumper;
use Expect;

my $VERSION = 'V1.1';
use POSIX qw( strftime );
my $date = strftime("%Y-%m-%d %H:%M:%S", localtime);

my $timeout = 10;
my $srv = "";
my $switchName = '';
my $user = "monitor";
my $pass = "bmonitor";
my $sshOptions = "-oHostKeyAlgorithms=+ssh-dss";
my @params;
my %checkCommands = (
                      'check_health'    => 'switchstatusshow', # Displays switch health.
                    );
my %returnCodes   = (
                      'OK'        => '0',
                      'WARNING'   => '1',
                      'CRITICAL'  => '2',
                      'UNKNOWN'   => '3',
                    );
my $returnState    = 'UNKNOWN';
my $checkCommand = $ARGV[0];
if(!$checkCommand || $checkCommand eq ""){
  print "Incorrect usage: check_brocade_fc.pl CHECK_COMMAND [SWITCH_IP/NAME] [USER] [PASS]\n";
  exit $returnCodes{'CRITICAL'};
}
if(!$checkCommands{$checkCommand}){
  print "Incorrect usage (invalid CHECK_COMMAND): check_brocade_fc.pl CHECK_COMMAND [SWITCH_IP/NAME] [USER] [PASS]\n";
  print "commands:\n".join( "\n", keys(%checkCommands))."\n";
  exit $returnCodes{'CRITICAL'};
}

$srv  = $ARGV[1] if ($ARGV[1]);
$user = $ARGV[2] if ($ARGV[2]);
$pass = $ARGV[3] if ($ARGV[3]);

if(!$srv){
  print "Incorrect usage (invalid SWITCH_IP/NAME): check_brocade_fc.pl CHECK_COMMAND [SWITCH_IP/NAME] [USER] [PASS]\n";
  exit $returnCodes{'CRITICAL'};
}

my $sshStr = "/usr/bin/ssh $sshOptions $user\@$srv";
my $command = $sshStr." ".$checkCommands{$checkCommand};

my $exp = Expect->spawn($command, @params) or die "Cannot spawn $command: $!\n";
$exp->log_stdout(undef);
my $output;
my @out;

@out = $exp->expect($timeout,
           [ qr/assword:/ => sub { my $exp = shift;
                                 $exp->send("$pass\n");
                                 $output = $exp->exp_after;
                                 exp_continue; } ],
           [ qr/sure you want to continue connecting \(yes\/no/i => sub { my $exp = shift;
                                 $exp->send("yes\n");
                                 $output = $exp->exp_after;
                                 exp_continue; } ],
          ) or die("could not spawn... $!");

# replace CRLF with LF
$out[3] =~ s/[\x0A\x0D][\x0A\x0D]/\n/gms;
if($exp->exitstatus() > 0){
  print "ERROR: cannot execute command:\n$command\n$out[3]$out[1]\n";
  exit $returnCodes{'CRITICAL'};
}

if($checkCommand eq "check_health"){

=pod

#> B<check_brocade_fc.pl> check_health fc-brocade-switch.mycompany.net monitor monitor123

Output:

 OK! Switch status HEALTHY (All ports are healthy)
 CRITICAL! Switch status DOWN (check 'switchstatusshow'),
 WARNING!  Switch status MARGINAL (check 'switchstatusshow'),
 UNKNOWN!  Switch status UNKNOWN (check 'switchstatusshow'),

=cut

<<'COMMENT';
#> switchstatusshow

DESCRIPTION
     Use this command to display the overall status for a switch
     that is configured with IPv4 and IPv6 addresses. In
     addition, customers with a Fabric Watch License will be able
     to see the list of unhealthy ports.

     Status values are HEALTHY, MARGINAL, or DOWN.

EXAMPLES

       Switch Health Report                 Report time: 09/11/2006 05:39:28 PM
       Switch Name:    switch
       IP address:     10.32.89.26
       SwitchState:    MARGINAL
       Duration:       80:12

       Power supplies monitor  HEALTHY
       Temperatures monitor    HEALTHY
       Fans monitor            HEALTHY
       Flash monitor           MARGINAL
       Marginal ports monitor  HEALTHY
       Faulty ports monitor    HEALTHY
       Missing SFPs monitor    HEALTHY

     All ports are healthy

SEE ALSO
     switchStatusPolicyShow, switchStatusPolicySet

Fabric OS                   2011-07-16                          2
COMMENT

  $out[3] =~ /\s+Switch\s+Name:\s+(.+)\n/i;
  $switchName = $1;

  my $strOut          = "OK! $switchName Switch status HEALTHY";
  my $strOutFailed    = "CRITICAL! $switchName Switch status DOWN (check 'switchstatusshow') "; 
  my $strOutDegraded  = "WARNING!  $switchName Switch status MARGINAL (check 'switchstatusshow') ";
  my $strOutUnknown   = "UNKNOWN!  $switchName Switch status UNKNOWN (check 'switchstatusshow') ";

  $out[33] = '
       Switch Health Report                 Report time: 09/11/2006 05:39:28 PM
       Switch Name:    switch
       IP address:     10.32.89.26
       SwitchState:    MARGINAL
       Duration:       80:12

       Power supplies monitor  HEALTHY
       Temperatures monitor    HEALTHY
       Fans monitor            HEALTHY
       Flash monitor           MARGINAL
       Marginal ports monitor  HEALTHY
       Faulty ports monitor    HEALTHY
       Missing SFPs monitor    HEALTHY

     All ports are healthy

SEE ALSO
     switchStatusPolicyShow, switchStatusPolicySet

Fabric OS                   2011-07-16                          2';

  $out[3] =~ /\s+SwitchState:\s+(\w+)\s*/i;

  $returnState = 'OK';
  if(uc($1)  eq "DOWN"){
    $strOut =  $strOutFailed." ".$out[3];
    $returnState = 'CRITICAL';
  }
  elsif(uc($1)  eq "MARGINAL"){
    $strOut =  $strOutDegraded." ".$out[3];
    $returnState = 'WARNING';
  }
  elsif(uc($1) eq "HEALTHY"){
    $strOut .= " ($1)" if($out[3] =~ /(All ports are healthy)/i);
    $strOut .= " ($1)" if($out[3] =~ /(Detailed port information is not included)/i);
  }
  else{
    $strOut =  $strOutUnknown." ".$out[3];
    $returnState = 'UNKNOWN';    
  }
  print "$strOut\n";
  $exp->soft_close();
  exit $returnCodes{$returnState};
}
elsif($checkCommand eq "check_node"){

}
else{
  print "Incorrect usage (invalid CHECK_COMMAND): check_brocade_fc.pl CHECK_COMMAND [SWITCH_IP/NAME] [USER] [PASS]\n";
  print "commands:\n".join( "\n", keys(%checkCommands))."\n";
  $exp->soft_close();
  exit $returnCodes{'CRITICAL'};
}

$exp->soft_close();
exit;
