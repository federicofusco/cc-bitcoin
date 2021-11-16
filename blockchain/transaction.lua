Transaction = {}
Transaction.__index = Transaction

-- Imports cryptographic functions
os.loadAPI("lib/crypto")
os.loadAPI("lib/sha256")

--[[
    @desc Creates a new transaction
    @param [table] author    -- A public key representing the sender of the transaction
    @param [table] recipient -- A public key representing the recipient of the transactions
    @param [number] amount   -- The transaction amount (which will be recieved by the recipient)
    @return [table] The transaction
]]
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

--[[
    @desc Converts the transaction to a string
    @returns [string] The stringified transaction
]]
function Transaction:toString()
    return textutils.serialise(self.author).."."..textutils.serialise(self.recipient).."."..self.amount 
end

--[[
    @desk Calculates the block's hash
]]
function Transaction:calculateHash()
    self.hash = sha256.sha256.digest(self:toString(), true)
end

--[[
    @desc Verifies the transaction's hash
    @returns [boolean] Whether or not the hash is valid
]]
function Transaction:verifyHash()
    return sha256.sha256.digest(self:toString(), true) == self.hash
end

--[[
    @desc Signs the transaction using the private key associated with the author
    @param [table] privateKey -- The private key associated with the author
]]
function Transaction:sign(privateKey)
    self.signature = crypto.crypto.sign(privateKey, self:toString())
end

--[[
    @desc Verifies the signature is valid and has been signed with the author's private key
    @returns [boolean] Whether or not the signature is valid
]]
function Transaction:verifySignature()
    return crypto.crypto.verify(self.author, self:toString(), self.signature)
end

--[[
    @desc Verifies is the transaction is valid
    @returns [boolean] Whether or not the transaction is valid
]]
function Transaction:verify()
    local validHash      = self.hash and self:verifyHash()
    local validSignature = self.signature and self:verifySignature()
    local validAuthor    = self.author and type(self.author) == "table" and textutils.serialise(self.author) ~= textutils.serialise(self.recipient)
    local validRecipient = self.recipient and type(self.recipient) == "table"
    local validAmount    = self.amount and type(self.amount) == "number" and self.amount > 0

    return validHash and validSignature and validAuthor and validRecipient and validAmount
end