FROM centos:7.7.1908

# Intel Acceleration Stack for Development for Intel Programmable Acceleration Card with Intel Arria 10 GX FPGA
RUN yum install -y curl epel-release sudo && \
    mkdir -p /installer && \
    curl -L http://download.altera.com/akdlm/software/ias/1.2.1/a10_gx_pac_ias_1_2_1_pv_dev.tar.gz | tar xz -C /installer --strip-components=1 && \
    sed -i 's/install_opae=1/install_opae=0/g' /installer/setup.sh && \
    sed -i 's/install_pacsign=1/install_pacsign=0/g' /installer/setup.sh && \
    /installer/setup.sh --installdir /opt --yes && \
    rm -rf /installer && \
    yum install -y libpng12 freetype fontconfig libX11 libSM libXrender 

ENV OPAE_PLATFORM_ROOT /opt/inteldevstack/a10_gx_pac_ias_1_2_1_pv/
ENV QUARTUS_HOME /opt/intelFPGA_pro/quartus_19.2.0b57/quartus/
ENV PATH "${QUARTUS_HOME}/bin:${PATH}"

# Modelsim
RUN mkdir -p /installer && \
    cd /installer && \
    curl -L -O http://download.altera.com/akdlm/software/acdsinst/19.2/57/ib_installers/ModelSimProSetup-19.2.0.57-linux.run && \
    curl -L -O http://download.altera.com/akdlm/software/acdsinst/19.2/57/ib_installers/modelsim-part2-19.2.0.57-linux.qdz && \
    chmod +x ModelSimProSetup-19.2.0.57-linux.run && \
    ./ModelSimProSetup-19.2.0.57-linux.run --mode unattended --installdir /opt/intelFPGA_pro/quartus_19.2.0b57/ --accept_eula 1 && \
    rm -rf /installer && \
    yum install -y glibc-devel.i686 libX11.i686 libXext.i686 libXft.i686 libgcc.i686 && \
    sed -ci 's/linux_rh60/linux/g' /opt/intelFPGA_pro/quartus_19.2.0b57/modelsim_ase/bin/vsim

ENV MTI_HOME /opt/intelFPGA_pro/quartus_19.2.0b57/modelsim_ase
ENV QUESTA_HOME "${MTI_HOME}"
ENV PATH "${MTI_HOME}/bin:${PATH}"

# Open Programmable Acceleration Engine
RUN mkdir -p /opae-sdk/build && \
    yum install -y git cmake3 make gcc gcc-c++ json-c-devel libuuid-devel hwloc-devel python-devel glibc-devel && \
    curl -L https://github.com/OPAE/opae-sdk/archive/release/2.0.0.tar.gz | tar xz -C /opae-sdk --strip-components=1 && \
    cd /opae-sdk/build && \
    cmake3 -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_ASE=On -DOPAE_BUILD_SIM=On -DOPAE_SIM_TAG=release/2.0.0 \
    -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j && \
    make install && \
    rm -rf /opae-sdk/build

# Intel FPGA Basic Building Blocks
RUN mkdir -p /intel-fpga-bbb/build && \
    curl -L https://github.com/OPAE/intel-fpga-bbb/archive/1bace5f39573e03d1f510c258c574a51b1c7ab6d.tar.gz | tar xz -C /intel-fpga-bbb --strip-components=1 && \
    cd /intel-fpga-bbb/build && \
    cmake3 -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j && \
    make install

ENV FPGA_BBB_CCI_SRC /intel-fpga-bbb

# Intel TBB
RUN curl -L https://github.com/oneapi-src/oneTBB/releases/download/v2020.3/tbb-2020.3-lin.tgz | tar xz -C /usr --strip-components=1

# Fletcher runtime
RUN mkdir -p /fletcher && \
    yum install -y https://apache.bintray.com/arrow/centos/$(cut -d: -f5 /etc/system-release-cpe)/apache-arrow-release-latest.rpm && \
    yum install -y arrow-devel && \
    curl -L https://github.com/abs-tudelft/fletcher/archive/0.0.11.tar.gz | tar xz -C /fletcher --strip-components=1 && \
    cd /fletcher && \
    cmake3 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr . && \
    make -j && \
    make install && \
    rm -rf /fletcher

# Fletcher plaform support for OPAE
RUN mkdir -p /fletcher-opae && \
    curl -L https://github.com/abs-tudelft/fletcher-opae/archive/master.tar.gz | tar xz -C /fletcher-opae --strip-components=1 && \
    cd /fletcher-opae && \
    cmake3 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr . && \
    make -j && \
    make install && \
    rm -rf /fletcher-opae

# Update the Platform Interface Manager
RUN mkdir -p /ofs-platform-afu-bbb && \
    curl -L https://github.com/OPAE/ofs-platform-afu-bbb/archive/c6b76f6623d21ac6ef7205be98d0251f146e5e55.tar.gz | tar xz -C /ofs-platform-afu-bbb --strip-components=1 && \
    cd /ofs-platform-afu-bbb/ && \
    sed -i 's/afu_fit/afu_default/g' plat_if_release/templates/ofs_plat_if_compat/a10_gx_pac_ias/install.sh && \
    ./plat_if_release/update_release.sh $OPAE_PLATFORM_ROOT

# Fletcher hardware libs
RUN git clone --recursive --single-branch -b 0.0.11 https://github.com/abs-tudelft/fletcher /fletcher
ENV FLETCHER_HARDWARE_DIR=/fletcher/hardware

WORKDIR /src
