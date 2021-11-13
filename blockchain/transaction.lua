-- This class will define how we store transactions in the blockchain
Transaction = {}
Transaction.__index = Transaction

-- Imports cryptographic functions
os.loadAPI("lib/crypto")
os.loadAPI("lib/sha256")

function Transaction:create(author, recipient, amount)
    
    local instance = {}
    setmetatable(instance, Transaction)
    
    instance.author = author
    instance.recipient = recipient
    instance.amount = amount
    instance.hash = nil
    instance.signature = nil

    return instance

end

function Transaction:toString()
    return textutils.serialise(self.author).."."..textutils.serialise(self.recipient).."."..self.amount 
end

function Transaction:calculateHash()
    self.hash = sha256.sha256.digest(self:toString())
end

function Transaction:sign(privateKey)
    if not privateKey then
        return false
    end

    self.signature = crypto.crypto.sign(privateKey, self:toString())
end

function Transaction:verifySignature()
    return crypto.crypto.verify(self.author, self:toString(), self.signature)
end

function Transaction:verifyHash()
    return textutils.serialise(sha256.sha256.digest(self:toString())) == textutils.serialise(self.hash)
end

function Transaction:verify()
    local validHash = self:verifyHash()
    local validSignature = self:verifySignature()
    local validAuthor = type(self.author) == "table"
    local validRecipient = type(self.recipient) == "table"
    local validAmount = type(self.amount) == "number"

    return validHash and validSignature and validAuthor and validRecipient and validAmount
end