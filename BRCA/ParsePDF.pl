#!usr/bin/perl
die "perl $0 <in.txt>\n" unless (@ARGV ==1);
open F,"$ARGV[0]" or die "$ARGV[0] Error!\n";
my ($sign,$count,$flag,%con);
$sign=0;
$count=0;
$flag=0;
while (my $l=<F>) 
{
	if ($l=~/^1\sBRCA\d\s\d{1,}\:\d{5,}.+/)
	{
		$sign=1;
		$count++;
		chomp($l);
		my @a=split/ /,$l;
		$key=$a[0]."\t".$a[1];
	}
	if ($sign==1)
	{
		if ($l=~/^\s\spathogenic\s.+/ || $l=~/^?Pathogenic\:.+/ || $l=~/^2\sBRCA\d\s\d{1,}\:\d{5,}.+/ || $l=~/^pathogenic\s.+/ || $l=~/^\sThis.+/ || $l=~/^\*.?/)
		{
			$sign=0;
		}
		else
		{
			chomp($l);
			$con{$key}.="#".$l;
		}
	}	
	if ($sign==0)
	{
		if ($l=~/^?Pathogenic\:.+/ || $l=~/^\*.?/ || $l=~/^\/.?/ || $l=~/^\sThis.+/)
		{
			$flag=0;
		}
		if ($l=~/^\d{1,}\sBRCA\d\s\d{1,}\:\d{5,}.+/)
		{
			$flag=1;
			chomp($l);
			my @b=split/ /,$l;
			$key=$b[0]."\t".$b[1];
			$count++;
		}
		if ($flag==1)
		{
			chomp($l);
			$con{$key}.="#".$l;
		}
	}
	if ($l=~/^Amplicon Mean Coverage\:\s(\d{1,})\s?\(Normal.+/)
	{
		$depth=$1;
	}
	if ($l=~/Covered\:\s(\d.+\%)$/)
	{
		$percentage=$1;
	}
}
close F;

$ARGV[0]=~s/\.txt//;
open O,">"."$ARGV[0].out";
foreach my $cle (sort {$a<=>$b} keys %con)
{
	$con{$cle}=~s/^#//;
	$con{$cle}=~s/Likely.Benign/Likely_Benign/;
	$con{$cle}=~s/Likely.Pathogenic/Likely_Pathogenic/;
	my $size=@c=split/[\s#]/,$con{$cle};
	if ($size<=11)
	{
		$con{$cle}=~s/ /\t/g;
		$con{$cle}=~s/#/\t/g;
	}
	if ($size>11&&$size<14)
	{
		$con{$cle}=~s/#/ /g;
		#print $ARGV[0]."\t".$con{$cle}."\n";
		my $p1=join " ",$c[0],$c[1],$c[2],$c[3],$c[4],$c[5];
		my $p2=join " ",$c[-4],$c[-3],$c[-2],$c[-1];
		$con{$cle}=~/$p1\s(c\.\d.+)\s$p2/;
		$Variant=$1;
		$Variant=~s/ //g;
		$con{$cle}=join "\t",$c[0],$c[1],$c[2],$c[3],$c[4],$c[5],$Variant,$c[-4],$c[-3],$c[-2],$c[-1];
		print $ARGV[0]."\t".$con{$cle}."\n";
	}
	if ($size>=14)
	{
		$con{$cle}=~s/#//g;
		#print "Attention!\n";
		#print $ARGV[0]."\t".$con{$cle}."\n";		
		my $p1=join " ",$c[0],$c[1],$c[2],$c[3];
		my $p2=join " ",$c[-4],$c[-3],$c[-2],$c[-1];
		$con{$cle}=~/$p1([ATCG]+)\//;
		$Ref=$1;
		$con{$cle}=~/$p1$Ref\/([ATCG]+)$Ref(c\.\d+\S+)$p2/;
		$Genotype=$Ref."/".$1;
		$Variant=$2;
		$con{$cle}=join "\t",$c[0],$c[1],$c[2],$c[3],$Genotype,$Ref,$Variant,$c[-4],$c[-3],$c[-2],$c[-1];
		print $ARGV[0]."\t".$con{$cle}."\n";
	}


	$con{$cle}=~s/^\d{1,}\t//;
	print O $ARGV[0]."\t".$con{$cle}."\t".$depth."\t".$percentage."\n";
}
close O;
print $ARGV[0]." Done.\n";
