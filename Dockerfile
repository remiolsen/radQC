FROM nfcore/base
LABEL authors="remi-andre.olsen@scilifelab.se" \
    description="Docker image containing all requirements for nf-core/radseq pipeline"

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
