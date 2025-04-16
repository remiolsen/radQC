# remiolsen/radqc

## Introduction

**remiolsen/radqc** is a bioinformatics best-practice analysis pipeline for Pipeline for QC of RAD-seq data.

- [Documentation](#documentation)
- [Quick start](#quick-start)
- [NGI data and usage](#ngi-data-and-usage)
- [Contributions and Support](#contributions-and-support)
- [Citations](#citations)

## Documentation

Please see the more detailed [usage documentation](docs/README.md)

## Quick start

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

To test your nextflow / Docker / Singularity setup on your computer you can run the pipeline using test data:

```
nextflow run remiolsen/radQC -profile <docker,singularity>,test -r master --outdir results
```

When you this test run is successfully completed, or if you elect to skip it you can start your analysis run. First by preparing a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv title="samplesheet.csv"
sample,population,fastq_1,fastq_2
sample101,pop1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Now, you can run the pipeline using:

```bash title="run.sh"
nextflow run remiolsen/radqc \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --enzyme <enzyme> \
   --outdir <OUTDIR> \
   -r <master,v##.##>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## NGI data and usage

This section describes parameter considerations when running this pipeline on data produced by [NGI Sweden](https://ngisweden.scilifelab.se/methods/rad-sequencing/), and additionally when running the pipeline on the Miarka cluster. Quick reference as of 2025-04-15 for running the pipeline:

```bash title="run.sh"
nextflow run /path/to/remiolsen-radqc/ \
--trim_truncate 130 \
--trim_head 5 \
--enzyme ecoRI \
--process_radtags_options='--disable-rad-check' \
--input samplesheet.csv \
--outdir ./results \
--project ngi2016004 \
-profile singularity \
-c /path/to/remiolsen-radqc/configs/conf/uppmax.config
```

For offline use the pipeline is downloaded using nf-core [tools](https://nf-co.re/tools) and including institutional configs specifically for Miarka/UPPMAX, e.g. `nf-core pipelines download -c yes -s singularity <pipeline name>`

* `--trim_truncate 130` This is to trim the reads to a uniform length. Traditionally Stacks only supported uniform lengths, so consider skipping if the libraries have a much longer insert than 300 nt.
* `--enzyme ecoRI` NGI rad-seq data made from digestion fragments of ecoRI
* `--trim_head 5` EcoRI have a cut site / overhang (AATTC) that can lead to low complexity and low quality sequecing in the first 5 cycles. You can check if this the case by running fastQC on the raw data, but this parameter will trim the first 5 nts.
* `--process_radtags_options='--disable-rad-check'` When we are trimming the cut site we need to instruct process_radtags to not check ecoRI sequences
* `-profile singularity` Container system supported on UPPMAX


## Credits

remiolsen/radqc was originally written by Remi-André Olsen.

We thank the following people for their extensive assistance in the development of this pipeline:


## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
