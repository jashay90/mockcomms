#!/usr/bin/perl
# Julie Shay
# February 6, 2017
# This script will randomly choose organisms to include in a mock community, and will output
# a file that lists these organisms and the random proportions that the script assigns to them.
# Organisms and proportions are chosen according to a set of rules in one of the input files.

use LWP::Simple;
use Getopt::Long;
use strict;
use warnings;

my $gdir = `pwd`;
chomp($gdir);
my $file = "$gdir/litsearch.tab";	# file with tab-delimited list of things to potentially include...each line should be a single species
my $infofile = "$gdir/bc/biggercommunityguidelines";	# specifies what the database should consist of
my $filelist = "$gdir/genomelist";	# contains the possible genomes that could go into the in silico data set.
my $filefolder = $gdir;	# folder that contains the genome files specified in $filelist
my $help = 0;

GetOptions('orglist=s' => \$file, 'guide=s' => \$infofile, 'genomelist=s' => \$filelist, 'gfolder=s' => \$filefolder, 'help' => \$help);

if ($help){
	print "Options\:\n\-orglist\t\: file with tab-delimited list of things to potentially include in a mock community. Each line should be a single species\n\-guide\t\: file which specifies how to choose components for the mock community\n\-genomelist\t\: file containing a list of the possible genomes that could go into the in silico data set\n\-gfolder\t\: folder that contains the genome files specified in the genomelist\n";
	exit;
}

my @info;
my @species;
my @props;
my $propreads;
my @singspecies;
my $sum = 0;
my $sumreads = 0;
my $filepath = "";
my @getgsize = ();
my @toprint = ("species\tfile\tproportion in mixture\tproportion of reads");
my @allpropreads = ("filler");
open(INFO, $infofile);
while (<INFO>) {
	# choose species
	$sum = 0;
	@info = split(/\t/, $_);
	@species = &random($file, $info[1], $info[2], $info[3]);
	for (my $x = 0; $x <= $#species; $x++) {
		@singspecies = split(/\t/, $species[$x]);
		$species[$x] = "$singspecies[2] $singspecies[3]";
		# assign proportions
		$props[$x] = rand();
		$sum += $props[$x];
	}
	for (my $x = 0; $x <= $#species; $x++){
		# normalize proportions
		$props[$x] = ($props[$x] / $sum) * $info[0];
		# find file name
		$filepath = `grep \"$species[$x]\" $filelist`;
		if (!($filepath)){
			$filepath = &addfile($species[$x]);
		}
		chomp($filepath);
		$filepath =~ s/.+\t//;
		# get genome size (assumes complete genome)
		$getgsize[0] = `tail -n +2 $filepath | wc`;
		chomp($getgsize[0]);
		@getgsize = split(/\t/, $getgsize[0]);
		$getgsize[2] -= $getgsize[0];
		$propreads = $props[$x] * $getgsize[2];
		$sumreads += $propreads;
		push(@toprint, "$species[$x]\t$filepath\t$props[$x]");
		push(@allpropreads, $propreads);
	}
}
close(INFO);

print "$toprint[0]\n";
#normalize, print proportions
for (my $x = 1; $x <= $#toprint; $x++){
	print $toprint[$x];
	$allpropreads[$x] = $allpropreads[$x] / $sumreads;
	print "\t$allpropreads[$x]\n";
}


# This subroutine will randomly choose items from a list that match your criteria
sub random {
	my $infile = $_[0];
	my $key = $_[1];	# keyword, so all results will have this keyword
	my $col = $_[2];	# column that the keyword must be found in
	my $num = $_[3];	# number of results
	my @options;
	my $remove;

	$options[0] = `awk '\$$col ~ /$key/' $infile`;
	@options = split(/\n/, $options[0]);

	# make sure that there are at least $num possible results
	if ($#options < ($num - 1)) {
		die "not enough lines have $key in column $col";
	} else {
		# randomly reduce @options until it only has $num elements
		while ($#options >= $num) {
			$remove = int(rand(($#options + 1)));
			splice(@options, $remove, 1);
		}
		return @options;
	}
}

sub addfile {
	my $sp = $_[0];
	my $otherout = $sp;
	my $base = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils";
	$sp =~ s/\s/\+/;
	my $url = $base . "/esearch.fcgi?db=nuccore&term=%22$sp%22%5BOrganism%5D+AND+%22complete+genome%22%5Btitl%5D+AND+RefSeq%5Bfilter%5D&retmax=1";
	my $output = get($url);
	if (($output =~ /No items found/) || (!($output =~ /\<Id\>/))){
		die "no RefSeq complete genomes for $sp";
	}
	$output =~ s/\n//g;
	$output =~ s/.+\<Id\>//g;
	$output =~ s/\<\/Id\>.+//g;
	$otherout .= "\t$filefolder/$output.fna\n";
	open(OUTFILEA, ">>$filelist");
	print OUTFILEA "$otherout";
	close(OUTFILEA);
	$url = $base . "/efetch.fcgi?db=nuccore&id=$output&rettype=fasta&retmode=text";
	open(OUTFILEB, ">$filefolder/$output.fna");
	my $data = get($url);
	if (!($data)){
		die "problem downloading $output genome";
	}
	print OUTFILEB "$data";
	close OUTFILEB;
	return $otherout;
}
