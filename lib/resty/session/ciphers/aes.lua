local setmetatable = setmetatable
local tonumber     = tonumber
local aes          = require "resty.aes"
local cip          = aes.cipher
local hashes       = aes.hash
local ceil         = math.ceil
local var          = ngx.var
local sub          = string.sub
local rep          = string.rep


local CIPHER_MODES = {
    ecb    = "ecb",
    cbc    = "cbc",
    cfb1   = "cfb1",
    cfb8   = "cfb8",
    cfb128 = "cfb128",
    ofb    = "ofb",
    ctr    = "ctr"
}

local CIPHER_SIZES = {
    ["128"] = 128,
    ["192"] = 192,
    ["256"] = 256
}

local defaults = {
    size   = CIPHER_SIZES[var.session_aes_size] or 256,
    mode   = CIPHER_MODES[var.session_aes_mode] or "cbc",
    hash   = hashes[var.session_aes_hash]       or "sha512",
    rounds = tonumber(var.session_aes_rounds)   or 1
}

local function salt(s)
    if s then
        local z = #s
        if z < 8 then
            return sub(rep(s, ceil(8 / z)), 1, 8)
        end
        if z > 8 then
            return sub(s, 1, 8)
        end
        return s
    end
end

local cipher = {}

cipher.__index = cipher

function cipher.new(config)
    local a = config.aes or defaults
    return setmetatable({
        size   = CIPHER_SIZES[a.size or defaults.size]   or 256,
        mode   = CIPHER_MODES[a.mode or defaults.mode]   or "cbc",
        hash   = hashes[a.hash       or defaults.hash]   or hashes.sha512,
        rounds = tonumber(a.rounds   or defaults.rounds) or 1
    }, cipher)
end

function cipher:encrypt(d, k, s)
    return aes:new(k, salt(s), cip(self.size, self.mode), self.hash, self.rounds):encrypt(d)
end

function cipher:decrypt(d, k, s)
    return aes:new(k, salt(s), cip(self.size, self.mode), self.hash, self.rounds):decrypt(d)
end

return cipher
