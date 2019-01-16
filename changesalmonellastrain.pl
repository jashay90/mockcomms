#!/usr/bin/perl
# Julie Shay
# October 20, 2017
# This script will adjust previous mixes by substituting in a different kind of Salmonella
# to replace 58156, and adjusting the proportions of everything according to the genome size
# of the substitution.
use strict;
use warnings;
use LWP::Simple;
use Getopt::Long;

my $genome = "";
my $mixin = "";
my $help = "";
GetOptions('genome=s' => \$genome, 'mixin=s' => \$mixin, 'help' => \$help);

if ($help){
	print "All this script does is take a pre-existing community guideline file with Salmonella enterica as the first listed species,\nand prints out a new community guidelines file where Salmonella enterica is replaced with a path to a new genome of your choice.\nThe path to the first bug will be changed, but it will still be listed as Salmonella enterica.\n\n";
	print "Options\:\n\-genome\t\: ID for the Salmonella genome you want to use\n-mixin\t\: Community guidelines file with Salmonella enterica as the first listed component\n";
	exit;
}

open(FILE, $mixin);
my $line = <FILE>;
print $line;
my @name = ();
my @file = ();
my @propinmixture = ();
my @col = ();
while (<FILE>){
	chomp($_);
	@col = split(/\t/, $_);
	push(@name, $col[0]);
	push(@file, $col[1]);
	push(@propinmixture, $col[2]);
}
close(FILE);

# Assuming that the first line will always be Salmonella/the thing to be substituted.
if ($name[0] ne "Salmonella enterica"){
	print "Something's wrong! This script is expecting Salmonella to be the first species listed.\n";
	die;
}
$file[0] = $genome;

my @gsizexprop = ();
my $sum = 0;
for (my $x = 0; $x <= $#file; $x++){
	$gsizexprop[$x] = &getsize($file[$x]);
	$gsizexprop[$x] = $gsizexprop[$x] * $propinmixture[$x];
	$sum += $gsizexprop[$x];
}

for (my $x = 0; $x <= $#file; $x++){
	print "$name[$x]\t$file[$x]\t$propinmixture[$x]\t";
	$gsizexprop[$x] = $gsizexprop[$x] / $sum;
	print "$gsizexprop[$x]\n";
}

sub getsize {
	my @info;
	$info[0] = `grep -vP "^\>" $_[0] | wc`;
	chomp($info[0]);
	@info = split(/\s+/, $info[0]);
	$info[0] = $info[3] - $info[1];
	return $info[0];
}
