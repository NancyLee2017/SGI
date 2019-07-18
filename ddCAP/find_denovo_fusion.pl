#!/usr/bin/perl -w

die "perl $0 <in.report.filtered.tsv.list> <fusion2check.xls>\n" unless (@ARGV ==2);
open IN, "$ARGV[0]" or die "Error! Cannot open $ARGV[0]\n";
open OT, ">$ARGV[1]" or die "Error! Cannot open $ARGV[1]\n";
print OT "SampleID\tFusionType\tFusionGene\tPosition1\tPosition2\n";

my ($fusion, $candidates)=("","");
while(<IN>){
	chomp;
	my @a=split/\//,$_;
	my $ID=$a[-2];
	
	if(/report.filtered.tsv$/){
		$fusion=(split /=/)[-1];
		$fusion=~s/report.filtered.tsv/fusion_result.tsv/;
		$candidates=(split /=/)[-1];
		$candidates=~s/-M\/(.+?)report.filtered.tsv/-M\/fusions_candidates.txt/; 
#		print "$candidates\n";
	}
	elsif(/fusion_result.tsv/){$fusion=(split /=/)[-1];}
	elsif(/fusions_candidates/){$candidates=(split /=/)[-1];}
	
	
	if ($fusion=~/fusion_result.tsv/){
		(open IN2,"$fusion" ) or (print "$ID has no fusion_result.tsv file!\n");
		while (<IN2>){
			if (/^$/){next;}
			elsif (/^chr/){
				chomp;
				my @b=split/\t/;
				my $pos1=join ":",$b[0],$b[1];
				my $pos2=join ":",$b[4],$b[5];
				my $type=join "-",$b[3],$b[7];
				if ($b[12]=~/Known_Cosmic_Fusion/){print OT "$ID\t$b[12]\t$type\t$pos1\t$pos2\n";}
				elsif($b[12]=~/Denovo_Fusion/){print OT "$ID\t$b[12]\t$type\t$pos1\t$pos2\n";}
			}
		}close IN2;
	}
	
	if ($candidates=~/fusions_candidates/){
		(open IN3,"$candidates" ) or (print "$ID has no fusions_candidates.txt file!\n");
		while(<IN3>){
			if (/^$/){next;}
			elsif(/^chr/){
				my @c=split/\t/;
				my @d=split/\~/,$c[0];
				my $pos1=join ":",$d[0],$c[1];
				my $pos2=join ":",$d[1],$c[2];
			print OT "$ID\tcandidate_fusions\t\t$pos1\t$pos2\n";
			}
		}close IN3;
	}
}close IN;
