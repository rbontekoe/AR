using Sockets, Serialization, AppliGeneralLedger

@async begin
    server = listen(IPv4(0), 2001)
    while true
        sock = accept(server)
        @async while isopen(sock)
            y = deserialize(sock)
            if (y isa String && y == "gl")
                write(sock, serialize(sock, AppliGeneralLedger.AppliGeneralLedger.read_from_file("/var/lib/postgresql/data/generalledger.txt")))
            else
                AppliGeneralLedger.process(y; path_journal="/var/lib/postgresql/data/journal.txt", path_ledger="/var/lib/postgresql/data/generalledger.txt")
            end
        end
    end
end

#Base.JLOptions().isinteractive==0 && wait()

wait(Condition())
