FROM ubuntu:20.04

ENV julia=julia-1.6.5

ENV julia_full=${julia}-linux-x86_64

RUN apt update && apt install -y git && apt install -y curl

COPY ./${julia_full}.tar.gz ./

RUN mkdir julia && cp /${julia_full}.tar.gz /julia && \
 tar -xvf /julia/${julia_full}.tar.gz -C /julia/ && \
 ln -s /julia/${julia}/bin/julia /usr/local/bin/julia

RUN julia -e 'using Pkg; Pkg.add(url="https://github.com/rbontekoe/Counter.jl"); exit()' 

RUN mkdir /socket

COPY cnt-start.sh /socket/

COPY cnt-server.jl /socket/

WORKDIR /socket

CMD bash /socket/cnt-start.sh

