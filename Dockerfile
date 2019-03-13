FROM mcr.microsoft.com/dotnet/core/sdk:2.2 AS builder 

# Install mono 

RUN apt-get update -qq \
    && apt-get install -y git zip unzip dos2unix libunwind8

RUN apt-get update -qq \
    && apt-get install -y libunwind8 dos2unix

RUN apt-get update -qq \
    && apt-get install -y apt-transport-https \
    && apt-key adv --no-tty --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb https://download.mono-project.com/repo/debian stable-stretch main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends mono-devel \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /repo

# Install Cake, and compile the Cake build script
ONBUILD COPY ./build.sh ./build.cake ./nuget.config ./
ONBUILD COPY ./build/constants.cake ./build/constants.cake
ONBUILD COPY ./build/common.cake ./build/common.cake
ONBUILD COPY ./build/version.cake ./build/version.cake
ONBUILD RUN ./build.sh --target=Clean


