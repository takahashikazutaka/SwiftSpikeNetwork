#!/usr/bin/perl
use strict;
use warnings;
my $infile=$ARGV[0];
print "$infile\n";
my $firstAdd='TMP=/tmp
umask 0000
tmp=`mktemp -d $TMP/matlabcachedir.XXXXXXXXXXX`
echo $tmp
export MCR_CACHE_ROOT=$tmp
';
open(IN,$infile);
my @file=<IN>;
close(IN);
open(OUT,">",$infile);
for (@file){
    if (/^exe_name=\$0$/){
      print OUT $firstAdd."\n";
    } 
    print OUT $_;
    if (/^\s+eval /){
        print OUT "rm -rf \$tmp\n";
    }
}    
close(OUT)
