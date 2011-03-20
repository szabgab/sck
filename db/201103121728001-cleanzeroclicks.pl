#!/usr/bin/perl 
use strict;
use warnings;
use Redis;
use Digest::SHA1 qw/sha1_hex/;

my $r = Redis->new(server => "localhost:6701");

{
    print "Reset top10\n";
    $r->del("s:top10");
    my @hk = $r->keys("h:*");
    foreach my $key(@hk) {
        my $clicks = $r->hget($key, "clicks");
        if ($clicks) {
            print "Update top10 : ",$key,"\n";
            $r->zadd("s:top10", $r->hget($key, "clicks_uniq"), $key);
        } else {
            my $pkey = "p:".sha1_hex($r->hget($key, "path"));
            #print "http://sck.to/",$r->hget($key, "path"),"?s=1:",$r->hget($key, "url"),"\n";
            print "Clean : ",$key,"\n";
            $r->del($key);
            print "Clean : ",$pkey,"\n";
            $r->del($pkey);
        }
    }
    print "Reset min letters\n";
    $r->set("c:min_letters", 1);
}

