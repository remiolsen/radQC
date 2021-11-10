FROM nfcore/base
LABEL authors="remi-andre.olsen@scilifelab.se" \
    description="Docker image containing all requirements for nf-core/radseq pipeline"

#COPY environment.yml /
#RUN conda env create -f ./environment.yml && conda clean -a
RUN conda config --add channels bioconda && conda config --add channels conda-forge && conda config --add channels defaults
RUN conda install --yes fastqc=0.11.7 r-base=3.6.1 r-markdown \
    multiqc=1.10 stacks=2.4 trimmomatic=0.38

