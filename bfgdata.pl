#!/usr/bin/env perl
# ABSTRACT: Generate static Battlefleet Gothic: Remastered ship profile HTML pages using data from The_MonkeyKing's Gothic Fleet Registry. 
use Cwd qw(getcwd abs_path);
use Data::Mirror qw(mirror_file mirror_str);
use File::Basename qw(dirname basename);
use File::Glob qw(:bsd_glob);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use Getopt::Long;
use HTML5::DOM;
use Image::Size;
use JSON::XS;
use Lingua::EN::Titlecase;
use Pod::Usage;
use Template::Liquid;
use common::sense;

my ($extract_images, $generate_images, $generate_ships, $img_src, $help);
pod2usage(1) unless(GetOptions(
    q{extract-to:s} => \$extract_images,
    images          => \$generate_images,
    ships           => \$generate_ships,
    q{image-src:s}  => \$img_src,
    help            => \$help,
));

pod2usage(0) if ($help);
pod2usage("Missing argument") unless ($extract_images || $generate_images || $generate_ships);

my $dir     = getcwd();
my $tc      = Lingua::EN::Titlecase->new;
my $tpl     = Template::Liquid->parse(read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), q{template.tpl})));
my $css     = read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), q{style.css}));
my $html    = mirror_str(q{https://bfgtools.kuldare.com/});
my $doc     = HTML5::DOM->new->parse($html);
my $json    = $doc->getElementById(q{bfgdata})->textContent;
my $data    = JSON::XS->new->utf8->decode($json);
my $book    = mirror_file(q{https://raw.githubusercontent.com/jodrell/battlefleet-game.org/refs/heads/main/src/BFG%20Remastered%20Official%20Fleets_WIP.pdf});
my $imgdir  = $img_src || tempdir();

if ($extract_images) {
    extract_images($extract_images);

} else {
    generate_images()   if ($generate_images);
    generate_html()     if ($generate_ships);

}

say STDERR q{done!};

exit;

sub generate_images {
    extract_images($imgdir) unless ($img_src);

    say STDERR q{generating ship images...};
    foreach my $ship (sort { $a->{pg} <=> $b->{pg} } values(%{$data->{ships}})) {
        generate_image($ship);
    }

    remove_tree($imgdir) unless ($img_src);
}

sub extract_images {
    my $extract_dir = shift;

    printf(STDERR qq{extracting images to %s (this may take a while)...\n}, $extract_dir);

    chdir($extract_dir);

    system(qw(pdfimages -p -png), $book, q{ship});

    chdir($dir);
}

sub generate_image {
    my $ship = shift;

    my $file = slug_to_filename(get_slug($ship), q{png});

    return if (-e $file);

    my $glob = File::Spec->catfile($imgdir, sprintf(q{ship-%03u-*.png}, $ship->{pg}));

    my @images = sort(bsd_glob($glob));

    if (scalar(@images) < 3) {
        printf(STDERR qq{WARNING: found %u images for '%s' for %s %s, need 3\n}, scalar(@images), $glob, $ship->{fl}, $ship->{nm});
        return;
    }

    system(
        qw(magick),
        $images[1],
        '(',
        $images[2],
        '-resize',
        sprintf(q{%ux%u}, imgsize($images[1])),
        ')',
        qw(-compose CopyOpacity -composite),
        $file,
    );

    printf(STDERR qq{wrote %s\n}, $file);
}

sub generate_html {
    say STDERR q{generating ship pages...};

    foreach my $ship (sort { $a->{pg} <=> $b->{pg} } values(%{$data->{ships}})) {
        generate_ship($ship);
    }
}

sub generate_ship {
    my $ship = shift;

    my $slug = get_slug($ship);

    foreach (qw(fl nm tl)) {
        $ship->{$_} = $tc->title($ship->{$_});
    }

    foreach (qw(sr op)) {
        $ship->{$_} =~ s/•/\n•/g;
        $ship->{$_} =~ s/^\n//g;
        $ship->{$_} =~ s/\n/<br>\n/g;
    }

    write_file(
        slug_to_filename($slug, q{html}),
        $tpl->render(
            ship    => $ship,
            style   => $css,
            image   => basename(slug_to_filename($slug, q{png})),
            has_sr  => length($ship->{sr}) > 0,
            has_op  => length($ship->{op}) > 0,
        )
    );
}

sub get_slug {
    my $ship = shift;

    my $slug = lc(sprintf(q{%s-%s}, $ship->{fl}, $ship->{nm}));
    $slug =~ s/ /-/g;
    $slug =~ s/[^a-z0-9\-\.]//g;

    return $slug;
}

sub slug_to_filename {
    my ($slug, $type) = @_;
    return File::Spec->catfile($dir, sprintf(q{%s.%s}, $slug, $type));
}

sub read_file {
    my $fh = IO::File->new(shift, q{r});
    $fh->binmode(q{:utf8});
    my $data = join(q{}, $fh->getlines);
    $fh->close;
    return $data;
}

sub write_file {
    my $fh = IO::File->new(shift, q{w});
    $fh->binmode(q{:utf8});
    $fh->write(pop);
    $fh->close;
    return 1;
}

=pod

=head1 SYNOPSIS

    bfgdata.pl OPTIONS

=head1 OPTIONS

You must specify one of --help, --ships, --images, --extract-to.

=over

=item * --help - show help.

=item * --ships - generate ship profiles in the current directory.

=item * --images - generate ship images in the current directory.

=item * --extract-to=DIR - extract images from the Fleets book into C<DIR> for later use.

=item * --image-SRC=DIR - use the images in C<DIR> instead of extracting them from the Fleets book.

=back

=cut
