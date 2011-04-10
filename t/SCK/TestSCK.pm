use App::Main;
use App::Root;
use App::Stats;
use App::MissingTitle;
use App::Redirect;
Dancer::set environment => 'testing';
Dancer::Config->load;
use Dancer::Test;

package TestSCK;
1;
