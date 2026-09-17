#!/usr/bin/env perl
# ABSTRACT: Generate static Battlefleet Gothic: Remastered ship profile HTML
# pages using data from The_MonkeyKing's Gothic Fleet Registry. 
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

my ($dir, $extract_images, $generate_images, $generate_pages, $img_src, $help);
pod2usage(1) unless(GetOptions(
    q{output-dir:s} => \$dir,
    q{extract-to:s} => \$extract_images,
    images          => \$generate_images,
    pages           => \$generate_pages,
    q{image-src:s}  => \$img_src,
    help            => \$help,
));

pod2usage(0) if ($help);
pod2usage("Missing argument") unless ($extract_images || $generate_images || $generate_pages);

my $tc      = Lingua::EN::Titlecase->new;
my $tpl     = Template::Liquid->parse(read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), q{template.tpl})));
my $i_tpl   = Template::Liquid->parse(read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), q{index.tpl})));
my $css     = read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), q{style.css}));
my $imgdir  = $img_src || tempdir();

if ($dir) {
    $dir = abs_path($dir);
    chdir($dir);

} else {
    $dir = abs_path(getcwd());

}

say STDERR q{mirroring ship data...};
my $html = mirror_str(q{https://bfgtools.kuldare.com/});

say STDERR q{extracting ship data...};
my $doc  = HTML5::DOM->new->parse($html);
my $json = $doc->getElementById(q{bfgdata})->textContent;
my $data = JSON::XS->new->utf8->decode($json);

munge_data();

say STDERR q{mirroring Fleets Book...};
my $book = mirror_file(q{https://raw.githubusercontent.com/jodrell/battlefleet-game.org/refs/heads/main/src/BFG%20Remastered%20Official%20Fleets_WIP.pdf});

extract_images($extract_images) if ($extract_images);

printf(STDERR qq{files will be written to '%s'\n}, $dir) if ($generate_images || $generate_pages);

generate_images()   if ($generate_images);
generate_pages()    if ($generate_pages);

say STDERR q{done!};

exit;

sub munge_data {
    foreach my $ship (sort { $a->{pg} <=> $b->{pg} } values(%{$data->{ships}})) {
        $ship->{fl} = munge_fleet_name($ship->{fl});
    }
}

sub munge_fleet_name {
    my $fleet = shift;
    return q{TAU}      if ($fleet =~ /^tau/i);
    return q{TYRANIDS} if ($fleet =~ /^tyranid/i);
    return q{NECRONS}  if ($fleet =~ /^necron/i);
    return $fleet;
}

sub extract_images {
    my $extract_dir = shift;

    printf(STDERR qq{extracting images to %s (this may take a while)...\n}, $extract_dir);

    chdir($extract_dir);

    system(qw(pdfimages -p -png), $book, q{ship}) == 0 || die($?);

    chdir($dir);
}

sub generate_images {
    extract_images($imgdir) unless ($img_src);

    say STDERR q{generating ship images...};
    foreach my $ship (sort { $a->{pg} <=> $b->{pg} } values(%{$data->{ships}})) {
        generate_image($ship);
    }

    remove_tree($imgdir) unless ($img_src);
}

sub generate_image {
    my $ship = shift;

    my @images = sort(bsd_glob(File::Spec->catfile($imgdir, sprintf(q{ship-%03u-*.png}, $ship->{pg}))));

    if (scalar(@images) < 3) {
        printf(STDERR qq{WARNING: found %u images for '%s' for %s (%s), need 3\n}, scalar(@images), $tc->title($ship->{nm}), $tc->title($ship->{fl}));
        return;
    }

    my $file = filename($dir, $ship, q{png});

    make_path(dirname($file)) unless (-e dirname($file));

    system(
        qw(magick),
        $images[1],
        q{(},
        $images[2],
        q{-resize},
        sprintf(q{%ux%u}, imgsize($images[1])),
        q{)},
        qw(-compose CopyOpacity -composite),
        $file,
    );

    printf(STDERR qq{wrote %s\n}, $file);
}

sub generate_pages {
    say STDERR q{generating ship pages...};

    foreach my $ship (sort { $a->{pg} <=> $b->{pg} } values(%{$data->{ships}})) {
        generate_ship($ship);
    }

    generate_index();
}

sub generate_ship {
    my $ship = shift;

    foreach (qw(fl nm tl)) {
        $ship->{$_} = $tc->title($ship->{$_});
    }

    foreach (qw(sr op)) {
        $ship->{$_} =~ s/•/\n•/g;
        $ship->{$_} =~ s/^\n//g;
        $ship->{$_} =~ s/\n/<br>\n/g;
    }

    write_file(
        filename($dir, $ship, q{html}),
        $tpl->render(
            ship    => $ship,
            style   => $css,
            image   => basename(filename($dir, $ship, q{png})),
            has_sr  => length($ship->{sr}) > 0,
            has_op  => length($ship->{op}) > 0,
        )
    );
}

sub generate_index {
    my $fleets = {};
    foreach my $ship (values(%{$data->{ships}})) {
        if (!exists($fleets->{$ship->{fl}})) {
            $fleets->{$ship->{fl}} = {
                name    => $tc->title($ship->{fl}),
                ships   => {
                    Defence     => [],
                    Escort      => [],
                    Cruiser     => [],
                    Battleship  => [],
                    Ground      => [],
                },
            }
        }

        push(@{$fleets->{$ship->{fl}}->{ships}->{$ship->{ty}}}, {
            name    => $tc->title($ship->{nm}),
            href    => filename(q{.}, $ship, q{html}),
        });
    }

    my %order = (
        q{Imperial Navy}        => 1,
        q{Space Marines}        => 2,
        q{Adeptus Mechanicus}   => 3,
        q{Inquisition}          => 4,
        q{Rogue Traders}        => 5,
        q{Chaos}                => 6,
        q{Eldar}                => 7,
        q{Dark Eldar}           => 8,
        q{Orks}                 => 9,
        q{Necrons}              => 10,
        q{Tyranids}             => 11,
        q{Tau}                  => 12,
        q{Demiurg}              => 13,
        q{Kroot}                => 14,
        q{Nicassar}             => 15,
        q{High Orbit Defences}  => 16,
        q{Low Orbit Defences}   => 17,
        q{Additional Vessels}   => 18,
    );

    foreach my $fleet (keys(%{$fleets})) {
        foreach my $type (keys(%{$fleets->{$fleet}->{ships}})) {
            $fleets->{$fleet}->{counts}->{$type}    = scalar(@{$fleets->{$fleet}->{ships}->{$type}});
            $fleets->{$fleet}->{ships}->{$type}     = [ sort { $a->{name} <=> $b->{name} } @{$fleets->{$fleet}->{ships}->{$type}} ];
        }
    }

    write_file(
        File::Spec->catfile($dir, q{index.html}),
        $i_tpl->render(
            style   => $css,
            fleets  => [sort { $order{$a->{name}} <=> $order{$b->{name}} } values(%{$fleets})],
        )
    );
}

sub read_file {
    my $fh = IO::File->new(shift, q{r});
    $fh->binmode(q{:utf8});
    my $data = join(q{}, $fh->getlines);
    $fh->close;
    return $data;
}

sub write_file {
    my ($file, $data) = @_;

    my $parent_dir = dirname($file);
    make_path($parent_dir) unless (-e $parent_dir);

    my $fh = IO::File->new($file, q{w}) || die(sprintf("%s: %s", $file, $!));
    $fh->binmode(q{:utf8});
    $fh->write($data);
    $fh->close;

    printf(STDERR qq{wrote %s\n}, $file);

    return 1;
}

sub filename {
    my ($parent_dir, $ship, $type) = @_;
    return File::Spec->catfile($parent_dir, sprintf(q{%s.%s}, get_slug($ship), $type));
}

sub get_slug {
    my $ship = shift;

    my $slug = lc(sprintf(q{%s/%s}, $ship->{fl}, $ship->{nm}));
    $slug =~ s/ /-/g;
    $slug =~ s/[^a-z0-9\-\.\/]//g;

    return $slug;
}

=pod

=head1 SYNOPSIS

    bfgdata.pl OPTIONS

=head1 OPTIONS

You must specify one or more of --help, --pages, --images, --extract-to.

=over

=item * --help - show help.

=item * --output-dir=DIR - specify output directory (if not, current working directory is used).

=item * --pages - generate ship profile pages.

=item * --images - generate ship images.

=item * --image-SRC=DIR - use the images in C<DIR> instead of extracting them from the Fleets book.

=item * --extract-to=DIR - extract images from the Fleets book into C<DIR> for later use.

=back

=cut
