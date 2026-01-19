FROM condaforge/mambaforge:24.3.0-0

ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Tokyo

RUN apt-get update && apt-get install -y --no-install-recommends \
    tini git curl ca-certificates vim nano less unzip && \
    rm -rf /var/lib/apt/lists/*
    

RUN mamba install -y -c conda-forge \
    python=3.10 \
    isce2=2.6.4 \
    mintpy=1.6.2 \
    snaphu=0.4.1 \
    gdal=3.10.3 proj \
    numpy=1.26.4 \
    scipy=1.15.2 \
    h5py=3.14.0 \
    cython=3.1.4 \
    pandas=2.3.3 \
    xarray=2025.6.1 \
    dask=2025.9.1 \
    matplotlib=3.10.6 \
    ipykernel=6.30.1 \
    ipywidgets=8.1.7 \
    jupyterlab=4.4.9 \
    geopandas=1.1.1 \
 && mamba clean -afy \
 && pip install --no-cache-dir data_downloader==1.2



ARG USERNAME=gray
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} ${USERNAME} && \
    useradd -m -s /bin/bash -u ${UID} -g ${GID} ${USERNAME}

ARG ISCE2_REF=main
RUN git clone --depth=1 --branch ${ISCE2_REF} https://github.com/isce-framework/isce2.git /opt/isce2 \
 && chown -R ${USERNAME}:${USERNAME} /opt/isce2

USER ${USERNAME}
WORKDIR /work

CMD ["/bin/bash"]