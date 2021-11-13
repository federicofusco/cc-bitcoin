-- Imports random byte generator
os.loadAPI("lib/random")
os.loadAPI("lib/sha256")

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

-- Big integer arithmetic for 168-bit (and 336-bit) numbers
-- Numbers are represented as little-endian tables of 24-bit integers
arith = (function()
    local function isEqual(a, b)
        return (
            a[1] == b[1]
            and a[2] == b[2]
            and a[3] == b[3]
            and a[4] == b[4]
            and a[5] == b[5]
            and a[6] == b[6]
            and a[7] == b[7]
        )
    end

    local function compare(a, b)
        for i = 7, 1, -1 do
            if a[i] > b[i] then
                return 1
            elseif a[i] < b[i] then
                return -1
            end
        end

        return 0
    end

    local function add(a, b)
        -- c7 may be greater than 2^24 before reduction
        local c1 = a[1] + b[1]
        local c2 = a[2] + b[2]
        local c3 = a[3] + b[3]
        local c4 = a[4] + b[4]
        local c5 = a[5] + b[5]
        local c6 = a[6] + b[6]
        local c7 = a[7] + b[7]

        if c1 > 0xffffff then
            c2 = c2 + 1
            c1 = c1 - 0x1000000
        end
        if c2 > 0xffffff then
            c3 = c3 + 1
            c2 = c2 - 0x1000000
        end
        if c3 > 0xffffff then
            c4 = c4 + 1
            c3 = c3 - 0x1000000
        end
        if c4 > 0xffffff then
            c5 = c5 + 1
            c4 = c4 - 0x1000000
        end
        if c5 > 0xffffff then
            c6 = c6 + 1
            c5 = c5 - 0x1000000
        end
        if c6 > 0xffffff then
            c7 = c7 + 1
            c6 = c6 - 0x1000000
        end
        
        return {c1, c2, c3, c4, c5, c6, c7}
    end

    local function sub(a, b)
        -- c7 may be negative before reduction
        local c1 = a[1] - b[1]
        local c2 = a[2] - b[2]
        local c3 = a[3] - b[3]
        local c4 = a[4] - b[4]
        local c5 = a[5] - b[5]
        local c6 = a[6] - b[6]
        local c7 = a[7] - b[7]

        if c1 < 0 then
            c2 = c2 - 1
            c1 = c1 + 0x1000000
        end
        if c2 < 0 then
            c3 = c3 - 1
            c2 = c2 + 0x1000000
        end
        if c3 < 0 then
            c4 = c4 - 1
            c3 = c3 + 0x1000000
        end
        if c4 < 0 then
            c5 = c5 - 1
            c4 = c4 + 0x1000000
        end
        if c5 < 0 then
            c6 = c6 - 1
            c5 = c5 + 0x1000000
        end
        if c6 < 0 then
            c7 = c7 - 1
            c6 = c6 + 0x1000000
        end
        
        return {c1, c2, c3, c4, c5, c6, c7}
    end

    local function rShift(a)
        local c1 = a[1]
        local c2 = a[2]
        local c3 = a[3]
        local c4 = a[4]
        local c5 = a[5]
        local c6 = a[6]
        local c7 = a[7]

        c1 = c1 / 2
        c1 = c1 - c1 % 1
        c1 = c1 + (c2 % 2) * 0x800000
        c2 = c2 / 2
        c2 = c2 - c2 % 1
        c2 = c2 + (c3 % 2) * 0x800000
        c3 = c3 / 2
        c3 = c3 - c3 % 1
        c3 = c3 + (c4 % 2) * 0x800000
        c4 = c4 / 2
        c4 = c4 - c4 % 1
        c4 = c4 + (c5 % 2) * 0x800000
        c5 = c5 / 2
        c5 = c5 - c5 % 1
        c5 = c5 + (c6 % 2) * 0x800000
        c6 = c6 / 2
        c6 = c6 - c6 % 1
        c6 = c6 + (c7 % 2) * 0x800000
        c7 = c7 / 2
        c7 = c7 - c7 % 1

        return {c1, c2, c3, c4, c5, c6, c7}
    end

    local function addDouble(a, b)
        -- a and b are 336-bit integers (14 words)
        local c1 = a[1] + b[1]
        local c2 = a[2] + b[2]
        local c3 = a[3] + b[3]
        local c4 = a[4] + b[4]
        local c5 = a[5] + b[5]
        local c6 = a[6] + b[6]
        local c7 = a[7] + b[7]
        local c8 = a[8] + b[8]
        local c9 = a[9] + b[9]
        local c10 = a[10] + b[10]
        local c11 = a[11] + b[11]
        local c12 = a[12] + b[12]
        local c13 = a[13] + b[13]
        local c14 = a[14] + b[14]

        if c1 > 0xffffff then
            c2 = c2 + 1
            c1 = c1 - 0x1000000
        end
        if c2 > 0xffffff then
            c3 = c3 + 1
            c2 = c2 - 0x1000000
        end
        if c3 > 0xffffff then
            c4 = c4 + 1
            c3 = c3 - 0x1000000
        end
        if c4 > 0xffffff then
            c5 = c5 + 1
            c4 = c4 - 0x1000000
        end
        if c5 > 0xffffff then
            c6 = c6 + 1
            c5 = c5 - 0x1000000
        end
        if c6 > 0xffffff then
            c7 = c7 + 1
            c6 = c6 - 0x1000000
        end
        if c7 > 0xffffff then
            c8 = c8 + 1
            c7 = c7 - 0x1000000
        end
        if c8 > 0xffffff then
            c9 = c9 + 1
            c8 = c8 - 0x1000000
        end
        if c9 > 0xffffff then
            c10 = c10 + 1
            c9 = c9 - 0x1000000
        end
        if c10 > 0xffffff then
            c11 = c11 + 1
            c10 = c10 - 0x1000000
        end
        if c11 > 0xffffff then
            c12 = c12 + 1
            c11 = c11 - 0x1000000
        end
        if c12 > 0xffffff then
            c13 = c13 + 1
            c12 = c12 - 0x1000000
        end
        if c13 > 0xffffff then
            c14 = c14 + 1
            c13 = c13 - 0x1000000
        end

        return {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14}
    end

    local function mult(a, b, half_multiply)
        local a1, a2, a3, a4, a5, a6, a7 = unpack(a)
        local b1, b2, b3, b4, b5, b6, b7 = unpack(b)
        
        local c1 = a1 * b1
        local c2 = a1 * b2 + a2 * b1
        local c3 = a1 * b3 + a2 * b2 + a3 * b1
        local c4 = a1 * b4 + a2 * b3 + a3 * b2 + a4 * b1
        local c5 = a1 * b5 + a2 * b4 + a3 * b3 + a4 * b2 + a5 * b1
        local c6 = a1 * b6 + a2 * b5 + a3 * b4 + a4 * b3 + a5 * b2 + a6 * b1
        local c7 = a1 * b7 + a2 * b6 + a3 * b5 + a4 * b4 + a5 * b3 + a6 * b2
                   + a7 * b1
        local c8, c9, c10, c11, c12, c13, c14
        if not half_multiply then
            c8 = a2 * b7 + a3 * b6 + a4 * b5 + a5 * b4 + a6 * b3 + a7 * b2
            c9 = a3 * b7 + a4 * b6 + a5 * b5 + a6 * b4 + a7 * b3
            c10 = a4 * b7 + a5 * b6 + a6 * b5 + a7 * b4
            c11 = a5 * b7 + a6 * b6 + a7 * b5
            c12 = a6 * b7 + a7 * b6
            c13 = a7 * b7
            c14 = 0
        else
            c8 = 0
        end

        local temp
        temp = c1
        c1 = c1 % 0x1000000
        c2 = c2 + (temp - c1) / 0x1000000
        temp = c2
        c2 = c2 % 0x1000000
        c3 = c3 + (temp - c2) / 0x1000000
        temp = c3
        c3 = c3 % 0x1000000
        c4 = c4 + (temp - c3) / 0x1000000
        temp = c4
        c4 = c4 % 0x1000000
        c5 = c5 + (temp - c4) / 0x1000000
        temp = c5
        c5 = c5 % 0x1000000
        c6 = c6 + (temp - c5) / 0x1000000
        temp = c6
        c6 = c6 % 0x1000000
        c7 = c7 + (temp - c6) / 0x1000000
        temp = c7
        c7 = c7 % 0x1000000
        if not half_multiply then
            c8 = c8 + (temp - c7) / 0x1000000
            temp = c8
            c8 = c8 % 0x1000000
            c9 = c9 + (temp - c8) / 0x1000000
            temp = c9
            c9 = c9 % 0x1000000
            c10 = c10 + (temp - c9) / 0x1000000
            temp = c10
            c10 = c10 % 0x1000000
            c11 = c11 + (temp - c10) / 0x1000000
            temp = c11
            c11 = c11 % 0x1000000
            c12 = c12 + (temp - c11) / 0x1000000
            temp = c12
            c12 = c12 % 0x1000000
            c13 = c13 + (temp - c12) / 0x1000000
            temp = c13
            c13 = c13 % 0x1000000
            c14 = c14 + (temp - c13) / 0x1000000
        end

        return {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14}
    end

    local function square(a)
        -- returns a 336-bit integer (14 words)
        local a1, a2, a3, a4, a5, a6, a7 = unpack(a)
        
        local c1 = a1 * a1
        local c2 = a1 * a2 * 2
        local c3 = a1 * a3 * 2 + a2 * a2
        local c4 = a1 * a4 * 2 + a2 * a3 * 2
        local c5 = a1 * a5 * 2 + a2 * a4 * 2 + a3 * a3
        local c6 = a1 * a6 * 2 + a2 * a5 * 2 + a3 * a4 * 2
        local c7 = a1 * a7 * 2 + a2 * a6 * 2 + a3 * a5 * 2 + a4 * a4
        local c8 = a2 * a7 * 2 + a3 * a6 * 2 + a4 * a5 * 2
        local c9 = a3 * a7 * 2 + a4 * a6 * 2 + a5 * a5
        local c10 = a4 * a7 * 2 + a5 * a6 * 2
        local c11 = a5 * a7 * 2 + a6 * a6
        local c12 = a6 * a7 * 2
        local c13 = a7 * a7
        local c14 = 0

        local temp
        temp = c1
        c1 = c1 % 0x1000000
        c2 = c2 + (temp - c1) / 0x1000000
        temp = c2
        c2 = c2 % 0x1000000
        c3 = c3 + (temp - c2) / 0x1000000
        temp = c3
        c3 = c3 % 0x1000000
        c4 = c4 + (temp - c3) / 0x1000000
        temp = c4
        c4 = c4 % 0x1000000
        c5 = c5 + (temp - c4) / 0x1000000
        temp = c5
        c5 = c5 % 0x1000000
        c6 = c6 + (temp - c5) / 0x1000000
        temp = c6
        c6 = c6 % 0x1000000
        c7 = c7 + (temp - c6) / 0x1000000
        temp = c7
        c7 = c7 % 0x1000000
        c8 = c8 + (temp - c7) / 0x1000000
        temp = c8
        c8 = c8 % 0x1000000
        c9 = c9 + (temp - c8) / 0x1000000
        temp = c9
        c9 = c9 % 0x1000000
        c10 = c10 + (temp - c9) / 0x1000000
        temp = c10
        c10 = c10 % 0x1000000
        c11 = c11 + (temp - c10) / 0x1000000
        temp = c11
        c11 = c11 % 0x1000000
        c12 = c12 + (temp - c11) / 0x1000000
        temp = c12
        c12 = c12 % 0x1000000
        c13 = c13 + (temp - c12) / 0x1000000
        temp = c13
        c13 = c13 % 0x1000000
        c14 = c14 + (temp - c13) / 0x1000000

        return {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14}
    end

    local function encodeInt(a)
        local enc = {}

        for i = 1, 7 do
            local word = a[i]
            for j = 1, 3 do
                enc[#enc + 1] = word % 256
                word = math.floor(word / 256)
            end
        end

        return enc
    end

    local function decodeInt(enc)
        local a = {}
        local encCopy = {}

        for i = 1, 21 do
            local byte = enc[i]
            assert(type(byte) == "number", "integer decoding failure")
            assert(byte >= 0 and byte <= 255, "integer decoding failure")
            assert(byte % 1 == 0, "integer decoding failure")
            encCopy[i] = byte
        end

        for i = 1, 21, 3 do
            local word = 0
            for j = 2, 0, -1 do
                word = word * 256
                word = word + encCopy[i + j]
            end
            a[#a + 1] = word
        end

        return a
    end

    local function mods(d, w)
        local result = d[1] % 2^w

        if result >= 2^(w - 1) then
            result = result - 2^w
        end

        return result
    end

    -- Represents a 168-bit number as the (2^w)-ary Non-Adjacent Form
    local function NAF(d, w)
        local t = {}
        local d = {unpack(d)}

        for i = 1, 168 do
            if d[1] % 2 == 1 then
                t[#t + 1] = mods(d, w)
                d = sub(d, {t[#t], 0, 0, 0, 0, 0, 0})
            else
                t[#t + 1] = 0
            end

            d = rShift(d)
        end

        return t
    end

    return {
        isEqual = isEqual,
        compare = compare,
        add = add,
        sub = sub,
        addDouble = addDouble,
        mult = mult,
        square = square,
        encodeInt = encodeInt,
        decodeInt = decodeInt,
        NAF = NAF
    }
end)()

-- Arithmetic on the finite field of integers modulo p
-- Where p is the finite field modulus
modp = (function()
    local add = arith.add
    local sub = arith.sub
    local addDouble = arith.addDouble
    local mult = arith.mult
    local square = arith.square

    local p = {3, 0, 0, 0, 0, 0, 15761408}

    -- We're using the Montgomery Reduction for fast modular multiplication.
    -- https://en.wikipedia.org/wiki/Montgomery_modular_multiplication 
    -- r = 2^168
    -- p * pInverse = -1 (mod r)
    -- r2 = r * r (mod p)
    local pInverse = {5592405, 5592405, 5592405, 5592405, 5592405, 5592405, 14800213}
    local r2 = {13533400, 837116, 6278376, 13533388, 837116, 6278376, 7504076}

    local function multByP(a)
        local a1, a2, a3, a4, a5, a6, a7 = unpack(a)

        local c1 = a1 * 3
        local c2 = a2 * 3
        local c3 = a3 * 3
        local c4 = a4 * 3
        local c5 = a5 * 3
        local c6 = a6 * 3
        local c7 = a1 * 15761408
        c7 = c7 + a7 * 3
        local c8 = a2 * 15761408
        local c9 = a3 * 15761408
        local c10 = a4 * 15761408
        local c11 = a5 * 15761408
        local c12 = a6 * 15761408
        local c13 = a7 * 15761408
        local c14 = 0

        local temp
        temp = c1 / 0x1000000
        c2 = c2 + (temp - temp % 1)
        c1 = c1 % 0x1000000
        temp = c2 / 0x1000000
        c3 = c3 + (temp - temp % 1)
        c2 = c2 % 0x1000000
        temp = c3 / 0x1000000
        c4 = c4 + (temp - temp % 1)
        c3 = c3 % 0x1000000
        temp = c4 / 0x1000000
        c5 = c5 + (temp - temp % 1)
        c4 = c4 % 0x1000000
        temp = c5 / 0x1000000
        c6 = c6 + (temp - temp % 1)
        c5 = c5 % 0x1000000
        temp = c6 / 0x1000000
        c7 = c7 + (temp - temp % 1)
        c6 = c6 % 0x1000000
        temp = c7 / 0x1000000
        c8 = c8 + (temp - temp % 1)
        c7 = c7 % 0x1000000
        temp = c8 / 0x1000000
        c9 = c9 + (temp - temp % 1)
        c8 = c8 % 0x1000000
        temp = c9 / 0x1000000
        c10 = c10 + (temp - temp % 1)
        c9 = c9 % 0x1000000
        temp = c10 / 0x1000000
        c11 = c11 + (temp - temp % 1)
        c10 = c10 % 0x1000000
        temp = c11 / 0x1000000
        c12 = c12 + (temp - temp % 1)
        c11 = c11 % 0x1000000
        temp = c12 / 0x1000000
        c13 = c13 + (temp - temp % 1)
        c12 = c12 % 0x1000000
        temp = c13 / 0x1000000
        c14 = c14 + (temp - temp % 1)
        c13 = c13 % 0x1000000

        return {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14}
    end

    -- Reduces a number from [0, 2p - 1] to [0, p - 1]
    local function reduceModP(a)
        -- a < p
        if a[7] < 15761408 or a[7] == 15761408 and a[1] < 3 then
            return {unpack(a)}
        end

        -- a > p
        local c1 = a[1]
        local c2 = a[2]
        local c3 = a[3]
        local c4 = a[4]
        local c5 = a[5]
        local c6 = a[6]
        local c7 = a[7]

        c1 = c1 - 3
        c7 = c7 - 15761408

        if c1 < 0 then
            c2 = c2 - 1
            c1 = c1 + 0x1000000
        end
        if c2 < 0 then
            c3 = c3 - 1
            c2 = c2 + 0x1000000
        end
        if c3 < 0 then
            c4 = c4 - 1
            c3 = c3 + 0x1000000
        end
        if c4 < 0 then
            c5 = c5 - 1
            c4 = c4 + 0x1000000
        end
        if c5 < 0 then
            c6 = c6 - 1
            c5 = c5 + 0x1000000
        end
        if c6 < 0 then
            c7 = c7 - 1
            c6 = c6 + 0x1000000
        end

        return {c1, c2, c3, c4, c5, c6, c7}
    end

    local function addModP(a, b)
        return reduceModP(add(a, b))
    end

    local function subModP(a, b)
        local result = sub(a, b)

        if result[7] < 0 then
            result = add(result, p)
        end
        
        return result
    end

    -- Montgomery REDC algorithn
    -- Reduces a number from [0, p^2 - 1] to [0, p - 1]
    local function REDC(T)
        local m = mult(T, pInverse, true)
        local t = {unpack(addDouble(T, multByP(m)), 8, 14)}

        return reduceModP(t)
    end

    local function multModP(a, b)
        -- Only works with a, b in Montgomery form
        return REDC(mult(a, b))
    end

    local function squareModP(a)
        -- Only works with a in Montgomery form
        return REDC(square(a))
    end

    local function montgomeryModP(a)
        return multModP(a, r2)
    end

    local function inverseMontgomeryModP(a)
        local a = {unpack(a)}

        for i = 8, 14 do
            a[i] = 0
        end

        return REDC(a)
    end

    local ONE = montgomeryModP({1, 0, 0, 0, 0, 0, 0})

    local function expModP(base, exponentBinary)
        local base = {unpack(base)}
        local result = {unpack(ONE)}

        for i = 1, 168 do
            if exponentBinary[i] == 1 then
                result = multModP(result, base)
            end
            base = squareModP(base)
        end 

        return result
    end

    return {
        addModP = addModP,
        subModP = subModP,
        multModP = multModP,
        squareModP = squareModP,
        montgomeryModP = montgomeryModP,
        inverseMontgomeryModP = inverseMontgomeryModP,
        expModP = expModP
    }
end)()

-- Arithmetic on the Finite Field of Integers modulo q
-- Where q is the generator's subgroup order.
modq = (function()
    local isEqual = arith.isEqual
    local compare = arith.compare
    local add = arith.add
    local sub = arith.sub
    local addDouble = arith.addDouble
    local mult = arith.mult
    local square = arith.square
    local encodeInt = arith.encodeInt
    local decodeInt = arith.decodeInt

    local modQMT

    local q = {9622359, 6699217, 13940450, 16775734, 16777215, 16777215, 3940351}
    local qMinusTwoBinary = {1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1}
    
    -- We're using the Montgomery Reduction for fast modular multiplication.
    -- https://en.wikipedia.org/wiki/Montgomery_modular_multiplication 
    -- r = 2^168
    -- q * qInverse = -1 (mod r)
    -- r2 = r * r (mod q)
    local qInverse = {15218585, 5740955, 3271338, 9903997, 9067368, 7173545, 6988392}
    local r2 = {1336213, 11071705, 9716828, 11083885, 9188643, 1494868, 3306114}

    -- Reduces a number from [0, 2q - 1] to [0, q - 1]
    local function reduceModQ(a)
        local result = {unpack(a)}

        if compare(result, q) >= 0 then
            result = sub(result, q)
        end

        return setmetatable(result, modQMT)
    end

    local function addModQ(a, b)
        return reduceModQ(add(a, b))
    end

    local function subModQ(a, b)
        local result = sub(a, b)

        if result[7] < 0 then
            result = add(result, q)
        end
        
        return setmetatable(result, modQMT)
    end

    -- Montgomery REDC algorithn
    -- Reduces a number from [0, q^2 - 1] to [0, q - 1]
    local function REDC(T)
        local m = {unpack(mult({unpack(T, 1, 7)}, qInverse, true), 1, 7)}
        local t = {unpack(addDouble(T, mult(m, q)), 8, 14)}

        return reduceModQ(t)
    end

    local function multModQ(a, b)
        -- Only works with a, b in Montgomery form
        return REDC(mult(a, b))
    end

    local function squareModQ(a)
        -- Only works with a in Montgomery form
        return REDC(square(a))
    end

    local function montgomeryModQ(a)
        return multModQ(a, r2)
    end

    local function inverseMontgomeryModQ(a)
        local a = {unpack(a)}

        for i = 8, 14 do
            a[i] = 0
        end

        return REDC(a)
    end

    local ONE = montgomeryModQ({1, 0, 0, 0, 0, 0, 0})

    local function expModQ(base, exponentBinary)
        local base = {unpack(base)}
        local result = {unpack(ONE)}

        for i = 1, 168 do
            if exponentBinary[i] == 1 then
                result = multModQ(result, base)
            end
            base = squareModQ(base)
        end 

        return result
    end

    local function intExpModQ(base, exponent)
        local base = {unpack(base)}
        local result = setmetatable({unpack(ONE)}, modQMT)

        if exponent < 0 then
            base = expModQ(base, qMinusTwoBinary)
            exponent = -exponent
        end

        while exponent > 0 do
            if exponent % 2 == 1 then
                result = multModQ(result, base)
            end
            base = squareModQ(base)
            exponent = exponent / 2
            exponent = exponent - exponent % 1
        end 

        return result
    end

    local function encodeModQ(a)
        local result = encodeInt(a)

        return setmetatable(result, byteTableMT)
    end

    local function decodeModQ(s)
        s = type(s) == "table" and {unpack(s, 1, 21)} or {tostring(s):byte(1, 21)}
        local result = decodeInt(s)
        result[7] = result[7] % q[7]

        return setmetatable(result, modQMT)
    end

    local function randomModQ()
        while true do
            local s = {unpack(random.random.random(), 1, 21)}
            local result = decodeInt(s)
            if result[7] < q[7] then
                return setmetatable(result, modQMT)
            end
        end
    end

    local function hashModQ(data)
        return decodeModQ(sha256.sha256.digest(data))
    end

    modQMT = {
        __index = {
            encode = function(self)
                return encodeModQ(self)
            end
        },

        __tostring = function(self)
            return self:encode():toHex()
        end,

        __add = function(self, other)
            if type(self) == "number" then
                return other + self
            end

            if type(other) == "number" then
                assert(other < 2^24, "number operand too big")
                other = montgomeryModQ({other, 0, 0, 0, 0, 0, 0})
            end

            return addModQ(self, other)
        end,

        __sub = function(a, b)
            if type(a) == "number" then
                assert(a < 2^24, "number operand too big")
                a = montgomeryModQ({a, 0, 0, 0, 0, 0, 0})
            end

            if type(b) == "number" then
                assert(b < 2^24, "number operand too big")
                b = montgomeryModQ({b, 0, 0, 0, 0, 0, 0})
            end

            return subModQ(a, b)
        end,

        __unm = function(self)
            return subModQ(q, self)
        end,

        __eq = function(self, other)
            return isEqual(self, other)
        end,

        __mul = function(self, other)
            if type(self) == "number" then
                return other * self
            end

            -- EC point
            -- Use the point's metatable to handle multiplication
            if type(other) == "table" and type(other[1]) == "table" then
                return other * self
            end

            if type(other) == "number" then
                assert(other < 2^24, "number operand too big")
                other = montgomeryModQ({other, 0, 0, 0, 0, 0, 0})
            end

            return multModQ(self, other)
        end,

        __div = function(a, b)
            if type(a) == "number" then
                assert(a < 2^24, "number operand too big")
                a = montgomeryModQ({a, 0, 0, 0, 0, 0, 0})
            end

            if type(b) == "number" then
                assert(b < 2^24, "number operand too big")
                b = montgomeryModQ({b, 0, 0, 0, 0, 0, 0})
            end

            local bInv = expModQ(b, qMinusTwoBinary)

            return multModQ(a, bInv)
        end,

        __pow = function(self, other)
            return intExpModQ(self, other)
        end
    }

    return {
        hashModQ = hashModQ,
        randomModQ = randomModQ,
        decodeModQ = decodeModQ,
        inverseMontgomeryModQ = inverseMontgomeryModQ
    }
end)()