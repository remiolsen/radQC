FROM nfcore/base
LABEL authors="remi-andre.olsen@scilifelab.se" \
    description="Docker image containing all requirements for radseqQC pipeline"

COPY environment.yml /
RUN conda config --add channels bioconda && conda config --add channels conda-forge
RUN conda env create -f ./environment.yml && conda clean -a


