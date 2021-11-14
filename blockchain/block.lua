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

    -- Converts transactions to string
    local transactions = ""
    for i = 0, table.getn(self.transactions) do
        if self.transactions[i] then
            transactions = transactions..self.transactions[i]:toString()
        end
    end

    return self.limit.."."..self.difficulty.."."..self.id.."."..transactions
end