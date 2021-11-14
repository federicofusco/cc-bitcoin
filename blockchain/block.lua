Block = {}
Block.__index = Block

-- Imports SHA256
os.loadAPI("lib/sha256")

function Block:createGenesis()

    local instance = {}
    setmetatable(instance, Block)

    instance.transactions = {}
    instance.limit = 0
    instance.difficulty = 0
    instance.id = 0
    instance.genesis = true
    
    instance:calculateHash()

    return instance

end

function Block:create(limit, difficulty, id)

    local instance = {}
    setmetatable(instance, Block)

    instance.transactions = {}
    instance.limit = limit or 3
    instance.difficulty = difficulty or 8
    instance.id = id

    return instance

end

function Block:toString()
    return self.limit.."."..self.difficulty.."."..self.id.."."..textutils.serialise(transactions)
end

function Block:calculateHash()
    self.hash = sha256.sha256.digest(self:toString())
end

function Block:addTransaction(transaction)
    if transaction:verify() then
        if table.getn(self.transactions) < self.limit then
            self.transactions[table.getn(self.transactions) + 1] = transaction
            self:calculateHash()
        else
            return "Limit exceeded"
        end
    else 
        return "Invalid transaction"
    end
end