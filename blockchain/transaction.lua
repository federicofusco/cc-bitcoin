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

    return instance

end

function Transaction:toString()
    return self.author.."."..self.recipient.."."..self.amount
end

function Transaction:calculateHash(returns)
    self.hash = sha256.sha256.digest(self:toString(), true)

    if returns then
        return self.hash
    end
end