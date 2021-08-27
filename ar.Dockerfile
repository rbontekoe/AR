FROM ubuntu:20.04

ENV julia=julia-1.6.0

ENV julia_full=${julia}-linux-x86_64

RUN apt update && apt install -y git && apt install -y curl

COPY ./${julia_full}.tar.gz ./

RUN mkdir julia && cp /${julia_full}.tar.gz /julia && \
 tar -xvf /julia/${julia_full}.tar.gz -C /julia/ && \
 ln -s /julia/${julia}/bin/julia /usr/local/bin/julia

RUN julia -e 'using Pkg; Pkg.add("AppliSales"); exit()'

RUN julia -e 'using Pkg; Pkg.add(url="https://github.com/rbontekoe/AppliAR.jl"); exit()' 

RUN julia -e 'using Pkg; Pkg.add("AppliGeneralLedger"); exit()'

RUN mkdir /socket


COPY ar-start.sh /socket/

COPY ar-server.jl /socket/

WORKDIR /socket

CMD bash /socket/ar-start.sh

