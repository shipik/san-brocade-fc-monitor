# san-brocade-fc-monitor
Brocade SAN FC switches monitoring health check script

NAME

    check_brocade_fc.pl - Brocade SAN FC switches monitoring check script

AUTHOR

    Vladimir Shapovalov <shapovalov@gmail.com>

SYNOPSIS

    check_brocade_fc.pl CHECK_COMMAND [SWITCH_IP/NAME] [USER] [PASS]

CHECK_COMMAND

    check_health
         Displays the overall status for a switch.

DESCRIPTION

    Script uses Expect to login to SAN switch via ssh. There is no
    additional software required.

      21.04.20 V0.1 (vs): Initial version
      22.04.20 V1.0 (vs): check_health (switchstatusshow) implemented
      20.05.20 V1.1 (vs): minor bug fixing

LICENSE

    MIT License - feel free!

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

EXAMPLES

    #> check_brocade_fc.pl check_health fc-brocade-switch.mycompany.net monitor monitor123

    Output:

     OK! Switch status HEALTHY (All ports are healthy)
     CRITICAL! Switch status DOWN (check 'switchstatusshow'),
     WARNING!  Switch status MARGINAL (check 'switchstatusshow'),
     UNKNOWN!  Switch status UNKNOWN (check 'switchstatusshow'),

