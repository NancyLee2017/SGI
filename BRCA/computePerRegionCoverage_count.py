#!/home/athurvagore/anaconda/envs/pipeline/bin/python
from __future__ import division
import argparse
import collections
import simplejson
import numpy as np
import fnmatch
import os


def compute_amplicon_distribution(json_filenames):
    amplicon_data = collections.OrderedDict()
    sum_data = collections.OrderedDict()
    quality_data = collections.OrderedDict()
    amplicon_ids = set()
    for json_filename in json_filenames:
        try:
            json_data = simplejson.loads(open(json_filename).read())
        except:
            print json_filename
            raise
        quality_data[json_filename] = json_data['total_read_count'], json_data['mapped_read_count'], json_data['ontarget_read_count'], json_data['uniformity'], json_data['average_amplicon_coverage'],json_data['fraction_target_covered'], json_data['fraction_known_sites_covered']
        amplicon_data[json_filename] = {}
        sum_data[json_filename] = 0

        for amplicon_id, amplicon_counts in json_data['read_counts_per_amplicon'].items():
            amplicon_data[json_filename][amplicon_id] = amplicon_counts
            sum_data[json_filename] += amplicon_counts
            amplicon_ids.add(amplicon_id)

    norm_read_fraction = collections.OrderedDict()
    for amplicon_id in amplicon_ids:
        norm_read_fraction[amplicon_id] = collections.OrderedDict()
        for json_filename in json_filenames:
            try:
                norm_read_fraction[amplicon_id][json_filename] = amplicon_data[json_filename][amplicon_id]
            except ZeroDivisionError:
                norm_read_fraction[amplicon_id][json_filename] = 0.0

    print "Quality Score\t%s" % "\t".join(str(x) for x in norm_read_fraction[amplicon_id].keys())
    print "Total Read Count\t%s" % "\t".join(str(quality_data[x][0]) for x in norm_read_fraction[amplicon_id].keys())
    print "Mapped Read Count\t%s" % "\t".join(str(quality_data[x][1]) for x in norm_read_fraction[amplicon_id].keys())
    print "Ontarget Read Count\t%s" % "\t".join(str(quality_data[x][2]) for x in norm_read_fraction[amplicon_id].keys())
    print "Uniformity\t%s" % "\t".join(str(quality_data[x][3]) for x in norm_read_fraction[amplicon_id].keys())
    print "Average Coverage\t%s" % "\t".join(str(quality_data[x][4]) for x in norm_read_fraction[amplicon_id].keys())
    print "Fraction target covered\t%s" % "\t".join(str(quality_data[x][5]) for x in norm_read_fraction[amplicon_id].keys())
    print "Fraction known sites covered\t%s" % "\t".join(str(quality_data[x][6]) for x in norm_read_fraction[amplicon_id].keys())
    print
    print "Amplicon_ID\t%s" % "\t".join(str(x) for x in norm_read_fraction[amplicon_id].keys())
    for amplicon_id in amplicon_ids:
        print "%s\t%s" % (amplicon_id, "\t".join(str(x) for x in norm_read_fraction[amplicon_id].values()))
    return


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--json-dir', dest="json_dir", action='store', help='Path to output folder')
    options = parser.parse_args()

    matches = []
    for root, dirnames, filenames in os.walk(options.json_dir):
        for filename in fnmatch.filter(filenames, '*.json'):
            matches.append(os.path.join(root, filename))

    compute_amplicon_distribution(matches)
