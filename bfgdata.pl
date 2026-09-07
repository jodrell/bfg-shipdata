#!/usr/bin/env perl
# ABSTRACT: Generate static ship profile HTML pages using data from The_MonkeyKing's Gothic Fleet Registry. 
use Cwd qw(getcwd abs_path);
use Data::Mirror qw(mirror_file mirror_str);
use File::Basename qw(dirname);
use File::Glob qw(:bsd_glob);
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use File::Slurp;
use File::Spec;
use HTML5::DOM;
use Image::Size;
use JSON::XS;
use Lingua::EN::Titlecase;
use Template::Liquid;
use common::sense;

my $dir     = getcwd();
my $tc      = Lingua::EN::Titlecase->new;
my $tpl     = Template::Liquid->parse(join('', read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), q{template.tpl}))));
my $css     = join('', read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), q{style.css})));
my $html    = mirror_str(q{https://bfgtools.kuldare.com/});
my $doc     = HTML5::DOM->new->parse($html);
my $json    = $doc->getElementById(q{bfgdata})->textContent;
my $data    = JSON::XS->new->utf8->decode($json);

my $book    = mirror_file(q{https://raw.githubusercontent.com/jodrell/battlefleet-game.org/refs/heads/main/src/BFG%20Remastered%20Official%20Fleets_WIP.pdf});

foreach my $ship (values(%{$data->{ships}})) {

    my $slug = lc(sprintf(q{%s-%s}, $ship->{fl}, $ship->{nm}));
    $slug =~ s/ /-/g;
    $slug =~ s/[^a-z0-9\-\.]//g;

    foreach (qw(fl nm tl)) {
        $ship->{$_} = $tc->title($ship->{$_});
    }

    foreach (qw(sr op)) {
        $ship->{$_} =~ s/•/\n•/g;
        $ship->{$_} =~ s/^\n//g;
        $ship->{$_} =~ s/\n/<br>\n/g;
    }

    my $img = File::Spec->catfile(getcwd(), sprintf(q{%s.png}, $slug));
    my $file = File::Spec->catfile(getcwd(), sprintf(q{%s.html}, $slug));

    write_file($file, $tpl->render(ship => $ship, style => $css, image => $img)) unless (-e $img);

    next if (-e $img);

    my $imgdir = tempdir();

    chdir($imgdir);

    system(
        q{pdfimages},
        q{-f} => $ship->{pg},
        q{-l} => $ship->{pg},
        q{-png},
        $book,
        q{image},
    );

    chdir($dir);

    my @images = sort(bsd_glob(File::Spec->catfile($imgdir, q{*.png})));

    # delete the background image
    unlink(shift(@images)) if (3 == scalar(@images));

    system(
        qw(magick),
        $images[0],
        '(',
        $images[1],
        '-resize',
        sprintf(q{%ux%u}, imgsize($images[0])),
        ')',
        qw(-compose CopyOpacity -composite),
        $img,
    );

    remove_tree($imgdir);

    system(q{open}, $file);
}
