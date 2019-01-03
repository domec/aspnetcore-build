FROM microsoft/dotnet:2.2-sdk AS builder 

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

WORKDIR /src

# Install Cake, and compile the Cake build script
ONBUILD COPY ./build.sh ./build.cake ./nuget.config ./
ONBUILD COPY ./build/constants.cake ./build/constants.cake
ONBUILD COPY ./build/common.cake ./build/common.cake
ONBUILD COPY ./build/version.cake ./build/version.cake
ONBUILD RUN ./build.sh --target=Clean

# Copy source projects and restore as distinct layers
ONBUILD COPY ./*.sln ./*.props ./*.targets ./
ONBUILD COPY src/*/*.csproj ./
ONBUILD RUN for file in $(ls *.csproj); do mkdir -p src/${file%.*}/ && mv $file src/${file%.*}/; done
ONBUILD COPY tests/*/*.csproj ./
ONBUILD RUN for file in $(ls *.csproj); do mkdir -p tests/${file%.*}/ && mv $file tests/${file%.*}/; done
#COPY src/sts.domec.tools.host/sts.domec.tools.host.csproj src/sts.domec.tools.host/sts.domec.tools.host.csproj
#COPY src/domain/sts.domec.tools.domain/sts.domec.tools.domain.csproj src/domain/sts.domec.tools.domain/sts.domec.tools.domain.csproj
#COPY src/domain/sts.domec.tools.domain.nh/sts.domec.tools.domain.nh.csproj src/domain/sts.domec.tools.domain.nh/sts.domec.tools.domain.nh.csproj
#COPY src/config/sts.domec.tools.config/sts.domec.tools.config.csproj src/config/sts.domec.tools.config/sts.domec.tools.config.csproj
#COPY src/storage/sts.domec.tools.storage/sts.domec.tools.storage.csproj src/storage/sts.domec.tools.storage/sts.domec.tools.storage.csproj
ONBUILD RUN ./build.sh --target=Restore

# Copy all remaining sources
ONBUILD COPY . .

# This defines the `ARG` inside the build-stage (it will be executed after `FROM` 
# in the child image, so it's a new build-stage). Don't set a default value so that 
# the value is set to what's currently set for `BUILD_VERSION` 
ONBUILD ARG BUILD_VERSION

# If BUILD_VERSION is set/non-empty, use it, otherwise use a default value 
ONBUILD ARG VERSION=${BUILD_VERSION:-1.0.0}

# Build
ONBUILD RUN ./build.sh --target=Build

# Test
ONBUILD RUN ./build.sh --target=Test

