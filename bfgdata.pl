#!/usr/bin/env perl
# ABSTRACT: Generate static Battlefleet Gothic: Remastered ship profile HTML
# pages using data from The_MonkeyKing's Gothic Fleet Registry. 
use Cwd qw(getcwd abs_path);
use Data::Mirror qw(mirror_str);
use File::Basename qw(dirname basename);
use File::Copy::Recursive qw(rcopy);
use File::Glob qw(:bsd_glob);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use Getopt::Long;
use HTML5::DOM;
use Image::Size;
use JSON::XS;
use Lingua::EN::Titlecase;
use List::Util qw(max);
use Pod::Usage;
use Template::Liquid;
use common::sense;

my ($dir, $help);
pod2usage(1) unless(GetOptions(
    q{output-dir:s} => \$dir,
    help            => \$help,
));

pod2usage(0) if ($help);

my $tc      = Lingua::EN::Titlecase->new;
my $tpl     = Template::Liquid->parse(read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), qw(tpl template.tpl))));
my $i_tpl   = Template::Liquid->parse(read_file(File::Spec->catfile(dirname(abs_path(__FILE__)), qw(tpl index.tpl))));

$dir = abs_path($dir || File::Spec->catdir(dirname(__FILE__), q{_site}));

say STDERR q{mirroring ship data...};
my $html = mirror_str(q{https://bfgtools.kuldare.com/});

say STDERR q{extracting ship data...};
my $doc  = HTML5::DOM->new->parse($html);
my $json = $doc->getElementById(q{bfgdata})->textContent;
my $data = JSON::XS->new->utf8->decode($json);

printf(STDERR qq{files will be written to '%s'\n}, $dir);

munge_data();
generate_pages();
copy_assets();

say STDERR q{done!};

exit;

#
# apply some cleanups to the data from the Gothic Fleet Registry. 
#
sub munge_data {
    add_missing_ships();

    foreach my $ship (values(%{$data->{ships}})) {
        $ship->{_ty} = $ship->{ty};
        $ship->{_ty} =~ s/ /_/g;
        $ship->{fl} = munge_fleet_name($ship->{fl});
    }
}

sub add_missing_ships {

    my $i = max(map { int($_) } keys(%{$data->{ships}}));

    my %map = map { $_->{nm} => 1 } values(%{$data->{ships}});

    $data->{ships}->{++$i} = {
        fl => q{LOW ORBIT DEFENCES},
        nm => q{MISSILE SILO},
        bp => 5,

        ty => q{Ground},
        hp => 1,

        sp => 0,
        tn => 0,
        sh => 0,
        ar => q{6+},

        tl => q{TURRETS},
        tu => 0,

        aw => [ [q{Torpedoes}, q{30 cm}, 6, q{Front}] ],

        pg => 0,
    } unless (exists($map{q{MISSILE SILO}}));

    $data->{ships}->{++$i} = {
        fl => q{LOW ORBIT DEFENCES},
        nm => q{DEFENCE LASER SILO},
        bp => 15,

        ty => q{Ground},
        hp => 1,

        sp => 0,
        tn => 0,
        sh => 0,
        ar => q{6+},

        tl => q{TURRETS},
        tu => 0,

        aw => [ [q{Lance battery}, q{60 cm}, 3, q{Front}] ],

        pg => 0,
    } unless (exists($map{q{DEFENCE LASER SILO}}));

    $data->{ships}->{++$i} = {
        fl => q{HIGH ORBIT DEFENCES},
        nm => q{FIRE SHIP},
        bp => 10,

        ty => q{Escort},
        hp => 1,

        sp => q{15 cm},
        tn => q{45°},
        sh => 1,
        ar => q{5+},

        tl => q{TURRETS},
        tu => 1,

        aw => [],
        sr => q{• The controlling player can detonate a fire ship at any point in its movement phase, inflicting D3 Fire critical hits on every ship within 3D6 cm. As with any escort suffering a critical hit, escorts within the fire ship's blast will be automatically destroyed, as are any Ordnance markers. Remove the detonated fire ship and put a Blast marker in its place.},

        pg => 0,
    } unless (exists($map{q{FIRE SHIP}}));

}

#
# generate a static HTML page for each ship in the registry.
#
sub generate_pages {
    say STDERR q{generating ship pages...};

    foreach my $ship (sort { $a->{pg} <=> $b->{pg} } values(%{$data->{ships}})) {
        generate_image($ship);
        generate_page($ship);
    }

    generate_index();
}

#
# copy assets into the output directory
#
sub copy_assets {
    my $dst = File::Spec->catfile($dir, q{assets});
    rcopy(
        File::Spec->catfile(dirname(abs_path(__FILE__)), q{assets}),
        $dst,
    );
    printf(STDERR qq{wrote assets to %s/\n}, $dst);
}

#
# generate an image for a ship. this is done using the images taken from the
# PDF. Using the page number in the registry data, we glob() the extracted
# images and use magick() to composite a new image, using one image as an alpha
# mask.
#
sub generate_image {
    my $ship = shift;

    my @images = sort(bsd_glob(File::Spec->catfile(dirname(__FILE__), q{src}, sprintf(q{image-%03u-*.png}, $ship->{pg}))));

    if (scalar(@images) < 3) {
        printf(STDERR qq{WARNING: found %u images on p%s for '%s' for %s (%s), need 3\n}, scalar(@images), $ship->{pg}, $tc->title($ship->{nm}), $tc->title($ship->{fl}));
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

#
# generate a static HTML page for a ship.
#
sub generate_page {
    my $ship = shift;

    foreach (qw(fl nm tl)) {
        $ship->{$_} = $tc->title($ship->{$_});
    }

    $ship->{nm} = q{Q-Ship} if (q{Q-SHIP} eq $ship->{nm});

    foreach (qw(sr op)) {
        $ship->{$_} =~ s/•/\n* /g;
        $ship->{$_} =~ s/^\n//g;
        $ship->{$_} = bullets2li($ship->{$_});
    }

    write_file(
        filename($dir, $ship, q{html}),
        $tpl->render(
            ship            => $ship,
            has_image       => (-e filename($dir, $ship, q{png})),
            has_armament    => scalar(@{$ship->{aw}} > 0),
            image           => basename(filename($dir, $ship, q{png})),
            has_sr          => length($ship->{sr}) > 0,
            has_op          => length($ship->{op}) > 0,
        )
    );
}

#
# takes a blob of text, which may contain bulleted lists, and turns it into
# HTML.
#
sub bullets2li {
    my @lines = split(/\n/, shift);

    for (my $i = 0 ; $i < scalar(@lines) ; $i++) {
        my $is_first_line = (0 == $i);
        my $is_last_line = (1+$i == scalar(@lines));

        if ($lines[$i] =~ /^\*/) {
            # line is part of a bulleted list
            $lines[$i] =~ s/^\*\s*//g;

            if ($is_first_line) {
                $lines[$i] = sprintf(q{<ul><li>%s</li>}, $lines[$i]);

            } else {
                $lines[$i] = sprintf(q{<li>%s</li>}, $lines[$i]);

                if ($lines[$i-1] !~ /\/li>$/) {
                    # previous line is not part of a list, start a new one
                    $lines[$i] = sprintf(q{<ul>%s}, $lines[$i]);
                }
            }

            $lines[$i] .= q{</ul>} if ($is_last_line);

        } else {
            # line is not part of a bulleted list

            $lines[$i] = sprintf(q{<p>%s</p>}, $lines[$i]);

            if ($lines[$i-1] =~ /\/li>$/) {
                # previous line is part of a list, close it
                $lines[$i] = sprintf(q{</ul>%s}, $lines[$i]);
            }
        }
    }

    return join("\n", @lines);
}

#
# generate the site index.
#
sub generate_index {
    my $fleets = {};
    foreach my $ship (values(%{$data->{ships}})) {
        if (!exists($fleets->{$ship->{fl}})) {
            $fleets->{$ship->{fl}} = {
                name    => $tc->title($ship->{fl}),
                slug    => get_slug($ship->{fl}),
                ships   => {
                    Defence         => [],
                    Escort          => [],
                    Cruiser         => [],
                    Battleship      => [],
                    Ground          => [],
                    Grand_Cruiser   => [],
                },
            }
        }

        push(@{$fleets->{$ship->{fl}}->{ships}->{$ship->{_ty}}}, {
            name    => $tc->title($ship->{nm}),
            href    => filename(q{.}, $ship, q{html}),
        });
    }

    #
    # this is the order in which the fleets will be listed
    #
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

    foreach my $fleet (sort { $order{$fleets->{$a}->{name}} <=> $order{$fleets->{$b}->{name}} } keys(%{$fleets})) {
        foreach my $type (keys(%{$fleets->{$fleet}->{ships}})) {
            $fleets->{$fleet}->{counts}->{$type}    = scalar(@{$fleets->{$fleet}->{ships}->{$type}});
            $fleets->{$fleet}->{ships}->{$type}     = [ sort { $a->{name} cmp $b->{name} } @{$fleets->{$fleet}->{ships}->{$type}} ];
        }
    }

    write_file(
        File::Spec->catfile($dir, q{index.html}),
        $i_tpl->render(
            fleets  => [sort { $order{$a->{name}} <=> $order{$b->{name}} } values(%{$fleets})],
        )
    );
}

#
# Sanitise the fleet names
#
sub munge_fleet_name {
    my $fleet = shift;
    return q{TAU}      if ($fleet =~ /^tau/i);
    return q{TYRANIDS} if ($fleet =~ /^tyranid/i);
    return q{NECRONS}  if ($fleet =~ /^necron/i);
    return $fleet;
}

#
# read a file into a scalar.
#
sub read_file {
    my $fh = IO::File->new(shift, q{r});
    $fh->binmode(q{:utf8});
    my $data = join(q{}, $fh->getlines);
    $fh->close;
    return $data;
}

#
# write a file from a scalar.
#
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

#
# compute a filename for a ship.
#
sub filename {
    my ($parent_dir, $ship, $type) = @_;

    return File::Spec->catfile($parent_dir, get_slug($ship->{fl}), sprintf(q{%s.%s}, get_slug($ship->{nm}), $type));
}

sub get_slug {
    my $slug = lc(shift);

    $slug =~ s/ /-/g;

    $slug =~ s/[^a-z0-9\-]//g;

    return$ slug;
}

=pod

=head1 SYNOPSIS

    bfgdata.pl OPTIONS

=head1 OPTIONS

=over

=item * --help - show help.

=item * --output-dir=DIR - specify output directory (if not, ./_site is used).

=back

=cut
