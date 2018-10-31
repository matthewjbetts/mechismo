use strict;
use warnings;

use Fist;

my $app = Fist->apply_default_middlewares(Fist->psgi_app);
$app;

