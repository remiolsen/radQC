#!/usr/bin/env python
# -*- coding: utf-8 -*-
""" Searches for fastq files in a folder and groups them by a prefix regex. Combining these files 
info a valid samplesheet, and joining potential samples sequenced over multiple lanes. This script
is specifically tuned for the naming conventions of NGI's sequencing facility. Your mileage may vary.

Usage:
    python samplesheet_gen.py -p <prefix_regex> <in_folder> <out_samplesheet>
Input:
    prefix_regex - Regex to group files by (default: "^P\\d+_\\d+")
    in_folder - Folder containing fastq files
    out_samplesheet - Samplesheet file
Output:
    out_samplesheet - Samplesheet file in csv format with the following columns:
        sample_name, read1, read2
"""
import sys
import os
import argparse
import re
import csv
from itertools import chain

r1_suffixes = ['_R1_', '_1.']
r2_suffixes = ['_R2_', '_2.']


def main(in_folder, prefix_regex, out_samplesheet):
    # Get all fastq files in all subfolders
    fastq_files = os.walk(in_folder)
    fastq_files = [os.path.join(root, f) for root, _, files in fastq_files for f in files if f.endswith('.fastq.gz')]
    # Group files by prefix
    prefix_re = re.compile(prefix_regex)
    prefix_groups = {}
    for f in fastq_files:
        m = prefix_re.search(f)
        if m:
            prefix = m.group(0)
            if prefix not in prefix_groups.keys():
                prefix_groups[prefix] = []
            if any(s in f for s in r1_suffixes) or any(s in f for s in r2_suffixes):
                prefix_groups[prefix].append(f)
    
    print(f'Found {len(list(chain(*prefix_groups.values())))} files for prefix {prefix_regex}', file=sys.stderr)

    # Write samplesheet
    with open(out_samplesheet, 'w') as out_f:
        writer = csv.writer(out_f)
        writer.writerow(['sample', 'fastq_1', 'fastq_2'])
        for prefix, files in prefix_groups.items():
            # Sort files by lane
            files.sort()
            # Group files by read type
            r1_files = [f for f in files if any(s in f for s in r1_suffixes)]
            r2_files = [f for f in files if any(s in f for s in r2_suffixes)]
            # Ensure the same number of R1 and R2 files
            if len(r1_files) != len(r2_files):
                print(f'Warning: Mismatched R1 and R2 files for prefix {prefix}', file=sys.stderr)
                continue
            # Write paired files to samplesheet
            for r1, r2 in zip(r1_files, r2_files):
                writer.writerow([prefix, r1, r2])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prefix_regex','-p' ,default="^P\\d+_\\d+", help='Regex to group files by (default: "P\\d+_\\d+")')
    parser.add_argument('in_folder', help='Folder containing fastq files')
    parser.add_argument('out_samplesheet', help='Samplesheet file')
    args=parser.parse_args()
    main(args.in_folder, args.prefix_regex, args.out_samplesheet)