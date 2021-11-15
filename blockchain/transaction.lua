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
    instance.hash = ""
    instance.signature = {}

    instance:calculateHash()

    return instance

end

function Transaction:toString()
    return textutils.serialise(self.author).."."..textutils.serialise(self.recipient).."."..self.amount 
end

function Transaction:calculateHash()
    self.hash = sha256.sha256.digest(self:toString(), true)
end

function Transaction:sign(privateKey)
    self.signature = crypto.crypto.sign(privateKey, self:toString())
end

function Transaction:verifySignature()
    return crypto.crypto.verify(self.author, self:toString(), self.signature)
end

function Transaction:verifyHash()
    return sha256.sha256.digest(self:toString(), true) == self.hash
end

function Transaction:verify()
    local validHash      = self.hash and self:verifyHash()
    local validSignature = self.signature and self:verifySignature()
    local validAuthor    = self.author and type(self.author) == "table" and textutils.serialise(self.author) ~= textutils.serialise(self.recipient)
    local validRecipient = self.recipient and type(self.recipient) == "table"
    local validAmount    = self.amount and type(self.amount) == "number" and self.amount > 0

    return validHash and validSignature and validAuthor and validRecipient and validAmount
end