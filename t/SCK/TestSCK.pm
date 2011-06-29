use 5.014;

use Dancer::Test;
Dancer::set environment => 'testing';
Dancer::Config->load;

use App::Main;
use App::Root;
use App::Redirect;

package TestSCK;
1;
