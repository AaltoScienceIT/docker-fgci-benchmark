# Start from Debian image
FROM debian:latest

# Install requirements for GROMACS benchmark
RUN apt-get update && apt-get install -y \
  openssh-client \
  openmpi-bin \
  libopenmpi-dev \
  fftw3 \
  libopenblas-dev \
  cmake \
  curl \
  build-essential \
  && rm -rf /var/lib/apt/lists/*

# Make install scripts folder
RUN mkdir /tmp/install_scripts

# Compile and install GROMACS
COPY install_scripts/install_gromacs.sh /tmp/install_scripts
RUN bash /tmp/install_scripts/install_gromacs.sh

# Download GROMACS test data
RUN mkdir /benchmarks/gromacs-datas && \
  cd /tmp && \
  curl -OL http://www.prace-ri.eu/UEABS/GROMACS/1.2/GROMACS_TestCaseA.tar.gz && \
  tar xzf GROMACS_TestCaseA.tar.gz && \
  cp ion_channel.tpr /benchmarks/gromacs-datas
  
# Install requirements for R benchmark
RUN apt-get update && apt-get install -y \
  r-base \
  && rm -rf /var/lib/apt/lists/*

# Install packages used for R benchmark
COPY install_scripts/install_rpackages.R /tmp/install_scripts
RUN R CMD BATCH /tmp/install_scripts/install_rpackages.R

# Install requirements for Python benchmark suite
RUN apt-get update && apt-get install -y \
  python3-pip \
  python3-yaml \
  moreutils \
  && rm -rf /var/lib/apt/lists/*

# Install packages for Python benchmark suite
RUN pip3 install -U \
  psutil \
  pytest \
  pygal \
  pygal.js \
  py-cpuinfo \
  pytest-benchmark

# Install CP2K dependencies
RUN apt-get update && apt-get install -y \
  git \
  python \
  && rm -rf /var/lib/apt/lists/*

# Install CP2K
COPY install_scripts/install_cp2k.sh /tmp/install_scripts
RUN bash /tmp/install_scripts/install_cp2k.sh

# Install CP2K dependencies
RUN apt-get update && apt-get install -y \
  environment-modules \
  && rm -rf /var/lib/apt/lists/*

# Download CP2K test data
RUN mkdir /benchmarks/cp2k-datas && \
  cd /benchmarks/cp2k-datas && \
  curl -L -o /tmp/CP2K_TestCaseA.tar.gz http://www.prace-ri.eu/UEABS/CP2K/CP2K_TestCaseA.tar.gz && \
  tar xzf /tmp/CP2K_TestCaseA.tar.gz && \
  rm /tmp/CP2K_TestCaseA.tar.gz

# Install hardinfo for HW information
RUN apt-get update && apt-get install -y \
  hardinfo \
  vim \
  less \
  && rm -rf /var/lib/apt/lists/*

# Copy benchmark scripts
COPY benchmarks/benchmarks.py /benchmarks
COPY benchmarks/R_GFA.R /benchmarks
COPY benchmarks/run_cp2k.sh /benchmarks
RUN chmod +x /benchmarks/run_cp2k.sh

# Set result folder
RUN mkdir /results

# chown /benchmarks and results for a new user with uid 1001
RUN chown 1001:1001 /benchmarks /results

# Create user benchmark with uid 1001 (MPI is risky to run as root)
RUN adduser --home /benchmarks --uid 1001 --shell /bin/bash --disabled-password --gecos '' benchmark

# Set default user and run location
USER benchmark
WORKDIR /benchmarks

RUN ln -s /tmp /benchmarks/.cache

# Copy entrypoint script
COPY ./entry.sh /entry.sh
ENTRYPOINT ["/entry.sh"]
