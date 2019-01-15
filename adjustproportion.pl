#!/usr/bin/perl
# Julie Shay
# This script will take a set of community guidelines, and change the proportions of each species
# such that your species of interest has a new proportion that you define.

use LWP::Simple;
use Getopt::Long;
use strict;
use warnings;

my $infile = "";
my $tochange = "dummy species";
my $newprop = "0.01";
my $help = 0;
GetOptions('infile=s' => \$infile, 'species=s' => \$tochange, 'newprop=f' => \$newprop, 'help' => \$help);

if ($help){
	print "Options\:\n\-infile\t\: input file with a list of component genomes and their proportions\n\-species\t\: name of species whose proportion you want to change. use quotes or backslashes to deal with the spaces\n\-newprop\t\: new proportion that you are setting the species to\n";
	exit;
}

my @species = ();
my @oldpropinmixture = ();
my @oldpropofreads = ();
my @col = ();
my $thisone = -1;
my $changefactor = 0;	# this is how much everything except the species of intereest changes

my @newpropofreads = ();
my @newpropinmixture = ();	# this will start off being newpropofreads * inferred relative genome size,
			# then it will be divided by the total..
my $header = "";
open(FILE, $infile);
$header = <FILE>;
print $header;
my $total = 0;
while (<FILE>){
	chomp($_);
	@col = split(/\t/, $_);
	push(@species, "$col[0]\t$col[1]");
	push(@oldpropinmixture, $col[2]);
	push(@oldpropofreads, $col[3]);
	if ($col[0] eq $tochange){
		$thisone = $#species;
		$changefactor = (1 - $newprop) / (1 - $col[2]);
	}
}
close(FILE);

if ($thisone == -1){
	print "Error! couldn't find species of interest for proportions change.\n";
} else {
	for ($x = 0; $x <= $#species; $x++){
		if ($x == $thisone){
			$newpropinmixture[$x] = $newprop;
		} else {
			$newpropinmixture[$x] = $oldpropinmixture[$x] * $changefactor;
		}
		$newpropofreads[$x] = $newpropinmixture[$x] * ($oldpropofreads[$x] / $oldpropinmixture[$x]);
		$total += $newpropofreads[$x];
	}
	for ($x = 0; $x <= $#species; $x++){
		$newpropofreads[$x] = $newpropofreads[$x] / $total;
		print "$species[$x]\t$newpropinmixture[$x]\t$newpropofreads[$x]\n";
	}
}
