FROM nfcore/base
MAINTAINER Remi-Andre Olsen <remi-andre.olsen@scilifelab.se>
LABEL authors="remi-andre.olsen@scilifelab.se" \
    description="Docker image containing all requirements for nf-core/radseq pipeline"

COPY environment.yml /
RUN conda env update -n root -f /environment.yml && conda clean -a
