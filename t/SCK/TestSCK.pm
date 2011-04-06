use App::Main;
Dancer::set environment => 'testing';
Dancer::Config->load;
use Dancer::Test;

package TestSCK;
1;
