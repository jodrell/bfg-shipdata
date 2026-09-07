#!/usr/bin/env perl
# ABSTRACT: Generate static ship profile HTML pages using data from The_MonkeyKing's Gothic Fleet Registry. 
use Data::Mirror qw(mirror_str);
use File::Slurp;
use File::Spec;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use HTML5::DOM;
use JSON::XS;
use Lingua::EN::Titlecase;
use Template::Liquid;
use common::sense;

my $tc      = Lingua::EN::Titlecase->new;
my $tpl     = Template::Liquid->parse(join('', read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), q{template.tpl}))));
my $css     = join('', read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), q{style.css})));
my $html    = mirror_str(q{https://bfgtools.kuldare.com/});
my $doc     = HTML5::DOM->new->parse($html);
my $json    = $doc->getElementById(q{bfgdata})->textContent;
my $data    = JSON::XS->new->utf8->decode($json);

foreach my $ship (values(%{$data->{ships}})) {

    foreach (qw(fl nm tl)) {
        $ship->{$_} = $tc->title($ship->{$_});
    }

    foreach (qw(sr op)) {
        $ship->{$_} =~ s/•/\n•/g;
        $ship->{$_} =~ s/^\n//g;
        $ship->{$_} =~ s/\n/<br>\n/g;
    }

    my $slug = lc(sprintf(q{%s-%s}, $ship->{fl}, $ship->{nm}));
    $slug =~ s/ /-/g;
    $slug =~ s/[^a-z0-9\-\.]//g;

    write_file(sprintf(q{%s.html}, $slug), $tpl->render(ship => $ship, style => $css));
}
