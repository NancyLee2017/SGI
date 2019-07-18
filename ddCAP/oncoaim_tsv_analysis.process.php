<?php
	// Config file (includes development versus production variables and automatically determines environment based on OS (Windows (local) vs Linux (server)))
	include(__DIR__ . '/config.inc');
	
	// Fix/update MySQL functions for PHP 7.x
	include(__DIR__ . '/fix_mysql.inc');
	
	// Default variables - for now, developing the Chinese language templates only
	// MDQ Server 3 command line test example: php oncoaim_tsv_analysis.php /var/www/html/php/john/dev/final_oncoaim_test/uploads/SGI-CL170308001-D01-L01-M_S9.report.extra.tsv sgi /var/www/html/php/john/dev/final_oncoaim_test/temp_pdf/test.pdf /var/www/html/php/john/dev/final_oncoaim_test/uploads/SGI-CL170308001-D01-L01-M_S9.sqm.json new_oncoaim_runon_fancy_condensed_CN /var/www/html/php/john/dev/final_oncoaim_test/uploads/SGI-CL170308001-D01-L01-M_S9.processed.tsv
	$language = 'cn';
	$qc_fail = 'no';
	
	// Functions and static arrays
	include(__DIR__ . '/functions.inc');
	
	// Set variables based on command line parameters, if running on production server
	if ($environment == 'prod') {
		// Production - run from command line
		$tsv_filepath = $argv[1];
		$client_id = $argv[2];
		$output_filepath_and_name = $argv[3];
		$json_filepath = $argv[4];
		$template_name = $argv[5];
		$output_tsv_clin_sig_filepath_and_name = $argv[6]; // Generates a processed .tsv file with additional data columns added
		$fusion_filepath = $argv[7];
		$cnv_filepath = $argv[8];
                $patient_basic_info = $argv[9]; //include patient basic information

		// Required parameters
		if ($tsv_filepath == '' || $client_id == '' || $output_filepath_and_name == '' || $json_filepath == '' || $template_name == '') die('All of the required parameters are not provided.');
	} else {
		// Development - run from local browser to allow .tsv file upload and to allow choosing template_name
		?>

		<a href='tsv_upload.php'>[New File]</a><br><br>

		<?php
		// Upload .tsv file as temporary file to disk
		if ($fileToUpload) {
			$target_file = $uploads_folder . basename($_FILES["fileToUpload"]["name"]);
			
			 if (move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file)) {
				if ($environment == 'dev') echo "The file has been uploaded as: " . $target_file . ".<br><br>";
				$tsv_filepath = $target_file;
			 } else {
				die("Error uploading the file.");
			 }
		}
	}
	
	// JSON filename is based on the sample name
	$base_filename = get_to_first_char(basename($tsv_filepath), ".");
	
	// Template main variant filtering - this is the style of the report: based on allele frequency or based on clinical significance
	// The script logic and variant filtering for specific sections of the report will be different based on the style of the report
	switch ($template_name) {
		case "new_oncoaim_runon_fancy_condensed_CN":
			// Related files: .sqm.json
			// JSON metrics file
			if ($environment == 'dev') {
				if (file_exists('./report_files/' . $base_filename . '.sqm.json')) {
					$json_filepath = './report_files/' . $base_filename . '.sqm.json';
				} else {
					// Sample JSON
					$json_filepath = './uploads/SGI-CL170308001-D01-L01-M_S9.sqm.json';
				}
			}
			
			$report_filter = 'frequency';
			break;
		case "plasaim_lung_CN":
                case "akm_plasaim_lung_CN":
		case "oncoaim_lung_CN":
			// Related files (except for titanseq_CN): .sqm.json, .cnv.tsv, .coverage.tsv, .fusion_result.tsv
			// JSON metrics file
			if ($environment == 'dev') {
				if (file_exists('./report_files/' . $base_filename . '.sqm.json')) {
					$json_filepath = './report_files/' . $base_filename . '.sqm.json';
				} else {
					// Sample JSON
					$json_filepath = './uploads/SGI-CL170308001-D01-L01-M_S9.sqm.json';
				}
			}
			
			// Fusions file
			if ($environment == 'dev') {
				if (file_exists('./report_files/' . $base_filename . '.fusion_result.tsv')) {
					$fusion_filepath = './report_files/' . $base_filename . '.fusion_result.tsv';
					echo "<u>FUSION FILE (" . $fusion_filepath . ") WITH type = 'Known_Cosmic_Fusion'</u>: <br>";
				}
			}
			
			if (file_exists($fusion_filepath)) {
				//** Process the fusion file line by line
				$file = fopen($fusion_filepath, "r");
				if (!$file) die('File does not exist or cannot open fusion file.');
				$line_number = 0;
			
				while(!feof($file)) {
					$line = fgets($file);
					$row_data = array();
					
					// Each line has different data
					//donor_chr	donor_end	donor_strand	donor_gene	acceptor_chr	acceptor_start	acceptor_strand	acceptor_gene	fusion_coverage	total_coverage	fusion_fraction	CP100K	type
					switch ($line_number) {
						case "0":
							// Number of input reads
							$fusion_number_of_input_reads = get_string_after_char($line, ":");
							
							break;
						case "1":
							// Average input read length
							$fusion_average_input_read_length = get_string_after_char($line, ":");
						
							break;
						case "2":
							// Mapping rate
							$fusion_mapping_rate = get_string_after_char($line, ":");
						
							break;
						case "3":
							// Number of reads mapped to ALK, RET, ROS1 with soft clip longer than 5: 398941
							$fusion_number_of_reads_mapped = get_string_after_char($line, ":");
							
							break;
						case "4":
							//** Separate each line in the file by tab-delimiter to get column value
							$row_data = explode("\t", $line);
						
							//** The first row is the header titles to assign as variables
							for ($a = 0; $a < sizeof($row_data); $a++) {
								//** Clean up array header names by replacing possibly problematic characters (eg. replace spaces and fix Gene(exons) column)
								$header_variable = strtolower(str_replace(" ", "_", $row_data[$a]));
								
								//** The data arrays from the .tsv file is prepended with 'list_' to represent the original data
								$all_fusion_headers[] = 'list_fusion_' . trim($header_variable);
							}
						
							break;
						default:
							//** Separate each line in the file by tab-delimiter to get column value
							$row_data = explode("\t", $line);
						
							//** Assign the remaining rows of the .tsv file as data values
							for ($x = 0; $x < sizeof($row_data); $x++) {
								if ($row_data[$x] != '') {
									//** Dynamically assign values to individual arrays based upon the header names; add trim function to clean up whitespaces, if any
									${$all_fusion_headers[$x]}[] = trim($row_data[$x]);
								} else {
									${$all_fusion_headers[$x]}[] = '';
								}
							}
							break;
					} 
					
					//** Increment line number
					$line_number++;
				}
				
				//** Close the .tsv file, as we have loaded it all into arrays
				fclose($file);
			
				// Get gene fusions in file that have type = Known_Cosmic_Fusion
				for ($c = 0; $c < sizeof($list_fusion_type); $c++) {
					if (strtolower(trim($list_fusion_type[$c])) == 'known_cosmic_fusion') {
						$filtered_list_fusion_donor_chr[] = $list_fusion_donor_chr[$c];
						$filtered_list_fusion_donor_end[] = $list_fusion_donor_end[$c];
						$filtered_list_fusion_donor_strand[] = $list_fusion_donor_strand[$c];
						$filtered_list_fusion_donor_gene[] = $list_fusion_donor_gene[$c];
						$filtered_list_fusion_acceptor_chr[] = $list_fusion_acceptor_chr[$c];
						$filtered_list_fusion_acceptor_start[] = $list_fusion_acceptor_start[$c];
						$filtered_list_fusion_acceptor_strand[] = $list_fusion_acceptor_strand[$c];
						$filtered_list_fusion_acceptor_gene[] = $list_fusion_acceptor_gene[$c];
						$filtered_list_fusion_coverage[] = $list_fusion_coverage[$c];
						$filtered_list_fusion_cp100k[] = $list_fusion_cp100k[$c];
						$filtered_list_fusion_type[] = $list_fusion_type[$c];
						$filtered_list_fusion_fraction[] = $list_fusion_fusion_fraction[$c];
						
						if ($environment == 'dev') {
							if ($list_fusion_type[$c] == 'Known_Cosmic_Fusion') {
								$found_fusion = TRUE;
								echo "<b>" . $list_fusion_acceptor_gene[$c] . "-" . $list_fusion_donor_gene[$c] . ": " . $list_fusion_fusion_fraction[$c] . "</b><br>";
							}
						}
					}
				}
				
				if ($environment == 'dev' && $found_fusion == FALSE) {
					echo "No reportable fusions identified.<br>";
				}
				
				// Sort arrays for report display
				if (isset($filtered_list_fusion_donor_gene, $filtered_list_fusion_acceptor_gene)) {
					array_multisort(
						$filtered_list_fusion_fraction, SORT_DESC,
						$filtered_list_fusion_donor_gene,
						$filtered_list_fusion_acceptor_gene);
				}
			}
			
			// CNV file
			if ($environment == 'dev') {
				if (file_exists('./report_files/' . $base_filename . '.cnv.tsv')) {
					$cnv_filepath = './report_files/' . $base_filename . '.cnv.tsv';
					
					echo "<br>";
					echo "<u>CNV FILE ($cnv_filepath)</u>:<br>";
					echo "<table>";
					echo "<tr>";
						echo "<td><b><u>Gene</u></b></td>";
						echo "<td><b><u>CNV (Rounded)</u></b></td>";
					echo "</tr>";
				}
			}
			
			if (file_exists($cnv_filepath)) {
				$file = fopen($cnv_filepath, "r");
				if (!$file) die('File does not exist or cannot open cnv file.');
				while(!feof($file)) {
					$line = fgets($file);
					$row_data = array();
					 
					//** Separate each line in the file by tab-delimiter to get column value
					$row_data = explode("\t", $line);
					
					//** Headers (not in file) of .tsv file: chr1	115247085	115259515	1.88643248967	-1.0863175839	NRAS = Chr | Start | End | CNV | Metric | Gene 
					//** Assign the rows of the .tsv file as data values
					if ($row_data[0] != '') {
						$cnv_chr[] = trim($row_data[0]);
						$cnv_start[] = trim($row_data[1]);
						$cnv_end[] = trim($row_data[2]);
						$cnv_cnv[] = trim($row_data[3]);
						$cnv_metric[] = trim($row_data[4]);
						$cnv_gene[] = trim($row_data[5]);
					}
				}
				
				//** Close the cnv file, as we have loaded it all into arrays
				fclose($file);
				
				// Display CNVs in file that have $call == pass
				for ($c = 0; $c < sizeof($cnv_gene); $c++) {
					if ($cnv_cnv[$c] >= 4) { // CNV is set to be "positive" at >= 4
						$bold_cnv = 'style=font-weight:bold';
						// Add to positive CNV arrays for display
						
						$positive_cnv_gene[] = $cnv_gene[$c];
						$positive_cnv_status[] = '扩增';
						$positive_cnv_cnv[] = $cnv_cnv[$c];
					} else {
						$bold_cnv = '';
					}
					
					if ($environment == 'dev') {
						echo "<tr>";
							echo "<td>" . $cnv_gene[$c] . "</td>";
							echo "<td $bold_cnv>" . $cnv_cnv[$c] . " (" . round($cnv_cnv[$c], 0) . ")</td>";
						echo "</tr>";
					}
				}
				
				if ($environment == 'dev') {
					echo "</table><br>";
				}
			}
			
			$report_filter = 'clin_sig';
			break;
		case "titanseq_CN": // TODO
		case "chope_v1_CN":
		case "chope_v2_CN":
			// Related files (except for titanseq_CN): .sqm.json, .cnv.tsv, .coverage.tsv, .fusion_result.tsv
			if ($environment == 'dev') {
				if (file_exists('./report_files/' . $base_filename . '.sqm.json')) {
					$json_filepath = './report_files/' . $base_filename . '.sqm.json';
				} else {
					// Sample JSON
					$json_filepath = './uploads/SGI-CL170308001-D01-L01-M_S9.sqm.json';
				}
			}
			
			$report_filter = 'clin_sig';
			break;
		default:
			$report_filter = 'frequency';
	}
	
	// Connect to database and set character set to UTF-8
	$link = mysql_connect($db_server, $db_username, $db_password);
	if (!$link) { die('Could not connect:' . mysql_error()); }
	mysql_set_charset('UTF8');
	$db_selected = mysql_select_db($db_name, $link);
	if (!$db_selected) { die ('Cannot use : ' . mysql_error()); }
	
	// Process the tsv file line by line
	$file = fopen($tsv_filepath, "r");
	if (!$file) die("File $tsv_filepath does not exist or cannot open file.");
	$line_number = 0;
	while(!feof($file)) {
		$line = fgets($file);
		$row_data = array();
		 
		// Break each line by tab-delimiter
		$row_data = explode("\t", $line);
		
		// Get headers and dynamically assign into array (will work with any number of header names (need to process certain reserved characters, eg. '+')) 
		if ($line_number == 0) {
			// First row contains the header titles which are used as the variable names for the storage arrays
			for ($a = 0; $a < sizeof($row_data); $a++) {
				// Clean up array variable name (replace spaces and special characters (ex. Ref+/Ref-/Var+/Var- columns, if any)
				$header_variable = str_replace($header_str_old, $header_str_new, $row_data[$a]);
				
				// The original data arrays from the original .tsv file are prepended with 'orig_'
				$all_headers[] = 'orig_' . strtolower(trim($header_variable));
			}
		} else {
			// Remaining rows of the tsv file are data values/arrays that are assigned to the appropriate header variables derived from above
			for ($x = 0; $x < sizeof($row_data); $x++) {
				// Assign values to individual arrays
				${$all_headers[$x]}[] = trim($row_data[$x]);
			}
		}
		
		$line_number++;
	}
	
	// Close the TSV file
	fclose($file);
	
	// Determine if normal .tsv file (has 48 columns) or not (eg. OncoAim .tsv file with the three added columns: Variant_Type, Locus_Name, PgkbGenotype)
	// If it is normal, then do not process PGKB genes???
	if (count($all_headers) == 48) $normal_tsv_file = TRUE;
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	
	if ($normal_tsv_file != TRUE) { // OncoAim template using interface layer
		// Handle multi-allelic PGKB variants by establishing the finalized genotype for display and database matching
		// Get data arrays of all PGKB variants that are in the multi-allelic ($haplotype_dbsnps) array
		for ($x = 0; $x < sizeof($orig_symbol); $x++) {
			if ($orig_variant_type[$x] == 'PGKB_SNPs' && in_array($orig_locus_name[$x], $haplotype_dbsnps)) {
				$haplotype_pgkb_keys[] = $x;
				$multi_pgkb_symbols[] = $orig_symbol[$x];
				$multi_pgkb_chromosomes[] = $orig_chromosome[$x];
				$multi_pgkb_positions[] = $orig_position[$x];
				$multi_pgkb_references[] = $orig_reference[$x];
				$multi_pgkb_alternates[] = $orig_alternate[$x];
				$multi_pgkb_locus_names[] = $orig_locus_name[$x];
				$multi_pgkb_genotypes[] = $orig_genotype[$x];
				$multi_pgkb_pgkbgenotypes[] = $orig_pgkbgenotype[$x];
			}
		}
		
		// Loop through the multi-allelic PGKB variants to determine the final PGKB phenotype
		for ($x = 0; $x < sizeof($haplotype_dbsnps); $x++) {
			$curr_haplotype_dbsnps = array_keys($multi_pgkb_locus_names, $haplotype_dbsnps[$x], true);
			
			unset($curr_pgkb_category, $curr_pgkb_dbsnp, $curr_pgkb_alt);
			for ($y = 0; $y < sizeof($curr_haplotype_dbsnps); $y++) {
				//echo $multi_pgkb_symbols[$curr_haplotype_dbsnps[$y]] . " " . $multi_pgkb_locus_names[$curr_haplotype_dbsnps[$y]] . " " . $multi_pgkb_pgkbgenotypes[$curr_haplotype_dbsnps[$y]] . " " . $multi_pgkb_genotypes[$curr_haplotype_dbsnps[$y]] . ": ";
				
				$curr_pgkb_alt .= $multi_pgkb_alternates[$curr_haplotype_dbsnps[$y]] . "|";
				
				// Build a string based on the PGKB phenotype
				switch ($multi_pgkb_pgkbgenotypes[$curr_haplotype_dbsnps[$y]]) {
					case "A/A":
						$curr_pgkb_category .= '1';
					
						break;
					case "A/B":
						$curr_pgkb_category .= '2';
						
						break;
					case "B/B":
						$curr_pgkb_category .= '3';
						
						break;
				}
				
				//echo $curr_pgkb_category . "<br>";
				
				$curr_pgkb_symbol = $multi_pgkb_symbols[$curr_haplotype_dbsnps[$y]];
				$curr_pgkb_dbsnp = $multi_pgkb_locus_names[$curr_haplotype_dbsnps[$y]];
				$curr_pgkb_ref = $multi_pgkb_references[$curr_haplotype_dbsnps[$y]];
			}
				
			$final_pgkb = getFinalPGKB($curr_pgkb_category, $curr_pgkb_dbsnp, $curr_pgkb_ref);
			//echo "<b>" . $final_pgkb . "</b><br><br>";
			
			// Create final pgkb arrays
			$final_multi_pgkb_symbols[] = $curr_pgkb_symbol;
			$final_multi_pgkb_locus_names[] = $curr_pgkb_dbsnp;
			$final_multi_pgkb_genotypes[] = $final_pgkb;
			if ($curr_pgkb_dbsnp == 'rs8175347') {
				$final_multi_pgkb_references[] = "(TA)6";
				$final_multi_pgkb_alternates[] = "(TA)5<br>(TA)7<br>(TA)8";
			} else {
				$final_multi_pgkb_references[] = $curr_pgkb_ref;
				$final_multi_pgkb_alternates[] = rtrim($curr_pgkb_alt, "| ");
			}
		}
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Set header string, adjust to actual header output for pdf generation script
	$processed_tsv = "Gene\tVariant_type\tChromosome\tPosition\tReference\tAlternate\tType\tGenotype\tExisting_variation\tPGKBgenotype\tLocus_name\tConsequence\tMinorallelefraction\tHgvsc\tHgvsp\tHgvsp_abbr\tLocation\tExon\tIntron\tSection\tGene intro\tCOSMIC prediction\tOncoAim hotspot\tFDA\tCFDA\tCivic variant\tCivic evidence\tCKB variant\tCKB evidence\tClinvarCoord\tClinvar\tClinTrials1\tClinTrials2\tPGKBAnnotation\tNCCN\tCOSMIC_ID\n";
	$indication = ''; // Tailor to specific report template/assay
	
	if ($environment == 'dev') {
		echo "<u>VARIANTS WITH FILTER = 'PASS' AND NOT PGKB IN .TSV FILE</u>:<br>";
		echo "<table border=1 cellspacing=0 cellpadding=2><tr><td><b>Section</b></td><td><b>Gene</b></td><td><b>HGVSc</b></td><td><b>HGVSp</b></td><td><b>Consequence</b></td><td><b>Location</b></td><td><b>MAF</b></td></tr>";
	}
	
	// Loop through each row based on the 'variant_type' and perform all of the variant lookups and modifications to create a processed .tsv file
	for ($x = 0; $x < sizeof($orig_symbol); $x++) {
		// The following block performs functions to append to $processed_tsv 
		// $mod_ = modify original data (eg. string processing)
		// $add_ = additional data obtained from database
		// serialize() converts array into a string to store
		// unserialize(), then var_export() will regenerate the original array for php handling;
		
		// The variant must have Filter = 'PASS' to be included in variant processing/formatting
		if (trim($orig_filter[$x]) == 'PASS') {
			$mod_minorallelefraction = mod_minorallelefraction($orig_minorallelefraction[$x]);
			$mod_chromosome = str_replace('chr', '', $orig_chromosome[$x]);
			$mod_hgvsc = mod_hgvsc($orig_hgvsc[$x], $orig_symbol[$x], $orig_position[$x], $orig_reference[$x], $orig_alternate[$x]);
			$mod_hgvsp = mod_hgvsp($orig_hgvsp[$x], $orig_hgvsc[$x]);
			$add_hgvsp_abbr = convertAA(str_replace('p.', '', $mod_hgvsp));
			$mod_location = mod_location($orig_location[$x]);
			$mod_consequence = mod_consequence($orig_consequence[$x]);
			$mod_exon = mod_exon($orig_exon[$x]);
			$mod_intron = mod_intron($orig_intron[$x]);
			$add_gene_intro = add_gene_intro($orig_symbol[$x]);
			$add_cosmic_prediction = add_cosmic_prediction($orig_symbol[$x], $mod_hgvsc, $orig_variant_type[$x]);
			$add_oncoaim_hotspot_mutation = getOncoaimHotspot($orig_symbol[$x], $mod_hgvsp, $orig_locus_name[$x]);
			$add_fda_drugs = serialize(getFDAdrugs($orig_symbol[$x], $mod_hgvsc, $mod_hgvsp));
			$add_cfda_drugs = serialize(getCFDAdrugs($orig_symbol[$x]));
			$add_civic_variant_summary = getCivicVariantSummary($orig_symbol[$x], $mod_hgvsc, $mod_hgvsp, $mod_chromosome, $orig_position[$x], $orig_reference[$x], $orig_alternate[$x], $orig_locus_name[$x]);
			$add_civic_clinical_evidence_summary = serialize(getCivicClinicalEvidenceSummary($orig_symbol[$x], $mod_hgvsc, $mod_hgvsp, $mod_chromosome, $orig_position[$x], $orig_reference[$x], $orig_alternate[$x]));
			$add_ckb_gene_variant = getCKBVariant($orig_variant_type[$x], $orig_symbol[$x], $mod_hgvsc, $mod_hgvsp, $mod_exon, $orig_consequence[$x]);
			$add_ckb_gene_variant_therapy = serialize(getCKBVariantTherapy($orig_variant_type[$x], $orig_symbol[$x], $mod_hgvsc, $mod_hgvsp));
			$add_clinvar_coord_clinical_significance = getClinvarCoordClinicalSignificance($mod_chromosome, $orig_position[$x], $orig_reference[$x], $orig_alternate[$x], $orig_variant_type[$x]);
			$add_clinvar_clinical_significance = getClinvarClinicalSignificance($orig_symbol[$x], $mod_hgvsc, $mod_hgvsp, $orig_variant_type[$x]);
			$add_clin_trials_1 = serialize(getClinicalTrials_1($orig_symbol[$x]));
			$add_clin_trials_2 = serialize(getClinicalTrials_2($orig_symbol[$x], $mod_hgvsp, $mod_exon, $orig_consequence[$x], $orig_variant_type[$x]));
			$add_pgkb_annotation = serialize(getPGKBAnnotation($orig_variant_type[$x], $orig_symbol[$x], $orig_locus_name[$x], $orig_genotype[$x]));
			$add_nccn = getNCCN($orig_symbol[$x], $indication);
			$add_cosmic_id = getCOSMICID($orig_symbol[$x], $mod_hgvsp, $template_name, $mod_hgvsc );
			
			// Check to see if there is a clinical annotation
                        $clinvar_clin_sig_exists = preg_match("/(4|5|drug)/i", $add_clinvar_clinical_significance);
                        $clinvar_coord_clin_sig_exists = preg_match("/(4|5|drug)/i", $add_clinvar_coord_clinical_significance);
			if ($add_civic_variant_summary == '' && $add_ckb_gene_variant == '' && $clinvar_clin_sig_exists == ''  && $clinvar_coord_clin_sig_exists == '' ) { // add in clinvar_coord ^^^^
				// No clinically relevant data is found (VUS), so $found_clinical_annotation is FALSE for further analysis
				$found_clinical_annotation = FALSE;
				
				// Add to vus_clinical_reports database - only for plasaim_lung_CN or chope_v1_CN and manually generated reports for now
				if ($environment == 'dev' && ($template_name == 'plasaim_lung_CN' || $template_name == 'chope_v1_CN' || $template_name == 'akm_plasaim_lung_CN')) {
					// Avoid exact duplicates (eg. from regenerating reports using same date)
					$sql_vus_delete = "DELETE FROM vus_clinical_reports 
										 WHERE sample_name = '" . get_to_first_char(basename($tsv_filepath), '.') . "' 
										 AND report_template = '" . $template_name . "' 
										 AND report_date = '" . $date . "'
										 AND vus_gene = '" . $orig_symbol[$x] . "'
										 AND vus_hgvsc = '" . $mod_hgvsc . "'";
					//echo "<br>" . $sql_vus_delete . "<br><br>";
					mysql_query($sql_vus_delete, $link);
					
					// Insert VUS
					$sql_vus_insert = "INSERT INTO vus_clinical_reports VALUES (
						default, 
						'" . get_to_first_char(basename($tsv_filepath), '.') . "', 
						'" . $template_name . "',
						'" . $date . "',
						'" . $orig_symbol[$x] . "',
						'" . $mod_hgvsc . "',
						'" . get_string_after_char($orig_hgvsp[$x], ':') . "',
						'" . $orig_location[$x] . "',
						'" . $orig_position[$x] . "',
						'" . $orig_type[$x] . "',
						'" . $orig_consequence[$x] . "',
						'" . number_format((float)$orig_minorallelefraction[$x], 4, '.', '') . "', 
						'" . $orig_refseq[$x] . "',
						'" . $orig_reference[$x] . "',
						'" . $orig_alternate[$x] . "')";
					//echo "<br>" . $sql_vus_insert . "<br><br>";
					mysql_query($sql_vus_insert, $link);
				}
			} else {
				$found_clinical_annotation = TRUE;
			}
			
			$add_section = add_section($orig_variant_type[$x], $orig_minorallelefraction[$x], $orig_symbol[$x], $mod_hgvsp, $mod_hgvsc, $orig_locus_name[$x], $report_filter, $found_clinical_annotation, $template_name);
			
			if ($environment == 'dev') {
				if ($add_section != 'PGKB') {
					echo "<tr><td>" . $add_section . "</td><td>" . $orig_symbol[$x] . "</td><td>" . $mod_hgvsc . "</td><td>" . $mod_hgvsp . "</td><td>" . $orig_consequence[$x] . "</td><td>" . $mod_chromosome . ":" . $orig_position[$x] . "</td><td>" . $orig_minorallelefraction[$x] . "</td></tr>";
				}
			}
			
			// Append to $processed_tsv row
			$processed_tsv .= "$orig_symbol[$x]\t$orig_variant_type[$x]\t$mod_chromosome\t$orig_position[$x]\t$orig_reference[$x]\t$orig_alternate[$x]\t$orig_type[$x]\t$orig_genotype[$x]\t$orig_existing_variation[$x]\t$orig_pgkbgenotype[$x]\t$orig_locus_name[$x]\t$mod_consequence\t$mod_minorallelefraction\t$mod_hgvsc\t$mod_hgvsp\t$add_hgvsp_abbr\t$mod_location\t$mod_exon\t$mod_intron\t$add_section\t$add_gene_intro\t$add_cosmic_prediction\t$add_oncoaim_hotspot_mutation\t$add_fda_drugs\t$add_cfda_drugs\t$add_civic_variant_summary\t$add_civic_clinical_evidence_summary\t$add_ckb_gene_variant\t$add_ckb_gene_variant_therapy\t$add_clinvar_coord_clinical_significance\t$add_clinvar_clinical_significance\t$add_clin_trials_1\t$add_clin_trials_2\t$add_pgkb_annotation\t$add_nccn\t$add_cosmic_id\n";
		}
	}
	
	if ($environment == 'dev') {
		echo "</table><br>";
	}
	
	if ($normal_tsv_file != TRUE) { // OncoAim template using interface layer
		// Remove multi-allelic PGKB rows, so that modified ones can be added
		$rows = explode("\n", $processed_tsv);
		$unwanted = "rs8175347|rs1045642|rs2032582|rs4986908|rs4244285|rs3760091";
		$cleanArray = preg_grep("/$unwanted/i", $rows, PREG_GREP_INVERT);
		$processed_tsv = implode("\n", $cleanArray);
		
		// Add one row for multi-allelic PGKB variants (that were previously represented in multiple rows)
		for ($x = 0; $x < sizeof($final_multi_pgkb_symbols); $x++) {
			// These PGKB variants are part of a set and only generate one row per set
			$first_part_genotype = get_to_first_char($final_multi_pgkb_genotypes[$x], '/');
			$second_part_genotype = get_string_after_char($final_multi_pgkb_genotypes[$x], '/');
			
			if ($first_part_genotype == $final_multi_pgkb_references[$x] && $second_part_genotype == $final_multi_pgkb_references[$x]) {
				// Wild-type designation as A/A
				$final_pgkbgenotype = 'A/A';
			} else if ($first_part_genotype == $final_multi_pgkb_references[$x] && $second_part_genotype != $final_multi_pgkb_references[$x]) {
				$final_pgkbgenotype = 'A/B';
			} else {
				$final_pgkbgenotype = 'B/B';
			}
			
			$add_pgkb_annotation = serialize(getPGKBAnnotation('PGKB_SNPs', $final_multi_pgkb_symbols[$x], $final_multi_pgkb_locus_names[$x], $final_multi_pgkb_genotypes[$x]));
			$processed_tsv .= "$final_multi_pgkb_symbols[$x]\tPGKB_SNPs\t\t\t$final_multi_pgkb_references[$x]\t$final_multi_pgkb_alternates[$x]\t\t$final_multi_pgkb_genotypes[$x]\t$final_multi_pgkb_locus_names[$x]\t$final_pgkbgenotype\t$final_multi_pgkb_locus_names[$x]\t\t\t\t\t\t\t\t\tPGKB\t\t\t\t\t\t\t\t\t\t\t\t\t\t$add_pgkb_annotation\t\t\n";
		}
	}
	
	// Output processed .tsv file
	$report_filename = str_replace('.tsv', '', split_string(basename($tsv_filepath), '-', '4'));
	$report_filename = str_replace('report.', '', $report_filename);
	$report_filename = rtrim($report_filename, '.filtered');
	$report_filename = rtrim(str_replace('.extra', '', $report_filename), '.');
	
	if ($environment == 'dev') {
		// Output to current directory
		$processed_tsv_filename = "test-" . $report_filename . ".tsv";
		file_put_contents($processed_tsv_filename, rtrim($processed_tsv) . "\t\t"); // rtrim removes last \n character
	} else {
		// Production
		if ($output_tsv_clin_sig_filepath_and_name) {
			// Write to tsv filename as specified in the parameter $output_tsv_clin_sig_filepath_and_name
#			file_put_contents($output_tsv_clin_sig_filepath_and_name, rtrim($processed_tsv)); // rtrim removes last \n character
			$processed_tsv_filename = $output_tsv_clin_sig_filepath_and_name;
		}
	}
	
	// *** OUTPUT PDF ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// All data arrays and variables are set for final report formatting and display
	include("generate_pdf_runon.inc");
?>
