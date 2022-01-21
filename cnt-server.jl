using Sockets, Serialization, Counter

FILE_INVOICE_NBR = "/var/lib/postgresql/data/seqnbr.txt"

@async begin
    server = listen(IPv4(0), 2001)
    while true
        sock = accept(server)
        @async while isopen(sock)
            deserialize(sock)
            invoice_nbr = create_new_invoice_nbr(FILE_INVOICE_NBR)
            serialize(sock, invoice_nbr)
        end
    end
end

#Base.JLOptions().isinteractive==0 && wait()

wait(Condition())
