local byteTableMT = {
    __tostring = function(a) return string.char(unpack(a)) end,
    __index = {
        toHex = function(self) return ("%02x"):rep(#self):format(unpack(self)) end,
        isEqual = function(self, t)
            if type(t) ~= "table" then return false end
            if #self ~= #t then return false end
            local ret = 0
            for i = 1, #self do
                ret = bit32.bor(ret, bit32.bxor(self[i], t[i]))
            end
            return ret == 0
        end
    }
}

-- Imports APIs
os.loadAPI("lib/bigint")
os.loadAPI("lib/ecc")

crypto = (function ()

    --[[
        @desc Generates an ECC keypair based on a given seed
        @param [string, number] seed -- The seed which will be used to generated the keypair
        @returns [table] The private and public keypair
    ]]
    local function generateKeypair(seed) 
        local x

        if seed then
            x = bigint.modq.hashModQ(seed)
        else
            x = bigint.modq.randomModQ()
        end

        local Y = ecc.curve.G * x

        local privateKey = x:encode ()
        local publicKey = Y:encode ()

        return privateKey, publicKey
    end

    --[[
        @desc Signs data based on a given private key
        @param [table] privateKey   -- The key which should be used to generate the signature
        @param [table, string] data -- The data which should be signed
        @returns [table] The signature
    ]]
    local function sign(privateKey, data)

        local data = type(data) == "table" and string.char(unpack(data)) or tostring(data)
        local privateKey = type(privateKey) == "table" and string.char(unpack(privateKey)) or tostring(privateKey)

        local x = bigint.modq.decodeModQ(privateKey)
        local k = bigint.modq.randomModQ()
        local R = ecc.curve.G * k
        local e = bigint.modq.hashModQ(data .. tostring(R))
        local s = k - x * e

        e = e:encode()
        s = s:encode()

        local result = e 
        for i = 1, #s do
            result[#result + 1] = s[i]
        end

        return setmetatable(result, byteTableMT)
    end

    --[[
        @desc Verifies a signature's validity
        @param [table] publicKey    -- The public key associated with the private key that generates the signature
        @param [table, string] data -- The data which was signed
        @param [table] signature    -- The signature
        @returns [boolean] Whether or not the signature is valid
    ]]
    local function verify(publicKey, data, signature)

        local data = type(data) == "table" and string.char(unpack(data)) or tostring(data)

        local Y = ecc.curve.pointDecode(publicKey)
        local e = bigint.modq.decodeModQ({unpack(signature, 1, #signature / 2)})
        local s = bigint.modq.decodeModQ({unpack(signature, #signature / 2 + 1)})
        local Rv = ecc.curve.G * s + Y * e
        local ev = bigint.modq.hashModQ(data .. tostring(Rv))

        return ev == e
    end

    return {
        generateKeypair = generateKeypair,
        sign = sign,
        verify = verify
    }

end)()