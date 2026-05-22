FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        bzip2 \
        ca-certificates \
        curl \
        docker-cli \
        docker.io \
        git \
        procps \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o /tmp/miniforge.sh \
    && bash /tmp/miniforge.sh -b -p /opt/conda \
    && rm /tmp/miniforge.sh \
    && /opt/conda/bin/conda install -y python=3.10 pip \
    && /opt/conda/bin/conda clean -afy \
    && ln -sf /opt/conda/bin/python /usr/local/bin/python3.10 \
    && ln -sf /opt/conda/bin/pip /usr/local/bin/pip3.10

ENV PATH="/opt/conda/bin:${PATH}"

USER jenkins
