From:nfcore/base
Bootstrap:docker

%labels
    MAINTAINER Remi-Andre Olsen <remi-andre.olsen@scilifelab.se>
    DESCRIPTION Singularity image containing all requirements for nf-core/radseq pipeline
    VERSION 0.1.0

%files
    environment.yml /

%post
    /opt/conda/bin/conda env update -n root -f /environment.yml
    /opt/conda/bin/conda clean -a
