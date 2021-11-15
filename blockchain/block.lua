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

    instance:calculateHash()

    return instance

end

function Block:toString()
    return textutils.serialise(self.transactions).."."..self.limit.."."..self.id.."."..self.difficulty.."."..self.prevHash.."."..self.nonce
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
        return tonumber(string.sub(sha256.sha256.digest(self:toString()), 1, self.difficulty)) == 0
    else
        return false
    end
end

function Block:addTransaction(transaction)
    if transaction and transaction:verify() then
        if not self:isFull() then
            self.transactions[table.getn(self.transactions) + 1] = transaction
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
end

function Block:verify(checkIfMined)

    local validTransactions = self.transactions and type(self.transactions) == "table" and self:verifyTransactions()
    local validLimit        = self.limit and type(self.limit) == "number" > 1
    local validId           = self.id and type(self.id) == "number"
    local validDifficulty   = self.difficulty and type(self.difficulty) == "number" and self.difficulty > 1
    local validPrevHash     = self.prevHash and type(self.prevHash) == "string"
    local validHash         = self.hash and type(self.hash) == "string" and self:verifyHash()
    local validNonce        = self.nonce and type(self.nonce) == "number"
    
    local valid = validTransactions and validLimit and validId and validDifficulty and validPrevHash and validHash and validNonce

    if checkIfMined then
        return valid and self:isMined()
    else
        return valid
    end

end