FROM condaforge/mambaforge:24.3.0-0

ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Tokyo

RUN apt-get update && apt-get install -y --no-install-recommends \
    tini git curl ca-certificates vim less && \
    rm -rf /var/lib/apt/lists/*


RUN mamba install -y -c conda-forge \
    python=3.10 \
    isce2 \
    mintpy \
    snaphu \
    gdal proj \
    numpy scipy h5py cython pandas xarray dask \
    matplotlib ipykernel ipywidgets jupyterlab \
    geopandas \
 && mamba clean -afy \
 && pip install --no-cache-dir data_downloader



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