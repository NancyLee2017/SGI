PDFPath="/home/hongyanli/sh.test/pdf"

WorkPath="/home/hongyanli/sh.test"

cd $WorkPath

if [ -d BRCA_res ];then
	rm -rf BRCA_res
fi
mkdir BRCA_res
cd BRCA_res

#获得libID
pdf_names=`ls -1 $PDFPath| cut -d "_" -f 2`
for name in $pdf_names;
do 
	/home/zhouwang/Scripts/xpdfbin/bin64/pdftotext -raw $PDFPath/*_${name}_*.pdf ${name}.txt;
	sed -i -e '/^$/d' ${name}.txt;
	perl /home/hongyanli/script/BRCA/ParsePDF.pl ${name}.txt;
done;

cd $WorkPath
cd BRCA_res
ls -1 *.out >out_file.list
perl /home/hongyanli/script/BRCA/DoMatrixBRCAimV1.pl out_file.list ../BRCAimV1.matrix.xls

