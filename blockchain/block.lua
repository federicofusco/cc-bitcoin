Block = {}
Block.__index = Block

-- Imports libraries
os.loadAPI("lib/sha256")
os.loadAPI("blockchain/transaction")

function Block:createGenesis()

    local instance = {}
    setmetatable(instance, Block)

    instance.transactions = {}
    instance.limit = 0
    instance.id = 0
    instance.difficulty = 0
    instance.prevHash = ""
    instance.hash = ""
    instance.nonce = 0

    instance:calculateHash()

    return instance

end

function Block:create(difficulty, id, prevHash)

    local instance = {}
    setmetatable(instance, Block)

    instance.transactions = {}
    instance.limit = 3
    instance.id = id
    instance.difficulty = difficulty
    instance.prevHash = prevHash
    instance.hash = ""
    instance.nonce = 0
    instance.miner = {}

    instance:calculateHash()

    return instance

end

function Block:toString()
    return textutils.serialise(self.transactions).."."..self.limit.."."..self.id.."."..self.difficulty.."."..self.prevHash.."."..self.nonce.."."..textutils.serialise(self.miner)
end

function Block:calculateHash()
    self.hash = sha256.sha256.digest(self:toString(), true)
end

function Block:verifyHash()
    return sha256.sha256.digest(self:toString(), true) == self.hash
end

function Block:isFull()
    return table.getn(self.transactions) == self.limit
end

function Block:isMined()
    if self:isFull() then
        return tonumber(string.sub(sha256.sha256.digest(self:toString(), true), 1, self.difficulty)) == 0
    else
        return false
    end
end

function Block:addTransaction(transaction)
    if transaction and transaction:verify() then
        if not self:isFull() then
            self.transactions[table.getn(self.transactions) + 1] = transaction
            self:calculateHash()
        else
            return "Exceeding block limit"
        end
    else
        return "Invalid transaction"
    end
end

function Block:verifyTransactions()
    if table.getn(self.transactions) > 0 then
        for k, v in pairs(self.transactions) do
            if not v:verify() then
                return false 
            end
        end
    else
        return false
    end

    return true
end

function Block:verify()

    local validTransactions = self.transactions and type(self.transactions) == "table" and self:verifyTransactions()
    local validLimit        = self.limit and type(self.limit) == "number"
    local validId           = self.id and type(self.id) == "number"
    local validDifficulty   = self.difficulty and type(self.difficulty) == "number" and self.difficulty > 1
    local validPrevHash     = self.prevHash and type(self.prevHash) == "string"
    local validHash         = self.hash and type(self.hash) == "string" and self:verifyHash()
    local validNonce        = self.nonce and type(self.nonce) == "number"
    
    return validTransactions and validLimit and validId and validDifficulty and validPrevHash and validHash and validNonce

end

function Block:mine(publicKey)

    if not self:verify () then
        return "Invalid block"
    end 

    self.miner = publicKey

    while not self:isMined() do
        self.nonce = self.nonce + 1
        self:calculateHash()
    end

    return true

end