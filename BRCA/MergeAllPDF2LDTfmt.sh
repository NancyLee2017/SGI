PDFPath="/home/hongyanli/sh.test/pdf"

WorkPath="/home/hongyanli/sh.test"


cd $WorkPath

if [ -d BRCA_res ];then
	rm -rf BRCA_res
fi
mkdir BRCA_res
cd BRCA_res
pdf_names=`ls -1 $PDFPath| cut -d "_" -f 2`
for name in $pdf_names;
do 
	/home/zhouwang/Scripts/xpdfbin/bin64/pdftotext -raw $PDFPath/*_${name}_*.pdf ${name}.txt;
	sed -i -e '/^$/d' ${name}.txt;
	perl /home/hongyanli/script/BRCA/ParsePDF.pl ${name}.txt;
done;
cd $WorkPath
cat BRCA_res/*.out | sed '1i Sample_ID\tGene\tLocus\tExon\tGenotype\tRef\tVariant\tAAChange\tType\tConsequence\tClinical_Significance\tAverage_CoverDepth\tMutation_Cover%' > variant.xls
