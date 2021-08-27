using Sockets, Serialization, AppliGeneralLedger

@async begin
    server = listen(IPv4(0), 2001)
    while true
        sock = accept(server)
        @async while isopen(sock)
            y = deserialize(sock)
            AppliGeneralLedger.process(y; path_journal="/var/lib/postgresql/data/journal.txt", path_ledger="/var/lib/postgresql/data/generalledger.txt")
        end
    end
end

#Base.JLOptions().isinteractive==0 && wait()

wait(Condition())
