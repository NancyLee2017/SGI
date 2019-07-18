<?php
	// *** SCRIPT INFORMATION ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Author: 	John C. Nguyen MD
	// Date: 	April 2017
	// Function: 	This script takes in a tab-delimited TSV file, analyzes the variants, and sets the 
	//	variables for display in a template. The script will do the following in this order:
	//	1. Upload the tsv file
	//	2. Reads the tsv file line by line and creates variables based on the column header names
	//	3. Looks up each variant in the different databases
	//	4. Creates final variables and arrays for the template to use
	//	5. Generates a pdf file
	// Associated files:	generate_pdf.php, functions.inc, config.inc, template folder(s), mpdf library, bootstrap files
	// Testing on MDQ Server 3: php brcaim_tsv_analysis.php /var/www/html/php/john/dev/new_brcaim_v3/uploads/SGI-CL170515004-D01-L01-P.report.tsv sgi /var/www/html/php/john/dev/new_brcaim_v3/temp_pdf/SGI-CL170515004-D01-L01-P.report.pdf /var/www/html/php/john/dev/new_brcaim_v3/uploads/exampleSQM.json seqstore_blood_cn /var/www/html/php/john/dev/new_brcaim_v3/temp_pdf/SGI-CL170515004-D01-L01-P.report.filtered_testname_clin_sig.tsv
	// *** END SCRIPT INFORMATION ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// *** SCRIPT CONFIGURATION /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Config file (includes development versus production variables)
	include(__DIR__ . '/fix_mysql.inc');
	include(__DIR__ . '/config.inc');
	
	// Global functions
	include(__DIR__ . '/functions.inc');

	// Set date and time of report generation
	$timestamp = date("U");
	$date = date("Y-m-d");
	
	// Set variables based on command line parameters, if on production server
	if ($environment == 'prod') {
		$tsv_filepath = $argv[1];
		$client_id = $argv[2];
		$output_filepath_and_name = $argv[3];
		$json_filepath = $argv[4];
		$template_name = $argv[5];
		$output_tsv_clin_sig_filepath_and_name = $argv[6]; // OPTIONAL; generates the original .tsv file with final clinical significance column added
		
		// Required parameters
		if ($tsv_filepath == '' || $client_id == '' || $output_filepath_and_name == '' || $json_filepath == '' || $template_name == '') die('All of the required parameters are not provided.');
	}
	
	// Connect to database
	$link = mysql_connect($db_server, $db_username, $db_password);
	if (!$link) { die('Could not connect:' . mysql_error()); }
	$db_selected = mysql_select_db($db_name, $link);
	if (!$db_selected) { die ('Cannot use : ' . mysql_error()); }
	
	// MySQL check to see if all tables needed exist in the tablespace (eg. on the server)
	$required_tables = array(
		'clin_sig_resolver',
		'clinvar_clin_sig_grch37_08_14_2017',
		'cosmic_v80_cosmicmutantexportcensus',
		'variant_blacklist',
		'mutalyzer_hgvs_brca1_05242017',
		'umd_clin_sig',
		'brca_exchange_clin_sig',
		'sgi_added_variants');
	$result = mysql_list_tables($db_name) or die('MySQL Error: ' . mysql_error());
	while ($row = mysql_fetch_row($result)) {
		$list_tables[] = $row[0];
	}
	
	// Do not proceed if not all required tables exist
	$containsAllNeeded = 0 == count(array_diff($required_tables, $list_tables));
	if (!$containsAllNeeded) {
		die("Not all required MySQL tables exist in the tablespace $db_name on server $db_server, please check MySQL configuration and/or synchronization. \n Required: " . implode(", ", $required_tables));
	}
	
	// Check mpdf library location
	if (!file_exists($mpdf_location)) {
		die("The mpdf library/location does not exist. Please check the config.inc file.");
	}
	
	// *** END SCRIPT CONFIGURATION /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// Apply Clinical Significance Algorithm
	function getFinalClinicalSignificance($template_name, $gene, $hgvs_c, $hgvs_p, $freq, $chromosome, $position, $ref, $alt, $genotype, $location, $exon, $intron, $coverage, $cosmic_id, $variant_effect, $type) {
		//echo "<b>$gene $hgvs_c $hgvs_p</b><br>";
		// Database connection
		global $link;
		
		// Arrays to fill for usage in table and report display
		global $clinvar_coord_clin_sigs, $clinvar_coord_clin_sig_notes, $clinvar_clin_sigs, $clin_sig_notes, $blacklist_notes, $sgi_clin_sigs, $sgi_clin_sig_notes, $sgi_notes, $clinvar_clin_sig_notes, $umd_clin_sigs, $umd_clin_sig_notes, $brca_exchange_clin_sigs, $brca_exchange_clin_sig_notes, $cosmic_predictions, $cosmic_prediction_notes, $lovd_predictions, $lovd_prediction_notes, $clinvitae_clin_sigs, $clinvitae_clin_sig_notes, $final_clin_sigs;
		
		// Check against blacklist arrays
		global $blacklist_variants, $blacklist;
		
		// Render final variables for report to display
		global $variant_ignore_reasons, $final_display_variants;
		global $final_report_clin_sig, $final_report_gene, $final_report_hgvs_c, $final_report_chromosome, $final_report_position, $final_report_location, $final_report_exon, $final_report_intron, $final_report_coverage, $final_report_hgvs_p, $final_report_orig_hgvs_p, $final_report_type, $final_report_freq, $final_report_cosmic_id, $final_report_genotype, $final_report_ref, $final_report_alt, $final_report_variant_effect;
		
		// ClinVar Coordinates check
		if (list($clinvar_coord_clin_sig, $clinvar_coord_clin_sig_note) = getClinVarCoord($chromosome, $position, $ref, $alt)) {
			$found_clinvar_coord_clin_sig = TRUE;
			$clinvar_coord_clin_sigs[] = $clinvar_coord_clin_sig;
			$clinvar_coord_clin_sig_notes[] = ' <span style=font-size:8.5pt>[' . $clinvar_coord_clin_sig_note . ']</span>';
		} else {
			$clinvar_coord_clin_sigs[] = '';
			$clinvar_coord_clin_sig_notes[] = '';
		}
		
		// ClinVar hgvs_c
		if (list($clinvar_clin_sig, $clinvar_clin_sig_note, $hgvs_c_lookup) = getClinVar($gene, $hgvs_c, $hgvs_p, $location, $type)) {
			if ($clinvar_clin_sig != '' && $clinvar_clin_sig_note != '') {
				$found_clinvar_clin_sig = TRUE;
				$clinvar_clin_sigs[] = $clinvar_clin_sig;
				$clinvar_clin_sig_notes[] = ' <span style=font-size:8.5pt>[' . $clinvar_clin_sig_note . ']</span>';
			} else {
				$clinvar_clin_sigs[] = '';
				$clinvar_clin_sig_notes[] = '';
			}
		}
		
		// UMD
		if (list($umd_clin_sig, $umd_clin_sig_note) = getUMD($gene, $hgvs_c, $hgvs_p)) {
			$found_umd_clin_sig = TRUE;
			$umd_clin_sigs[] = $umd_clin_sig;
			$umd_clin_sig_notes[] = ' <span style=font-size:8.5pt>[' . $umd_clin_sig_note . ']</span>';
		} else {
			$umd_clin_sigs[] = '';
			$umd_clin_sig_notes[] = '';
		}
		
		// BRCA Exchange
		if (list($brca_exchange_clin_sig, $brca_exchange_clin_sig_note) = getBRCAExchange($gene, $hgvs_c, $hgvs_p)) {
			$found_brca_exchange_clin_sig = TRUE;
			$brca_exchange_clin_sigs[] = $brca_exchange_clin_sig;
			$brca_exchange_clin_sig_notes[] = ' <span data-toggle = "tooltip" title = "' . $brca_exchange_clin_sig_note . '" style=font-size:8.5pt>[' . substr($brca_exchange_clin_sig_note, 0, 85) . '...]</span>';
		} else {
			$brca_exchange_clin_sigs[] = '';
			$brca_exchange_clin_sig_notes[] = '';
		}
		
		// COSMIC
		if (list($cosmic_prediction, $cosmic_prediction_note) = getCOSMIC($gene, $hgvs_c, $hgvs_p)) {
			$found_cosmic_prediction = TRUE;
			$cosmic_predictions[] = $cosmic_prediction;
			$cosmic_prediction_notes[] = ' <span style=font-size:8.5pt>[' . $cosmic_prediction_note . ']</span>';
		} else {
			$cosmic_predictions[] = '';
			$cosmic_prediction_notes[] = '';
		}
		
		// LOVD
		if (list($lovd_prediction, $lovd_prediction_note) = getLOVD($gene, $hgvs_c, $hgvs_p)) {
			$found_lovd_prediction = TRUE;
			$lovd_predictions[] = $lovd_prediction;
			$lovd_prediction_notes[] = ' <span style=font-size:8.5pt>[' . $lovd_prediction_note . ']</span>';
		} else {
			$lovd_predictions[] = '';
			$lovd_prediction_notes[] = '';
		}
		
		// Clinvitae
		if (list($clinvitae_clin_sig, $clinvitae_clin_sig_note) = getClinvitae($gene, $hgvs_c, $hgvs_p)) {
			$found_clinvitae_clin_sig = TRUE;
			$clinvitae_clin_sigs[] = $clinvitae_clin_sig;
			$clinvitae_clin_sig_notes[] = ' <span style=font-size:8.5pt>[' . $clinvitae_clin_sig_note . ']</span>';
		} else {
			$clinvitae_clin_sigs[] = '';
			$clinvitae_clin_sig_notes[] = '';
		}
		
		// SGI database
		if (list($sgi_clin_sig, $sgi_clin_sig_note) = getSGI($gene, $hgvs_c, $hgvs_p)) {
			$found_sgi_database = TRUE;
			$sgi_clin_sigs[] = $sgi_clin_sig;
			$sgi_clin_sig_notes[] = ' <span style=font-size:8.5pt>[' . $sgi_clin_sig_note . ']</span>';
		} else {
			$sgi_clin_sigs[] = '';
			$sgi_clin_sig_notes[] = '';
		}
		
		// Check to see if the variant is in the blacklist
		if (in_array($gene . ' ' . $hgvs_c, $blacklist_variants)) {
			$found_blacklist = TRUE;
			$blacklist[] = $gene . ' ' . $hgvs_c;
		} else {
		}
		
		// Evaluate and get Clinical Significance Conclusion based on hierarchy and logic
		// HIERARCHY = Blacklist --> SGI database --> ClinVar Coord --> ClinVar hgvs_c --> UMD --> BRCA Exchange --> Inconclusive
		if ($found_blacklist) {
			$final_clin_sig = 'BLACKLIST';
		} else if ($found_sgi_database) {
			$final_clin_sig = trim($sgi_clin_sig);
		} else if ($found_clinvar_coord_clin_sig) {
			$final_clin_sig = trim($clinvar_coord_clin_sig);
		} else if ($found_clinvar_clin_sig) {
			$final_clin_sig = trim($clinvar_clin_sig);
		} else if ($found_umd_clin_sig) {
			$final_clin_sig = trim($umd_clin_sig);
		} else if ($found_brca_exchange_clin_sig) {
			$final_clin_sig = trim($brca_exchange_clin_sig);
		} else {
			$final_clin_sig = '0-Inconclusive';
		}
		
		// Set flags for inconsistencies
		// Set flag if UMD and ClinVar are not equal
		if ($umd_clin_sig != '' && ($umd_clin_sig != $clinvar_clin_sig || $umd_clin_sig != $clinvar_coord_clin_sig))  {
			// See if this clinical significance has been resolved in the database (which is a separate table)
			$sql = "SELECT * FROM clin_sig_resolver WHERE gene = '$gene' AND codon = '$hgvs_c'";
			$result = mysql_query($sql, $link);
			$row = mysql_fetch_assoc($result);

			if ($row['id'] != '') {
				// Resolved data exists so overwrite the clinical significance to what is in the database
				$note_db = "<br>&nbsp; &nbsp; &nbsp; <b>Resolved</b> as " . $row['resolved_clin_sig'] . " on " . $row['date_resolved'] . ": " . $row['references_comments'] . "</i> <a class='label label-warning' href=\"resolve.php?type=update&gene=" . $gene . "&variation=" . $hgvs_c . "\" onclick=\"window.open(this.href,'targetWindow', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500'); return false;\" style=\"color: black; border: 1px solid black;\">Update</a>";
				$final_clin_sig = $row['resolved_clin_sig'];
			} else {
				// Resolved data does not exist so offer a link
				$note_db = " <a class='label label-warning' href=\"resolve.php?new=yes&gene=" . $gene . "&variation=" . $hgvs_c . "\" onclick=\"window.open(this.href,'targetWindow', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500'); return false;\" style='color: black; border: 1px solid black;'>Resolve?</a></i>";
			}
			$clin_sig_notes[] = '<br>&nbsp; <i class="fa fa-check-square-o"></i> <b>Check UMD and ClinVar</b> for possible conflict' . $note_db;
		} else {
			$clin_sig_notes[] = '';
		}
		
		// Generate blacklist string
		if ($found_blacklist) {
			// Blacklist data exists
			$blacklist_notes[] = " <a class='label label-default' href=\"blacklist.php?submit=1&type=delete_or_edit&notes=" . $row['notes'] . "&gene=" . $gene . "&variation=" . $hgvs_c . "\" onclick=\"window.open(this.href,'targetWindow', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500'); return false;\" style='border: 1px solid black;'>Edit/Remove from blacklist</b></a>";
		} else {
			// Blacklist data does not exist so offer a link
			$blacklist_notes[] = " <a class='label label-default' href=\"blacklist.php?gene=" . $gene . "&variation=" . $hgvs_c . "\" onclick=\"window.open(this.href,'targetWindow', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500'); return false;\" style='border: 1px solid black;'>Add blacklist</a>";
		}

		// Generate add or override variant string for SGI database
		if ($found_sgi_database) {
			// SGI data exists and clinical significance overrides all other sources
			$sgi_notes[] = " <a class='label label-info'href=\"add_variant.php?submit=1&type=delete_or_edit&aa_change=" . $hgvs_p . "&gene=" . $gene . "&codon=" . $hgvs_c . "\" onclick=\"window.open(this.href,'targetWindow', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500'); return false;\" style=\"color: black; border: 1px solid black;'\">Edit/Remove from SGI database</a>";
		} else {
			if (!$found_blacklist) {
				// SGI added variant data does not exist so offer a link
				$sgi_notes[] = " <a class='label label-primary' href=\"add_variant.php?gene=" . $gene . "&codon=" . $hgvs_c . "&aa_change=" . $hgvs_p . "\" onclick=\"window.open(this.href,'targetWindow', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500'); return false;\" style='border: 1px solid black;'>Add SGI database</a>\n";
			} else {
				$sgi_notes[] = '';
			}
		}
		
		// Add to array of final clinical signficances
		$final_clin_sigs[] = $final_clin_sig;
		//echo "<br>FINAL CLIN SIG = " . $final_clin_sig;
		
		// Initialize final ignore reasons 
		$ignore_reasons = array();
		
		// Filtering algorithm
		// Never show variants that are on the blacklist
		if ($final_clin_sig == 'BLACKLIST') {
			$ignore_reasons[] = "On blacklist";
		}
		
		// Never show variants that are less than 5%
		if ($freq < 0.05) {
			$ignore_reasons[] = '<5%';
		}
		
		// Synonymous check
		if ($variant_effect == 'synonymous_variant') {
			if (stristr($final_clin_sig, 'pathogenic') || $final_clin_sig == '3-Uncertain' || $final_clin_sig == '0-Inconclusive') {
				// Continue
			} else {
				$ignore_reasons[] = 'Synonymous variant that is not P/LP/Unc/Incl';
			}
		}
		
		// Only show non-exon variants that are Pathogenic or Likely Pathogenic
		if ($location != 'exon') {
			if ($final_clin_sig != '5-Pathogenic' && $final_clin_sig != '4-Likely Pathogenic') {
				$ignore_reasons[] = 'Non-exon and not P/LP';
			}
		}
		
		// Sample type check
		if ($freq >= 0.2) {
			// Continue
		} else if ($freq < 0.2 && $template_name == 'seqstore_ffpe_cn') {
			// Continue
		} else {
			// Ignore
			$ignore_reasons[] = 'Sample type check failed';
		}
		
		// Allele change check
		if ($freq >= 0.1) {
			// Continue
		} else if ($freq >= 0.05 && $freq < 0.1 && !(stristr($hgvs_c, "C>T") || stristr($hgvs_c, "G>A"))) {
			// Continue
		} else {
			// Ignore
			$ignore_reasons[] = 'Allele change check failed';
		}
		
		// Clinical significance check
		if ($freq >= 0.2) {
			// Continue
		} else if ($freq < 0.2 && (stristr($final_clin_sig, 'pathogenic') || $final_clin_sig == '3-Uncertain')) {
			// Continue
		} else if ($freq < 0.2 && ($final_clin_sig == '0-Inconclusive' && $cosmic_id != 'N/A')) {
			// Continue
		} else {
			// Ignore
			$ignore_reasons[] = 'Clinical significance check failed';
		}
		
		if (!empty($ignore_reasons)) {
			$variant_ignore_reasons[] = ' | <i class="fa fa-times"></i> Ignore: ' . implode(', ', $ignore_reasons);
		} else {
			// The variant has no ignore reasons and will display
			$variant_ignore_reasons[] = '';
			$final_display_variants[] = $gene . ' ' . $hgvs_c . ' ' . $freq;
			
			// Assign the variant to the final list arrays for report display
			$final_report_clin_sig[] = $final_clin_sig;
			$final_report_gene[] = $gene;
			
			// Update BRCA1 NM_7300.3 to NM_7294.3, if different 
			if ($gene == 'BRCA1' && $hgvs_c != $hgvs_c_lookup && $hgvs_c_lookup != '') {
				$final_report_hgvs_c[] = $hgvs_c_lookup;
				
				// Get hgvs_p from ClinVar database
				$sql_hgvsp = "SELECT hgvs_p 
							  FROM clinvar_clin_sig_grch37_08_14_2017
							  WHERE gene = '" . $gene . "'
							  AND hgvs_c = '" . $hgvs_c_lookup . "'";
				//echo "$gene | $hgvs_c | $hgvs_c_lookup | $hgvs_p <br><br>";
				$result = mysql_query($sql_hgvsp, $link);
				$row = mysql_fetch_assoc($result);
				
				
				if ($row['hgvs_p'] != '') {
					$final_report_hgvs_p[] = $row['hgvs_p'];
					$final_report_orig_hgvs_p[] = $hgvs_p;
				} else {
					if ($hgvs_c != $hgvs_c_lookup) {
						// Subtract 21 (63/3) from the original hgvs_p
						$hgvs_p_num = filter_var($hgvs_p, FILTER_SANITIZE_NUMBER_INT);
						$new_hgvs_p_num = $hgvs_p_num - 21;
						$final_report_hgvs_p[] = preg_replace("/[0-9]+/", $new_hgvs_p_num, $hgvs_p);
						$final_report_orig_hgvs_p[] = $hgvs_p;
					} else {
						$final_report_hgvs_p[] = $row['hgvs_p'];
						$final_report_orig_hgvs_p[] = $hgvs_p;
					}
				}
			} else {
				if ($hgvs_c == '') {
					$final_report_hgvs_c[] = 'N/A';
				} else {
					$final_report_hgvs_c[] = $hgvs_c;
				}
				
				if ($hgvs_p == '') {
					$final_report_hgvs_p[] = 'N/A';
					$final_report_orig_hgvs_p[] = 'N/A';
				} else {
					$final_report_hgvs_p[] = $hgvs_p;
					$final_report_orig_hgvs_p[] = $hgvs_p;
				}
			}
			
			$final_report_chromosome[] = $chromosome;
			$final_report_position[] = $position;
			$final_report_location[] = $location;
			$final_report_exon[] = $exon; 
			$final_report_intron[] = $intron;
			$final_report_coverage[] = $depthofcoverage;
			$final_report_type[] = $type;
			$final_report_freq[] = $freq;
			$final_report_cosmic_id[] = $cosmic_id;
			$final_report_genotype[] = $genotype;
			$final_report_ref[] = $ref;
			$final_report_alt[] = $alt;
			$final_report_variant_effect[] = $variant_effect;
		}
	}
	
	// *** ALLOW UPLOAD OF TSV FILE FROM WEB BROWSER ////////////////////////////////////////////////////////////////////////////////////////////////
	// Show HTML page to allow uploading of local file
	if ($environment == 'dev') { 
		// Set character set to be UTF-8 to handle Chinese characters
		header('Content-Type: text/html; charset=UTF-8');
	?>
	
	<html>
		<head>
			<meta charset="utf-8">
			<meta http-equiv="X-UA-Compatible" content="IE=edge">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<link rel="stylesheet" href="font-awesome/css/font-awesome.min.css">
			
			<!-- Bootstrap -->
			<link href="bootstrap/css/bootstrap.min.css" rel="stylesheet">
			
			<!-- Custom CSS styling for dev html page -->
			<style>
				body { font-family: monospace; font-size: 9pt; margin: 10px; }
				.filtered_headers { font-size: 10pt; }
				.filtered_data { font-size: 8.5pt; }
				#navWrap { overflow:hidden; }
				#nav { padding: 5px; background: #ffffcc; overflow:hidden; }
				br.clearLeft { clear: left; ​}
			</style>
			
			<!-- jQuery -->
			<script src="bootstrap/js/jquery.min.js"></script>
			<script src="bootstrap/js/bootstrap.min.js"></script>
			<script src="bootstrap/js/jquery.dataTables.min.js"></script>
		
			<!-- jQuery datatables plugin to sort and display tables -->
			<link href="bootstrap/css/jquery.dataTables.min.css" rel="stylesheet">
			
			<!--Javascript and JQuery functions -->
			<script language="javascript">
				// Tooltip functionality
				$(function () {
					$('[data-toggle="tooltip"]').tooltip();
					$('#example').DataTable({
						"pageLength": 50
					});
				})
				
				// Show/hide div functionality
				function toggler(divId) {
					$("#" + divId).toggle();
				}
				
				// Fixed navbar for reported variants
				$(function() {
					// Stick the #nav to the top of the window
					var nav = $('#nav');
					var navHomeY = nav.offset().top;
					var isFixed = false;
					var $w = $(window);
					$w.scroll(function() {
						var scrollTop = $w.scrollTop();
						var shouldBeFixed = scrollTop > navHomeY;
						if (shouldBeFixed && !isFixed) {
							nav.css({
								position: 'fixed',
								top: 0,
								left: nav.offset().left,
								width: nav.width()
							});
							isFixed = true;
						} else if (!shouldBeFixed && isFixed) {
							nav.css({
								position: 'static'
							});
							isFixed = false;
						}
					});
				});
			</script>
		</head>
		<body>
		<a name="top"></a>
		<h2><img align="middle" width="100" src="./images/small_singlera_logo.png"><b>|TSV file processing - BRCAim</b></h2>
	<?php
	}

	// Allow TSV file upload 
	if ($environment == 'dev' && !$submit) {
		?>
		
		<div class="panel panel-default">
			<div class="panel-body">
				This script creates a formatted BRCAim BRCA1/2 PDF report based on an uploaded TSV file.<br>
				<b>Select .tsv file to upload:</b>
			</div>
			<div class="panel-footer">
				<form action="brcaim_tsv_analysis.php" method="post" enctype="multipart/form-data">
						<input type="file" class="btn btn-primary" name="fileToUpload"><br>
						<?php
							if (isset($DEV) && $DEV == 'YES') {
								?>
								
								<input type="hidden" name="DEV" value="YES">
								
								<?php
							}
						?>
						
						<select class="btn btn-primary" name="template_name">
							<option value="">- Choose template -</option>
							<option value="seqstore_blood_cn">seqstore_blood_cn</option>
							<option value="seqstore_ffpe_cn">seqstore_ffpe_cn</option>
						</select><br><br>

						<input class='btn btn-info' type="submit" value="Submit" name="submit">

				</form>
			</div>
		</div>
		
		<?php
	} else {
		if ($environment == 'dev') {
			// Allow uploading of new tsv file for development purposes
			if ($DEV == 'YES') {
				// Maintain development environment on MDQ Server 3 (because $environment autocheck is Windows (local) vs Linux (server))
				echo "<i class='fa fa-file-o'></i> <a href='brcaim_tsv_analysis.php?DEV=YES'>[New File]</a><br>\n";
			} else {
				echo "<i class='fa fa-file-o'></i> <a href='brcaim_tsv_analysis.php'>[New File]</a><br>\n";
			}
			
			// This allows display of the progress bar while the script is still executing
			if (ob_get_level() == 0) ob_start();
			?>
			
			<div class="progress">
				<div id="processing" class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width:100%">
					<b>Processing...</b>
				</div>
			</div>

			<?php
			ob_flush();
			flush();
			ob_end_flush();
			
			// Upload .tsv file as temporary file to disk
			if ($fileToUpload) {
				$target_file = $uploads_folder . basename($_FILES["fileToUpload"]["name"]);
				
				 if (move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file)) {
					  echo "The file has been uploaded as: " . $target_file . ".<br>";
					  $tsv_filepath = $target_file;
				 } else {
					  die("Error uploading the file.");
				 }
				 ?>
				
				<script language="Javascript">
					$('#processing').html("<b>Done</b>");
					$('#processing').removeClass("progress-bar-striped active");
					$('#processing').addClass("progress-bar-success");
				</script>
				 
				 <?php
			}
		}
		
		// Process the tsv file line by line; this is pre-processing (just getting all of the data into arrays)
		$file = fopen($tsv_filepath, "r");
		if (!$file) die("File does not exist or cannot open file.");
		$line_number = 0;
		while(!feof($file)){
			$line = fgets($file);
			$row_data = array();
			 
			// Break each line by tab-delimiter
			$row_data = explode("\t", $line);
				
			// Get headers and dynamically assign into array (will work with any header names (will need to process reserved characters) and amount) 
			// Chromosome | Position | Reference | Alternate | Type | Genotype | MinorAlleleFraction | DepthOfCoverage | Allele | Consequence | IMPACT | SYMBOL | Gene | Feature_type | Feature | BIOTYPE | EXON | INTRON | HGVSc | HGVSp | cDNA_position | 
			// CDS_position | Protein_position | Amino_acids | Codons | Existing_variation | DISTANCE | STRAND | FLAGS | SYMBOL_SOURCE | HGNC_ID | ENSP | RefSeq | HGVS_OFFSET | GMAF | AFR_MAF | AMR_MAF | EAS_MAF | EUR_MAF | SAS_MAF | CLIN_SIG | SOMATIC | PHENO | PUBMED
			
			if ($line_number == 0) {
				// First row contains the header titles which are used as the variable names for the arrays
				for ($a = 0; $a < sizeof($row_data); $a++) {
					// Clean up array variable name (replace spaces and special characters (ex. Ref+/Ref-/Var+/Var- column)
					$header_variable = strtolower(str_replace(" ", "_", $row_data[$a]));
					$header_variable = str_replace("+", "_", $header_variable);
					$header_variable = str_replace("-", "_", $header_variable);
					$header_variable = str_replace("/", "_", $header_variable);
					
					// The raw data arrays from the .tsv file are prepended with 'list_'
					$all_headers[] = 'list_' . trim($header_variable);
				}
			} else {
				// Remaining rows of the tsv file are data rows/values that are assigned to the appropriate header variables derived from the above arrays
				for ($x = 0; $x < sizeof($row_data); $x++) {
					// Assign values to individual arrays
					${$all_headers[$x]}[] = trim($row_data[$x]);
				}
			}
			
			$line_number++;
		}
		
		// Close the TSV file
		fclose($file);
		// *** END ALLOW UPLOAD OF TSV FILE FROM WEB BROWSER ////////////////////////////////////////////////////////////////////////////////////////

		// *** PROCESS DATA AND GENERATE VARIABLES AND ARRAYS FOR PDF REPORT ////////////////////////////////////////////////////////////////////////
		// Remove Ensembl prefix in front of HGVS_c and HGVS_p for compact display
		$hgvsc_replace = array("ENST00000544455.1:", "ENST00000471181.2:");
		$hgvsp_replace = array("ENSP00000439902.1:", "ENSP00000418960.2:", "ENST00000471181.2:", "ENST00000544455.1:");
		
		// Array to store BRCA1 transcript conversion, if any
		$new_coding_positions = array();
		
		// Loop over each row of data which were stored in arrays from the tsv file processing above
		for ($x = 0; $x < sizeof($list_chromosome); $x++) {
			// Remove transcript designation in front of cds to allow for simple searching
			$list_hgvsc[$x] = str_replace($hgvsc_replace, "", $list_hgvsc[$x]);
			$list_hgvsp[$x] = str_replace($hgvsp_replace, "", $list_hgvsp[$x]);
			
			// Allow for possiblel BRCA1 codon position adjustment
			unset($new_coding_position);
			
			// Number of PASS variants to evaluate
			$num = 0;
			
			// ALLOW ONLY filter == 'PASS' (and only BRCA1 and BRCA2 genes) to be included in the pdf report (show all of the raw data as a hidden table)
			if ($list_filter[$x] == 'PASS' && ($list_symbol[$x] == 'BRCA1' || $list_symbol[$x] == 'BRCA2')) {
				// Create arrays from IR data specifically used for pdf generation with initial string formatting
				$TSV_filtered_list_num[] = $num;	// Original order sequential numbering
				$TSV_filtered_list_chromosome[] = str_replace('chr', '', $list_chromosome[$x]);	// Remove 'chr' in front of the chromosome number
				$TSV_filtered_list_position[] = $list_position[$x];	// GRCh37 genomic position start
				$TSV_filtered_list_genotype[] = $list_genotype[$x];	// Genotype designation
				$TSV_filtered_list_ref[] = $list_reference[$x];	// Reference allele
				$TSV_filtered_list_alt[] = $list_alternate[$x];	// Alternate allele
				$TSV_filtered_list_refseq[] = $list_refseq[$x];	// RefSeq transcript name
				$TSV_filtered_list_type[] = $list_type[$x];	// Type of variant (ex. SNP)
				$TSV_filtered_list_freq[] = $list_minorallelefraction[$x];	// Allele fraction in decimal
				$TSV_filtered_list_genes[] = $list_symbol[$x];	// Gene name (BRCA1 or BRCA2)
				$TSV_filtered_list_location[] = $list_location[$x];	// Location of variant (ex. intron, exon, etc.)
				$TSV_filtered_list_exon[] = get_to_first_char($list_exon[$x], "/");	// Exon number/total exons
				$TSV_filtered_list_intron[] = $list_intron[$x];	// Intron number/total introns
				$TSV_filtered_list_hgvs_c[] = $list_hgvsc[$x];	// HGVSC format
				$TSV_filtered_list_hgvs_p[] = $list_hgvsp[$x];	// HGVSP format
				$TSV_filtered_list_variant_effect[] = $list_consequence[$x];	// Consequence of variant (ex. missense)
				$TSV_filtered_list_clinvar[] = $list_clin_sig[$x];	// Original clinical significance from sequencer
				$TSV_filtered_list_coverage[] = $list_depthofcoverage[$x];	// Depth of coverage
				
				// Search for COSMIC ID, using the most recent database release, to be included into the report 
				// *************** if ($list_type == 'SNV') // add in all types to format the genome position for COSMIC searching
				$sql_cosmic = "SELECT DISTINCT mutation_id FROM cosmic_v80_cosmicmutantexportcensus WHERE gene_name = '" . $list_symbol[$x] . "' AND mutation_genome_position = '" . str_replace('chr', '', $list_chromosome[$x]) . ":" . $list_position[$x] . "-" . $list_position[$x] . "' AND mutation_cds NOT LIKE '%?%'";
				//echo $sql_cosmic . "<br>";
				$result = mysql_query($sql_cosmic, $link);
				if ($row = mysql_fetch_assoc($result)) {
					$TSV_filtered_list_cosmic_id[] = $row['mutation_id'];
				} else {
					$TSV_filtered_list_cosmic_id[] = 'N/A';
				}
				
				$num++;
			}
		}
		
		// Loop over each PASSED variant to determine its clinical significance
		for ($v = 0; $v < sizeof($TSV_filtered_list_genes); $v++) {
			// Load blacklist variants into array
			$sql = "SELECT * FROM variant_blacklist";
			$result = mysql_query($sql, $link);
			while ($row = mysql_fetch_assoc($result)) {
				$blacklist_variants[] = $row['gene'] . ' ' . $row['cds'];
			}
			
			// Evaluate for clinical significance conclusion
			getFinalClinicalSignificance($template_name, $TSV_filtered_list_genes[$v], $TSV_filtered_list_hgvs_c[$v], $TSV_filtered_list_hgvs_p[$v], $TSV_filtered_list_freq[$v], $TSV_filtered_list_chromosome[$v], $TSV_filtered_list_position[$v], $TSV_filtered_list_ref[$v], $TSV_filtered_list_alt[$v], $TSV_filtered_list_genotype[$v], $TSV_filtered_list_location[$v], $TSV_filtered_list_exon[$v], $TSV_filtered_list_intron[$v], $TSV_filtered_list_coverage[$v], $TSV_filtered_list_cosmic_id[$v], $TSV_filtered_list_variant_effect[$v], $TSV_filtered_list_type[$v]);
		}
		
		// *** PREPARE FOR PDF GENERATION ///////////////////////////////////////////////////////////////////////////////////////////////////////////
		// *** SHOW AND ASSIGN JSON FILE CONTAINING QUALITY METRICS DATA !!! EXAMPLE FILE GIVEN !!! Production will have specified JSON file from command line parameter
		if ($environment == 'dev') {
			$json_filepath = './uploads/exampleSQM.json';
		}
		
		$json_data = json_decode(file_get_contents($json_filepath));
		
		// Assign variables
		$ontarget_read_count = $json_data->{'ontarget_read_count'};
		$fraction_target_covered = $json_data->{'fraction_target_covered'};
		foreach($json_data->{'read_counts_per_region'} as $json => $value){
			$read_counts_per_region_list[] = $value;
		}
		$uniformity = $json_data->{'uniformity'};
		$total_read_count = $json_data->{'total_read_count'};
		foreach($json_data->{'read_counts_per_amplicon'} as $json => $value){
			$read_counts_per_amplicon[] = $value;
		}
		$fraction_known_sites_covered = $json_data->{'fraction_known_sites_covered'};
		$mapped_read_count = $json_data->{'mapped_read_count'};
		$average_amplicon_coverage = $json_data->{'average_amplicon_coverage'};
		$calculated_average_amplicon_coverage = array_sum($read_counts_per_amplicon)/count($read_counts_per_amplicon);
		
		// Sample level data can be provided by URL or command line variables
		($first_name == '' || $first_name == '0') ?  $list_patient_firstname[0] = 'NA' : $list_patient_firstname[0] = $first_name;
		($last_name == '' || $last_name == '0') ? $list_patient_lastname[0] = '' : $list_patient_lastname[0] = $last_name;
		($date_of_birth == '' || $date_of_birth == '0') ? $list_patient_dob[0] = 'NA' : $list_patient_dob[0] = $date_of_birth;
		($age == '' || $age == '0') ? $list_patient_age[0] = 'NA' : $list_patient_age[0] = $age;
		($gender == '' || $gender == '0') ? $list_patient_gender[0] = 'NA' : $list_patient_gender[0] = $gender;
		($received_date == '' || $received_date == '0') ? $list_specimen_received[0] = 'NA' : $list_specimen_received[0] = $received_date;
		($indication == '' || $indication == '0') ? $list_indication[0] = 'NA' : $list_indication[0] = ucfirst($indication);
		($sample_type == '' || $sample_type == '0') ? $list_sample_type[0] = 'NA' : $list_sample_type[0] = $sample_type;
		($ordering_dr == '' || $ordering_dr == '0') ? $list_ordering_physician[0] = 'NA' : $list_ordering_physician[0] = $ordering_dr;
		($additional_dr == '' || $additional_dr == '0') ?  $list_additional_physician[0] = 'NA' : $list_additional_physician[0] = $additional_dr;
		($institution == '' || $institution == '0') ? $list_institution[0] = 'NA' : $list_institution[0] = $institution;
		
		// Select client logo to display on front page -- testing uses default.png
		switch (strtolower($client_id)) {
			case "sgi":
				$logo_image = 'sgi.png';
				break;
			case "huayin":
				$logo_image = 'huayin.png';
				break;
			case "xiangya":
				$logo_image = 'xiangya.png';
				break;
			case "puth":
				$logo_image = 'puth.png';
				break;
			default:
				$logo_image = 'default.png';
		}
		
		// Display portion of filename on report
		$report_filename = str_replace('.report.tsv', '', basename($tsv_filepath));
		$report_filename = preg_replace('/_\d+/', '', $report_filename);
		
		// *** FINALIZE LIST OF VARIANTS (AFTER PASS AND TEMPLATE FILTERS) *** //
		$before_sort_final_report_clin_sig = $final_report_clin_sig; // Maintain original order to regenerate the tsv file
		if (sizeof($final_report_gene) > 0) {
			array_multisort(
				$final_report_clin_sig, SORT_DESC, 
				$final_report_gene,
				$final_report_hgvs_c, 
				$final_report_chromosome, 
				$final_report_position, 
				$final_report_location, 
				$final_report_exon, 
				$final_report_intron, 
				$final_report_coverage,  
				$final_report_hgvs_p,  
				$final_report_type,  
				$final_report_freq, 
				$final_report_cosmic_id, 
				$final_report_genotype,  
				$final_report_ref,  
				$final_report_alt,  
				$final_report_variant_effect);
		}
		
		// *** END PREPARE FOR PDF GENERATION ///////////////////////////////////////////////////////////////////////////////////////////////////////
		
		// *** OUTPUT PDF ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// All data arrays and variables are set for final report formatting and display
		// Set html folder based on template selected
		if ($template_name == 'seqstore_blood_cn') {
			$html_folder = 'html_pages_seqstore_blood_cn';
		} elseif ($template_name == 'seqstore_ffpe_cn') {
			$html_folder = 'html_pages_seqstore_ffpe_cn';
		}
		
		include("generate_pdf.inc");
		
		if ($environment == 'dev') {
			if ($DEV == 'YES') {
				// Save to MDQ Server 3 
				$output_file = $output_folder . $timestamp . '_' . str_replace('.tsv', '', basename($tsv_filepath)) . '_' . $template_name . '.pdf'; 
				$output_browser = 'http://192.168.1.23/php/john/dev/new_brcaim_v3/temp_pdf/' . $timestamp . '_' . str_replace('.tsv', '', basename($tsv_filepath)) . '_' . $template_name . '.pdf';
				$mpdf->Output($output_file, 'F');
			} else {
				// Save pdf file to local Windows development computer to allow preview
				$output_file = 'C:\Apache24\htdocs\new_brcaim_v3\temp_pdf\new_brcaim_v3_report_' . $timestamp . '_' . str_replace('.tsv', '', basename($tsv_filepath)) . '_' . $template_name . '.pdf'; 
				$output_browser = str_replace('C:\Apache24\htdocs\new_brcaim_v3\\', '', $output_file);
				$mpdf->Output($output_file, 'F');
				
				// Delete pdf files older than 12 hours from preview directory (to save disk space for development purposes)
				$dir = 'C:\Apache24\htdocs\new_brcaim_v3\temp_pdf\\';
				foreach (glob($dir."*") as $file) {
					if (filemtime($file) < time() - 43200) {
						unlink($file);
					}
				}
			}
			
			// Show link to pdf file
			echo "<br><img src='" . $images_folder . "pdf-icon.jpg'> <a style='font-size: 16px; font-weight: bold;' target='_blank' href='$output_browser'>Report PDF Preview</a> (<b>Template: $template_name</b>)\n";
			
			// Output clin_sig text file
			$tsv_string_output = "Chromosome\tPosition\tReference\tAlternate\tType\tGenotype\tMinorAlleleFraction\tDepthOfCoverage\tFilter\tHomopolymerLength\tSource\tAllele\tConsequence\tIMPACT\tSYMBOL\tGene\tFeature_type\tFeature\tBIOTYPE\tLocation\tEXON\tINTRON\tHGVSc\tHGVSp\tcDNA_position\tCDS_position\tProtein_position\tAmino_acids\tCodons\tExisting_variation\tDISTANCE\tSTRAND\tFLAGS\tSYMBOL_SOURCE\tHGNC_ID\tENSP\tRefSeq\tHGVS_OFFSET\tGMAF\tAFR_MAF\tAMR_MAF\tEAS_MAF\tEUR_MAF\tSAS_MAF\tCLIN_SIG\tSOMATIC\tPHENO\tPUBMED\tFINAL_REPORT_DISPLAY_CLIN_SIG\n";
			$variant_count = 0;
			
			for ($z = 0; $z < sizeof($list_chromosome); $z++) {
				// Append the clinical significance if found; using gene + hgvs_c + allele_fraction to get unique identifier (to search from preprocessed original list) for variant
				if (in_array($list_symbol[$z] . ' ' . $list_position[$z] . ' ' . $list_minorallelefraction[$z], $final_display_variants_tsv)) {
					$final_report_display_clin_sig = $before_sort_final_report_clin_sig[$variant_count];
					$tsv_string_output .= "$list_chromosome[$z]\t$list_position[$z]\t$list_reference[$z]\t$list_alternate[$z]\t$list_type[$z]\t$list_genotype[$z]\t$list_minorallelefraction[$z]\t$list_depthofcoverage[$z]\t$list_filter[$z]\t$list_homopolymerlength[$z]\t$list_source[$z]\t$list_allele[$z]\t$list_consequence[$z]\t$list_impact[$z]\t$list_symbol[$z]\t$list_gene[$z]\t$list_feature_type[$z]\t$list_feature[$z]\t$list_biotype[$z]\t$list_location[$z]\t$list_exon[$z]\t$list_intron[$z]\t$list_hgvsc[$z]\t$list_hgvsp[$z]\t$list_cdna_position[$z]\t$list_cds_position[$z]\t$list_protein_position[$z]\t$list_amino_acids[$z]\t$list_codons[$z]\t$list_existing_variation[$z]\t$list_distance[$z]\t$list_strand[$z]\t$list_flags[$z]\t$list_symbol_source[$z]\t$list_hgnc_id[$z]\t$list_ensp[$z]\t$list_refseq[$z]\t$list_hgvs_offset[$z]\t$list_gmaf[$z]\t$list_afr_maf[$z]\t$list_amr_maf[$z]\t$list_eas_maf[$z]\t$list_eur_maf[$z]\t$list_sas_maf[$z]\t$list_clin_sig[$z]\t$list_somatic[$z]\t$list_pheno[$z]\t$list_pubmed[$z]\t$final_report_display_clin_sig\n";
					$variant_count++;
				}
				
				//$tsv_string_output .= "$list_chromosome[$z]\t$list_position[$z]\t$list_reference[$z]\t$list_alternate[$z]\t$list_type[$z]\t$list_genotype[$z]\t$list_minorallelefraction[$z]\t$list_depthofcoverage[$z]\t$list_filter[$z]\t$list_homopolymerlength[$z]\t$list_source[$z]\t$list_allele[$z]\t$list_consequence[$z]\t$list_impact[$z]\t$list_symbol[$z]\t$list_gene[$z]\t$list_feature_type[$z]\t$list_feature[$z]\t$list_biotype[$z]\t$list_location[$z]\t$list_exon[$z]\t$list_intron[$z]\t$list_hgvsc[$z]\t$list_hgvsp[$z]\t$list_cdna_position[$z]\t$list_cds_position[$z]\t$list_protein_position[$z]\t$list_amino_acids[$z]\t$list_codons[$z]\t$list_existing_variation[$z]\t$list_distance[$z]\t$list_strand[$z]\t$list_flags[$z]\t$list_symbol_source[$z]\t$list_hgnc_id[$z]\t$list_ensp[$z]\t$list_refseq[$z]\t$list_hgvs_offset[$z]\t$list_gmaf[$z]\t$list_afr_maf[$z]\t$list_amr_maf[$z]\t$list_eas_maf[$z]\t$list_eur_maf[$z]\t$list_sas_maf[$z]\t$list_clin_sig[$z]\t$list_somatic[$z]\t$list_pheno[$z]\t$list_pubmed[$z]\t$final_report_display_clin_sig\n";
			}
			
			// Write to tsv filename
			file_put_contents("test_clin_sig.txt", $tsv_string_output);
		} else { 
			// Production uses command line argument to save pdf file
			$full_filename_and_path = $output_filepath_and_name; 
			$mpdf->Output($full_filename_and_path,'F');
			
			// Print location of pdf and exit script - needed for Luigi
			echo $full_filename_and_path;
			
			if ($output_tsv_clin_sig_filepath_and_name) {
				// Chromosome | Position | Reference | Alternate | Type | Genotype | MinorAlleleFraction | DepthOfCoverage | Allele | Consequence | IMPACT | SYMBOL | Gene | Feature_type | Feature | BIOTYPE | EXON | INTRON | HGVSc | HGVSp | cDNA_position | 
				// CDS_position | Protein_position | Amino_acids | Codons | Existing_variation | DISTANCE | STRAND | FLAGS | SYMBOL_SOURCE | HGNC_ID | ENSP | RefSeq | HGVS_OFFSET | GMAF | AFR_MAF | AMR_MAF | EAS_MAF | EUR_MAF | SAS_MAF | CLIN_SIG | SOMATIC | PHENO | PUBMED
				
				// If the optional output_tsv_clin_sig_filepath_and_name parameter is on, then append the reported clinical significance in the supplied TSV file
				// Regenerate the full TSV file from the already defined variables
				$tsv_string_output = "Chromosome\tPosition\tReference\tAlternate\tType\tGenotype\tMinorAlleleFraction\tDepthOfCoverage\tFilter\tHomopolymerLength\tSource\tAllele\tConsequence\tIMPACT\tSYMBOL\tGene\tFeature_type\tFeature\tBIOTYPE\tLocation\tEXON\tINTRON\tHGVSc\tHGVSp\tcDNA_position\tCDS_position\tProtein_position\tAmino_acids\tCodons\tExisting_variation\tDISTANCE\tSTRAND\tFLAGS\tSYMBOL_SOURCE\tHGNC_ID\tENSP\tRefSeq\tHGVS_OFFSET\tGMAF\tAFR_MAF\tAMR_MAF\tEAS_MAF\tEUR_MAF\tSAS_MAF\tCLIN_SIG\tSOMATIC\tPHENO\tPUBMED\tFINAL_REPORT_DISPLAY_CLIN_SIG\n";
				$variant_count = 0;
				
				for ($z = 0; $z < sizeof($list_chromosome); $z++) {
					// Append the clinical significance if found; using gene + hgvs_c + allele_fraction to get unique identifier for variant
					if (in_array($list_symbol[$z] . ' ' . $list_position[$z] . ' ' . $list_minorallelefraction[$z], $final_display_variants_tsv)) {
						$final_report_display_clin_sig = $before_sort_final_report_clin_sig[$variant_count];
						$tsv_string_output .= "$list_chromosome[$z]\t$list_position[$z]\t$list_reference[$z]\t$list_alternate[$z]\t$list_type[$z]\t$list_genotype[$z]\t$list_minorallelefraction[$z]\t$list_depthofcoverage[$z]\t$list_filter[$z]\t$list_homopolymerlength[$z]\t$list_source[$z]\t$list_allele[$z]\t$list_consequence[$z]\t$list_impact[$z]\t$list_symbol[$z]\t$list_gene[$z]\t$list_feature_type[$z]\t$list_feature[$z]\t$list_biotype[$z]\t$list_location[$z]\t$list_exon[$z]\t$list_intron[$z]\t$list_hgvsc[$z]\t$list_hgvsp[$z]\t$list_cdna_position[$z]\t$list_cds_position[$z]\t$list_protein_position[$z]\t$list_amino_acids[$z]\t$list_codons[$z]\t$list_existing_variation[$z]\t$list_distance[$z]\t$list_strand[$z]\t$list_flags[$z]\t$list_symbol_source[$z]\t$list_hgnc_id[$z]\t$list_ensp[$z]\t$list_refseq[$z]\t$list_hgvs_offset[$z]\t$list_gmaf[$z]\t$list_afr_maf[$z]\t$list_amr_maf[$z]\t$list_eas_maf[$z]\t$list_eur_maf[$z]\t$list_sas_maf[$z]\t$list_clin_sig[$z]\t$list_somatic[$z]\t$list_pheno[$z]\t$list_pubmed[$z]\t$final_report_display_clin_sig\n";
						$variant_count++;
					}
					
					//$tsv_string_output .= "$list_chromosome[$z]\t$list_position[$z]\t$list_reference[$z]\t$list_alternate[$z]\t$list_type[$z]\t$list_genotype[$z]\t$list_minorallelefraction[$z]\t$list_depthofcoverage[$z]\t$list_filter[$z]\t$list_homopolymerlength[$z]\t$list_source[$z]\t$list_allele[$z]\t$list_consequence[$z]\t$list_impact[$z]\t$list_symbol[$z]\t$list_gene[$z]\t$list_feature_type[$z]\t$list_feature[$z]\t$list_biotype[$z]\t$list_location[$z]\t$list_exon[$z]\t$list_intron[$z]\t$list_hgvsc[$z]\t$list_hgvsp[$z]\t$list_cdna_position[$z]\t$list_cds_position[$z]\t$list_protein_position[$z]\t$list_amino_acids[$z]\t$list_codons[$z]\t$list_existing_variation[$z]\t$list_distance[$z]\t$list_strand[$z]\t$list_flags[$z]\t$list_symbol_source[$z]\t$list_hgnc_id[$z]\t$list_ensp[$z]\t$list_refseq[$z]\t$list_hgvs_offset[$z]\t$list_gmaf[$z]\t$list_afr_maf[$z]\t$list_amr_maf[$z]\t$list_eas_maf[$z]\t$list_eur_maf[$z]\t$list_sas_maf[$z]\t$list_clin_sig[$z]\t$list_somatic[$z]\t$list_pheno[$z]\t$list_pubmed[$z]\t$final_report_display_clin_sig\n";
				}
				
				// Write to tsv filename
				file_put_contents($output_tsv_clin_sig_filepath_and_name, $tsv_string_output);
			}
			
			exit;
		}
		// *** END OUTPUT PDF ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		// *** OUTPUT TSV FILE ANALYSIS TO BROWSER //////////////////////////////////////////////////////////////////////////////////////////////////
		if ($environment == 'dev') {
			// Variant counters
			echo "<br><br>Total reported: " . $final_num_total_variants . "<br>";
			echo "Pathogenic: " . $final_num_pathogenic_variants . "<br>";
			echo "Likely pathogenic: " . $final_num_likely_pathogenic_variants . "<br>";
			echo "Uncertain: " . $final_num_uncertain_variants . "<br>";
			echo "Likely benign: " . $final_num_likely_benign_variants . "<br>";
			echo "Benign: " . $final_num_benign_variants . "<br>";
			echo "Inconclusive: " . $final_num_inconclusive_variants;
			
			// Show unfiltered data (can be shown/hidden by clicking)
			?>
			
			<br><br>
			<div id="navWrap">
				<div id="nav" style="border:1px solid black; box-shadow: 5px 4px 3px #999;">
					<b>Variants reported in PDF: <?=strip_tags_content(substr($variants_table_combined, 0, strpos($variants_table_combined, '</div>')), '<thead>', TRUE);?></b> 
				</div>
			</div><br>
			
			<b>UNFILTERED TSV FILE</b>: <a onmouseover='this.style.textDecoration="none"' href='#/' onclick='toggler("unfiltered_table");'>[show/hide]</a><br><br>
			<div id='unfiltered_table' style='display:none'>
			<table class="table table-condensed striped compact hover" id="example" border=1>
				<thead>
					<tr class=top_header>
						<th width=25>Num</th>	<!--number of row-->
						<th>Filter</th>	<!--column: filter -->
						<th>Gene</th>	<!--column: symbol -->
						<th>HGVSc</th>	<!--column: hgvsc -->
						<th>HGVSp</th>	<!--column: hgvsp -->
						<th>RefSeq</th>	<!--column: refseq -->
						<th>GRCh37</th>	<!--column: position -->
						<th>Genotype</th>	<!--column: genotype -->
						<th>Ref</th>	<!--column: reference -->
						<th>Alt</th>	<!--column: alternate -->
						<th>Type</th>	<!--column: type -->
						<th>Frequency</th>	<!--column: minorallelefraction -->
						<th>Coverage</th>	<!--column: depthofcoverage -->
						<th>Effect</th>	<!--column: consequence -->
						<th>Location</th>	<!--column: location -->
						<th>Exon</th>	<!--column: exon # -->
						<th>Intron</th>	<!--column: intron # -->
						<th>GMAF</th>	<!--column: GMAF -->
						<th>AFR_MAF</th>	<!--column: AFR GMAF -->
						<th>AMR_MAF</th>	<!--column: AMR GMAF -->
						<th>EAS_MAF</th>	<!--column: EAS GMAF -->
						<th>EUR_MAF</th>	<!--column: EUR GMAF -->
						<th>SAS_MAF</th>	<!--column: SAS GMAF -->
						<th>Orig. clin sig</th>	<!--column: clin_sig -->
						<!--<th>PubMed</th>	    column: pubmed --> 
					</tr>
				</thead>
		
			<?php
			$num = 1; // Counter for list
		
			for ($x = 0; $x < sizeof($list_chromosome); $x++) {
				if ($list_symbol[$x] != '') {
					// Remove transcript designation in front of cds
					$list_hgvsc[$x] = str_replace($hgvsc_replace, "", $list_hgvsc[$x]);
					
					if (strtolower($list_filter[$x]) == 'pass') {
						$filter_color = 'lightv3';
					} else {
						$filter_color = 'white';
					}
					
					echo "<tr style='background: $filter_color'>\n";
						echo "<td width=35 bgcolor='#ffdd99'><b>" . $num . "</b></td>\n";
						echo "<td>" . str_replace("_Filter", "", $list_filter[$x]) . "</td>\n";
						echo "<td>" . $list_symbol[$x] . "</td>\n";
						echo "<td>" . wordwrap($list_hgvsc[$x], 16, "<br>", true) . "</td>\n";
						echo "<td>" . str_replace($hgvsp_replace, "", $list_hgvsp[$x]) . "</td>\n";
						echo "<td>" . $list_refseq[$x] . "</td>\n";
						echo "<td>" . $list_chromosome[$x] . ":" . $list_position[$x] . "</td>\n";
						echo "<td>" . wordwrap($list_genotype[$x], 10, "<br>", true) . "</td>\n";
						echo "<td>" . wordwrap($list_reference[$x], 10, "<br>", true) . "</td>\n";
						echo "<td>" . wordwrap($list_alternate[$x], 10, "<br>", true) . "</td>\n";
						echo "<td>" . strtoupper($list_type[$x]) . "</td>\n";
						echo "<td>" . strtoupper($list_minorallelefraction[$x]) . "</td>\n";
						echo "<td>" . $list_depthofcoverage[$x] . "</td>\n";
						echo "<td>" . str_replace("&", "<br>", str_replace("_variant", "", $list_consequence[$x])) . "</td>\n";
						echo "<td>" . $list_location[$x] . "</td>\n";
						echo "<td>" . $list_exon[$x] . "</td>\n";
						echo "<td>" . $list_intron[$x] . "</td>\n";
						echo "<td>" . $list_gmaf[$x] . "</td>\n";
						echo "<td>" . $list_afr_maf[$x] . "</td>\n";
						echo "<td>" . $list_amr_maf[$x] . "</td>\n";
						echo "<td>" . $list_eas_maf[$x] . "</td>\n";
						echo "<td>" . $list_eur_maf[$x] . "</td>\n";
						echo "<td>" . $list_sas_maf[$x] . "</td>\n";
						
						// Highlight Orig Clin Sig if it is pathogenic or likely pathogenic
						if (stristr($list_clin_sig[$x], 'pathogenic') == TRUE) {
							$orig_clinsig_bgcolor = 'yellow';
						} else {
							$orig_clinsig_bgcolor = '';
						}
						echo "<td style='background: $orig_clinsig_bgcolor'>" . str_replace("&", "<br>", $list_clin_sig[$x]) . "</td>\n";
						//echo "<td>" . str_replace("&", "<br>", $list_pubmed[$x]) . "</td>\n";
					echo "</tr>\n";
				}
				
				$num++;
			}
			
			echo "</table></div>\n";
			if (!$DEV) {
				// Use a mock JSON file for development, otherwise it is provided by the JSON file parameter
			?>
			
			<b>QUALITY METRICS FROM JSON FILE:</b>
			<a onmouseover='this.style.textDecoration="none"' href='#/' onclick='toggler("quality_metrics");'>[show/hide]</a><br><br>
			<div id='quality_metrics' style='display:none'>
			<table class="table table-condensed striped compact hover" border="1">
				<tr><td><b>ontarget_read_count</b></td><td><?=$ontarget_read_count?></td></tr>
				<tr><td><b>fraction_target_covered</b></td><td><?=$fraction_target_covered?></td></tr>
				<tr><td><b>read_counts_per_region list</b></td><td><?=implode(", ", $read_counts_per_region_list)?></td></tr>
				<tr><td><b>uniformity</b></td><td><?=$uniformity?></td></tr>
				<tr><td><b>total_read_count</b></td><td><?=$total_read_count?></td></tr>
				<tr><td><b>read_counts_per_amplicon list</b></td><td><?=implode(", ", $read_counts_per_amplicon)?></td></tr>
				<tr><td><b>fraction_known_sites_covered</b></td><td><?=$fraction_known_sites_covered?></td></tr>
				<tr><td><b>mapped_read_count</b></td><td><?=$mapped_read_count?></td></tr>
				<tr><td><b>average_amplicon_coverage (JSON)</b></td><td><?=$average_amplicon_coverage?></td></tr>
				<tr><td><b>Calculated average amplicon coverage</b></td><td><?=$calculated_average_amplicon_coverage?></td></tr>
			</table>
			</div>
			
			<?php
			}
			
			// Show filtered data
			echo "Below is the <b>filtered</b> and condensed data</b> (filter='PASS') from the TSV file: <br>\n";
			?>
			
				<table border=1 class="table table-condensed table-hover table-striped" id="filtered_table">
					<thead>
						<tr>
							<th class='filtered_headers'>Num.&nbsp;</th>	<!--number of row-->
							<th class='filtered_headers'>Symbol</th>	<!--column: symbol -->
							<!--<th class='filtered_headers'>RefSeq</th>	<!--column: refseq -->
							<th class='filtered_headers'>HGVSc</th>	<!--column: hgvsc -->
							<th class='filtered_headers'>HGVSp</th>	<!--column: hgvsp -->
							<th class='filtered_headers'>Frequency</th>	<!--column: minorallelefraction -->
							<th class='filtered_headers'>GRCh37</th>	<!--column: position -->
							<th class='filtered_headers'>Genotype</th>	<!--column: genotype -->
							<th class='filtered_headers'>Ref</th>	<!--column: reference -->
							<th class='filtered_headers'>Alt</th>	<!--column: alternate -->
							<th class='filtered_headers'>Type</th>	<!--column: type -->
							<th class='filtered_headers'>Variant effect</th>	<!--column: consequence -->
							<th class='filtered_headers'>Location</th>	<!--column: location -->
							<th class='filtered_headers'>Exon</th>	<!--column: exon # -->
							<th class='filtered_headers'>Intron</th>	<!--column: intron # -->
							<th class='filtered_headers'>Coverage</th>	<!--column: depthofcoverage -->
							<th class='filtered_headers'>Orig. clin sig</th>	<!--column: clin_sig -->
						</tr>
					</thead>
					<tbody>
			
			<?php
			for ($x = 0; $x < sizeof($TSV_filtered_list_position); $x++) {
				?>
				
					<tr>
						<td class='filtered_data'><b><a style='color: black; text-decoration: none;' href=#<?=$x+1?>><?=$x+1?><i class='fa fa-chevron-circle-right'></i></a></td>
						<td class='filtered_data'><?=$TSV_filtered_list_genes[$x] ?></td>
						<!--<td class='filtered_data'><?=$TSV_filtered_list_refseq[$x] ?></td>-->
						<td class='filtered_data'><?=wordwrap($TSV_filtered_list_hgvs_c[$x], 25, "<br>", true) ?></td>
						<td class='filtered_data'><?=$TSV_filtered_list_hgvs_p[$x] ?></td>
						<td class='filtered_data'><?=$TSV_filtered_list_freq[$x] ?></td>
						<td class='filtered_data'><?=$TSV_filtered_list_chromosome[$x] . ":" . $TSV_filtered_list_position[$x] ?></td>
						<td class='filtered_data'><?=wordwrap($TSV_filtered_list_genotype[$x], 25, "<br>", true) ?></td>
						<td class='filtered_data'><?=wordwrap($TSV_filtered_list_ref[$x], 25, "<br>", true) ?></td>
						<td class='filtered_data'><?=wordwrap($TSV_filtered_list_alt[$x], 25, "<br>", true) ?></td>
						<td class='filtered_data'><?=$TSV_filtered_list_type[$x] ?></td>
						<td class='filtered_data'><?=$TSV_filtered_list_variant_effect[$x] ?></td>
						<td class='filtered_data'><?=$TSV_filtered_list_location[$x] ?></td>
						<td class='filtered_data'><?=$TSV_filtered_list_exon[$x] ?></td>
						<td class='filtered_data'><?=$TSV_filtered_list_intron[$x] ?></td>
						<td class='filtered_data'><?=$TSV_filtered_list_coverage[$x] ?></td>
						<td class='filtered_data'><?=str_replace("&", "<br>", $TSV_filtered_list_clinvar[$x]) ?></td>
					</tr>
				
				<?php
			}
			?>
			
					</tbody>
				</table><br>
			
			<?php
			function font_awesome_found($db_clin_sig) {
				if ($db_clin_sig != '') {
					return "<i class='fa fa-database' style='color: v3;'></i>";
				} else {
					return "<i class='fa fa-ban' style='color: red;'></i>";
				}
			}
			
			// Display each filtered variant and associated information
			for ($y = 0; $y < sizeof($TSV_filtered_list_genes); $y++) {
				?>
				
				<table border=1 class='table table-condensed table-responsive table-bordered' style='box-shadow: 5px 4px 3px #999;'>
					<tr bgcolor='#ffdd99'>
						<td> 
							<a name=<?=$y+1?>> 
								<h5><b>
									<a style="background-color: #ffdd99; color: #000000;" href="#top"><i class="fa fa-chevron-circle-up"></i></a> 
									<?=$y+1?>) <?=$TSV_filtered_list_genes[$y]?> <?=$TSV_filtered_list_hgvs_c[$y]?>/<?=$TSV_filtered_list_hgvs_p[$y]?>, freq:<?=sprintf("%.2f%%", $TSV_filtered_list_freq[$y] * 100)?>, location:<?=$TSV_filtered_list_location[$y]?>, type:<?=str_replace("_variant", "", $TSV_filtered_list_variant_effect[$y])?>, COSMIC:<?=$TSV_filtered_list_cosmic_id[$y]?>
									
									<?php
										if ($TSV_filtered_list_genes[$y] == 'BRCA1' && $TSV_filtered_list_hgvs_c[$y] != $new_coding_positions[$y]) {
											echo ", ADJUSTED BRCA1 CODING POSITION LOOKUP: " . $new_coding_positions[$y];
										}
									?>
									
								</b></h5>
							</a>
						</td>
					</tr>
					<tr bgcolor=#ffffcc><td style='font-size:14px'>&nbsp; <?=font_awesome_found($clinvar_coord_clin_sigs[$y])?> <b>ClinVar database (1)</b>: <b><u><?=$clinvar_coord_clin_sigs[$y]?></u></b> <?=$clinvar_coord_clin_sig_notes[$y]?></td></tr>
					<tr bgcolor=#ffe066><td style='font-size:14px'>&nbsp; <?=font_awesome_found($clinvar_clin_sigs[$y])?> <b>ClinVar database (2)</b>: <b><u><?=$clinvar_clin_sigs[$y]?></u></b> <?=$clinvar_clin_sig_notes[$y]?></td></tr>
					<tr bgcolor=#ffcce0><td style='font-size:14px'>&nbsp; <?=font_awesome_found($umd_clin_sigs[$y])?> <b>UMD database</b>: <b><u><?=$umd_clin_sigs[$y]?></u></b> <?=$umd_clin_sig_notes[$y]?></td></tr>
					<tr bgcolor=#e6ccff><td style='font-size:14px'>&nbsp; <?=font_awesome_found($brca_exchange_clin_sigs[$y])?> <b>BRCA Exchange database</b>: <b><u><?=$brca_exchange_clin_sigs[$y]?></u></b> <?=$brca_exchange_clin_sig_notes[$y]?></td></tr>
					<tr bgcolor=#c2f0f0><td style='font-size:14px'>&nbsp; <?=font_awesome_found($cosmic_predictions[$y])?> <b>COSMIC FATHMM prediction</b>: <b><u><?=$cosmic_predictions[$y]?></u></b> <?=$cosmic_prediction_notes[$y]?></td></tr>
					<tr bgcolor=#ccff99><td style='font-size:14px'>&nbsp; <?=font_awesome_found($lovd_predictions[$y])?> <b>LOVD prediction</b>: <b><u><?=$lovd_predictions[$y]?></u></b> <?=$lovd_prediction_notes[$y]?></td></tr>
					<tr bgcolor=#ffd6cc><td style='font-size:14px'>&nbsp; <?=font_awesome_found($clinvitae_clin_sigs[$y])?> <b>Clinvitae database</b>: <b><u><?=$clinvitae_clin_sigs[$y]?></u></b> <?=$clinvitae_clin_sig_notes[$y]?></td></tr>
					<tr bgcolor=#99ffcc><td style='font-size:14px'>&nbsp; <?=font_awesome_found($sgi_variants[$y])?> <b>SGI database</b>: <b><u><?=$sgi_clin_sigs[$y]?></u></b> <?=$sgi_clin_sig_notes[$y]?></td></tr>
					<tr height=25 bgcolor=<?=clin_sig_bg_color($final_clin_sigs[$y])?>><td style='font-size:14px; color: #ffffff'>&nbsp; <i class='fa fa-flip-vertical fa-mail-forward'></i> <?=$final_clin_sigs[$y]?> <?=$variant_ignore_reasons[$y]?> <?=$clin_sig_notes[$y]?> <?=$blacklist_notes[$y]?> <?=$sgi_notes[$y]?></td></tr>
				</table>
				
				<?php
			}
			
			echo "<img src='" . $images_folder . "pdf-icon.jpg'> <a style='font-size: 16px; font-weight: bold;' target='_blank' href='$output_browser'>Report PDF Preview</a> (<b>Template: $template_name</b>)\n";
			
			// Play sound when processing is complete
			$myAudioFile = "images/computer_work_beep.mp3";
			echo '<audio id="my_audio" src="' . $myAudioFile . '"></audio>';
			echo '<script language=javascript>$("#my_audio").get(0).play();</script>';
		}
	}
?>
