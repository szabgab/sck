package Celogeek::URL;
use strict;
use Moose;
use Data::Rand qw/rand_data_string/;
use Digest::SHA1 qw/sha1_hex/;
use File::Basename;
use File::Path;
use File::Spec;
use DateTime;
use Carp;
use WWW::GetPageTitle;

has 'redis' => (
    'is' => 'rw',
    'isa' => 'Redis',
    'required' => 1
);

has 'generated_times' => (
    'is' => 'rw',
    'isa' => 'Int',
    'required' => 1,
    'default' => 0
);

has 'max_generated_times' => (
    'is' => 'rw',
    'isa' => 'Int',
    'required' => 1,
    'default' => 0
);

has 'max_letters' => (
    is => 'rw',
    'isa' => 'Int',
    'required' => 1,
    'default' => 1
);

sub BUILD {
    my $self = shift;
    $self->redis->incr('c:min_letters') unless $self->redis->get('c:min_letters');
};

sub generate {
    my $self = shift;
    my $letters = $self->redis->get('c:min_letters');
    return "" if $self->max_letters < $letters;

    my @kb = ('a'..'z', 'A'..'Z', 0..9, '/');

    my ($key);
    my $ok;
    while($self->max_generated_times > $self->generated_times) {
        $key = rand_data_string($letters, \@kb); 
        $key =~ s/\/+/\//g; $key =~ s/\/$//; $key =~ s/^\///;
        next if $key eq ''; #one letter, only a /
        $self->generated_times($self->generated_times + 1);
        unless ($self->redis->exists($self->_path_key($key))) {
            $ok = 1;
            last;
        } 
    }
    if ($ok) {
        return $key;
    } else {
        $self->max_generated_times($self->max_generated_times + $self->generated_times);
        $self->redis->incr('c:min_letters');
        return $self->generate();
    }
}

sub shorten {
    my $self = shift;
    my $url = shift;
    return "BAD URL" unless $url =~ /^https?:\/\//;
    my $hash_key = $self->_hash_key($url);

    if ($self->redis->exists($hash_key)) {
        return $self->redis->hget($hash_key, "path");
    } else {
        $self->generated_times(0);
        my $short = $self->generate();
        if ($short ne "") {
            $self->_save($hash_key, {
                    url => $url,
                    path => $short,
                    clicks => 0,
                    clicks_uniq => 0,
                    created_at => DateTime->now,
                    last_accessed_at => DateTime->now
                });
            $self->redis->set($self->_path_key($short), $hash_key);
            return $short;
        } else {
            return "NO WAY TO SHORTEN";
        }
    }
}

sub longen {
    my $self = shift;
    my $key = shift;
    my $clicks = shift;
    my $clicks_uniq = shift;

    if ($self->redis->exists($self->_path_key($key))) {
        my $hash_key = $self->redis->get($self->_path_key($key));
        if ($clicks) {
            $self->redis->hincrby($hash_key, "clicks", 1);
            if ($clicks_uniq) {
                $self->redis->hincrby($hash_key, "clicks_uniq", 1);
                $self->redis->zincrby("s:top10", 1, $hash_key);
            }
            $self->_save($hash_key, { last_accessed_at => DateTime->now });
        }
        return $self->redis->hget($hash_key, "url");
    } else {
        return "";
    }
}

sub stats {
    my $self = shift;
    my $key = shift;
    my $opts = shift || {};
    $opts->{date} ||= "%c UTC";

    if ($self->redis->exists($self->_path_key($key))) {
        my $data = $self->_get($self->redis->get($self->_path_key($key)));
        foreach my $d(qw/created_at last_accessed_at/) {
            if ($data->{$d}) {
                $data->{$d} = $self->_datetime($data->{$d})->strftime($opts->{date});
            }
        }
        return $data;
    } else {
        return {};
    }
}

sub _datetime {
    my $self = shift;
    my $date = shift;
    my ($year,$month,$day,$hour,$minute,$second) = ($date =~ /^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/);
    if ($year) {
        return DateTime->new(
            year => $year,
            month => $month,
            day => $day,
            hour => $hour,
            minute => $minute,
            second => $second
        );
    } else {
        return DateTime->now;
    }
}

sub _datetime_str {
    my $self = shift;
    my $date = shift;

    return $date->ymd." ".$date->hms;
}

sub _save {
    my $self = shift;
    my $hash_key = shift;
    my $data = shift;

    foreach my $key(keys %$data) {
        my $val = $data->{$key};
        if (ref $val eq 'DateTime') {
            $data->{$key} = $self->_datetime_str($val);
        }
    }
    $self->redis->hmset($hash_key, %$data);
}

sub _get {
    my $self = shift;
    my $hash_key = shift;
    my %data = $self->redis->exists($hash_key) ? $self->redis->hgetall($hash_key) : ();
    return \%data;
}

sub _redis_key {
    my $self = shift;
    my $prefix = shift;
    my $key = shift;
    return $prefix.":".sha1_hex($key);
}

sub _path_key {
    my $self = shift;
    my $path = shift;
    return $self->_redis_key("p", $path);
}

sub _hash_key {
    my $self = shift;
    my $url = shift;
    return $self->_redis_key("h", $url);
}

sub _title_key {
    my $self = shift;
    my $url = shift;
    return $self->_redis_key("t", $url);
}

sub top10 {
    my $self = shift;
    my @members = $self->redis->zrevrange('s:top10', 0, 9,'WITHSCORES');
    my @top10_data = ();
    for(my $i=0; $i<@members; $i+=2) {
        #fetch data
        my $data = {score => $members[$i+1]};
        $data->{$_} = $self->redis->hget($members[$i], $_) for qw/url path/;
        my $title_key = $self->_title_key($data->{url});
        my $hash_key = $self->_hash_key($data->{url});
        $data->{title} = $self->redis->get($title_key);
        $data->{alt} = "";

            ### too many try, never try again
        if ($data->{title}) {
            #if title exist, use it
            if ($data->{title} ne $data->{url}) {
                $self->redis->hdel($hash_key, 'missing_title_tries');
                $data->{alt} = $data->{title}." - ";
            }
        } else {
            $data->{title} = $data->{url};
            #try to fetch title in asynchrone mode
            if (($self->redis->hget($hash_key, 'missing_title_tries') || 0) < 5) {
                $self->redis->hincrby($hash_key, 'missing_title_tries', 1);
                $data->{missing_title} = 1;
            }
        }
        $data->{alt} .= $data->{url}." - Score ".$data->{score};
        push @top10_data, $data;
    }
    return \@top10_data;
}

sub missing_title {
    my $self = shift;
    my $url = shift;
    my $tk = $self->_title_key($url);
    my $expire = 24 * 3600 * 3; #3 day
    unless ($self->redis->exists($tk)) {
        #set url as title to prevent multiset
        #lock 15s to prevent multicall to the same dest
        #if this part crash, it will be allow to retry in a short time
        $self->redis->setex($tk, 60, $url); 
        eval {
            ### WWW::GetPageTitle react bad if page are not html
            local $SIG{__WARN__};
            my $gt = WWW::GetPageTitle->new;
            if ($gt->get_title($url)) {
                $self->redis->setex($tk, $expire, $gt->title);
            }
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable();
1;
