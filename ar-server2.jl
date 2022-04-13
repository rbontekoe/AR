using Sockets, Serialization, AppliSales, AppliAR, AppliGeneralLedger

@async begin
    server = listen(IPv4(0), 2001)
    while true
        sock = accept(server)
        @async while isopen(sock)
            data = deserialize(sock)
            client = connect(getaddrinfo("gl-service"), 2001)
            if data isa Vector{AppliSales.Order} && isopen(client)
                entries = AppliAR.process(data; path="/var/lib/postgresql/data/unpaid-invoices.txt")
                serialize(client, entries)
            elseif data isa Vector{BankStatement} && isopen(client)
                unpaid_inv = AppliAR.retrieve_unpaid_invoices(;path="/var/lib/postgresql/data/unpaid-invoices.txt")
                entries = AppliAR.process(unpaid_inv, data; path="/var/lib/postgresql/data/paid-invoices.txt")
                serialize(client, entries)
            elseif data isa String && data == "status"
                aging_report = AppliAR.aging("/var/lib/postgresql/data/unpaid-invoices.txt", "/var/lib/postgresql/data/paid-invoices.txt")
                serialize(sock, aging_report)
            elseif data isa String && data == "gl-status"
                ledger = AppliGeneralLedger.read_from_file("/var/lib/postgresql/data/generalledger.txt")
                serialize(sock, ledger)
            elseif data isa String && data == "remove"
                rm -f /var/lib/postgresql/data/*
                serialize(sock, "All files are removed")
            end
        end   
    end
end

#Base.JLOptions().isinteractive==0 && wait()

wait(Condition())
