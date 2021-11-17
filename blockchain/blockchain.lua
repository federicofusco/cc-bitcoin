Blockchain = {}
Blockchain.__index = Blockchain

-- Imports block functions
os.loadAPI("blockchain/block")

function Blockchain:create()

    local instance = {}
    setmetatable(instance, Blockchain)

    instance.blocks = {}
    instance.unconfirmedBlock = nil
    instance.genesisBlock = nil

    return instance
end    

function Blockchain:initialise()
    self.genesisBlock = block.Block:createGenesis()
    self:createUnconfirmedBlock()
end

function Blockchain:createUnconfirmedBlock()
    local previousBlock = self:getLastBlock()
    self.unconfirmedBlock = block.Block:create( 3, previousBlock.id + 1, previousBlock.hash )
end

function Blockchain:getLastBlock()
    if table.getn(self.blocks) > 0 then
        return self.blocks[table.getn(self.blocks)]
    else
        return self.genesisBlock
    end
end