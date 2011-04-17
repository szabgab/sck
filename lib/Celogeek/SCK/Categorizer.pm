package Celogeek::SCK::Categorizer;

# ABSTRACT: Celogeek::SCK::Categorizer - Categorize link base on their extracted word

use strict;
use warnings;
use 5.012;

use Data::Dumper;
use Carp;

#load YML and reverse
my $_word_to_categories = {};
{
    my $config = Config::YAML->new(config => 'category.yml');
    while(my ($key, $value) = each %$config) {
        next if substr($key, 0, 1) eq '_';
        foreach my $word(@$value) {
            $_word_to_categories->{$word} //= [];
            push @{$_word_to_categories->{$word}}, $key;
        }
    }
}

=method get_category

Return best category for your word_score

=cut
sub get_category {
    my ($self, $word_score) = @_;
    croak "Missing word_score params" unless defined $word_score;
    my %category_score = ();

    while(my ($word, $score) = each %$word_score) {
        if (defined $_word_to_categories->{$word}) {
            say "Found word $word";
            foreach my $category(@{$_word_to_categories->{$word}}) {
                $category_score{$category} += $score;
            }
        } else {
            say "Unknown word $word";
        }
    }

    say Data::Dumper::Dumper \%category_score;

    return "N/A";
}
