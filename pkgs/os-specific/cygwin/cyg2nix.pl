#!/usr/bin/env perl

use strict;
use warnings;

print "{\n";

my $package;
my $version;
my @install;
my @source;

sub end_package() {
    return if !$package;
    print "  \"$package\" = {\n";
    print "    version = \"$version\";\n";
    print "    install = {\n";
    print "      url = \"$install[0]\";\n";
    print "      sha512 = \"$install[1]\";\n";
    print "    };\n";
    if ($#source) {
        print "    source = {\n";
        print "      url = \"$source[0]\";\n";
        print "      sha512 = \"$source[1]\";\n";
        print "    };\n";
    }
    print "  };\n";
}

while (<>) {
    chomp;
    my @x;
    if (/^@ (\S+)/) {
        end_package();
        $package = $1;
        $version = undef;
        @install = undef;
        @source = undef;
    } elsif (/^version: (\S+)/) {
        $version = $1 if !$version;
    } elsif (@x = /^install: (\S+) \S+ (\S+)/) {
        @install = @x if !$#install;
    } elsif (@x = /^source: (\S+) \S+ (\S+)/) {
        @source = @x if !$#source;
    }
}
end_package();

print "}\n";
