use 5.012;

use Dancer::Test;
Dancer::set environment => 'testing';
Dancer::Config->load;

use App::Main;
use App::Root;
use App::Stats;
use App::Redirect;

package TestSCK;
1;
