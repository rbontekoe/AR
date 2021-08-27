using Sockets, Serialization, AppliSales, AppliAR, AppliGeneralLedger

@async begin
    server = listen(IPv4(0), 2001)
    while true
        sock = accept(server)
        @async while isopen(sock)
            data = deserialize(sock)
            client = connect(getaddrinfo("socket-service-gl"), 2001)
            if data isa Vector{AppliSales.Order} && isopen(client)
                entries = AppliAR.process(data; path="/var/lib/postgresql/data/unpaid-invoices.txt")
                serialize(client, entries)
            elseif data isa Vector{BankStatement} && isopen(client)
                unpaid_inv = AppliAR.retrieve_unpaid_invoices(;path="/var/lib/postgresql/data/unpaid-invoices.txt")
                entries = AppliAR.process(unpaid_inv, data; path="/var/lib/postgresql/data/paid-invoices.txt")
                serialize(client, entries)
            end
        end   
    end
end

#Base.JLOptions().isinteractive==0 && wait()

wait(Condition())
