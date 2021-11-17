Blockchain = {}
Blockchain.__index = Blockchain

-- Imports block functions
os.loadAPI("blockchain/block")

function Blockchain:create()

    local instance = {}
    setmetatable(instance, Blockchain)

    instance.blocks = {}
    instance.unconfirmedBlock = {}
    instance.genesisBlock = {}

    return instance
end    