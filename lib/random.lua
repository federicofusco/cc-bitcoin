-- Imports SHA256
os.loadAPI("lib/sha256")

-- Random Byte Generator
random = (function()
    local entropy = ""
    local accumulator = ""
    local entropyPath = "/.random"

    local function feed(data)
        accumulator = accumulator .. (data or "")
    end

    local function digest()
        entropy = tostring(sha256.sha256.digest(entropy .. accumulator))
        accumulator = ""
    end

    if fs.exists(entropyPath) then
        local entropyFile = fs.open(entropyPath, "rb")
        feed(entropyFile.readAll())
        entropyFile.close()
    end

    feed("init")
    feed(tostring(math.random(1, 2^31 - 1)))
    feed("|")
    feed(tostring(math.random(1, 2^31 - 1)))
    feed("|")
    feed(tostring(math.random(1, 2^4)))
    feed("|")
    feed(tostring(os.epoch("utc")))
    feed("|")
    for _ = 1, 10000 do
        feed(tostring({}):sub(-8))
    end
    digest()
    feed(tostring(os.epoch("utc")))
    digest()

    local function save()
        feed("save")
        feed(tostring(os.epoch("utc")))
        feed(tostring({}))
        digest()

        local entropyFile = fs.open(entropyPath, "wb")
        entropyFile.write(tostring(sha256.sha256.hmac("save", entropy)))
        entropy = tostring(sha256.sha256.digest(entropy))
        entropyFile.close()
    end
    save()

    local function seed(data)
        feed("seed")
        feed(tostring(os.epoch("utc")))
        feed(tostring({}))
        feed(data)
        digest()
        save()
    end

    --[[
        @desc Generates random bytes
        @returns [table] Random bytes
    ]]
    local function random()
        feed("random")
        feed(tostring(os.epoch("utc")))
        feed(tostring({}))
        digest()
        save()

        local result = sha256.sha256.hmac("out", entropy)
        entropy = tostring(sha256.sha256.digest(entropy))
        
        return result
    end

    return {
        seed = seed,
        save = save,
        random = random
    }
end)()