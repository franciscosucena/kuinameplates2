--[[
-- Simple configuration library with profiles.
-- By Kesava @ curse.com.
-- All rights reserved.
--]]
local MAJOR, MINOR = 'KuiConfig-1.0', 2
local kc = LibStub:NewLibrary(MAJOR, MINOR)

if not kc then
    -- already registered
    return
end

function kc:print(m)
    print(MAJOR..'-'..MINOR..': '..(m or 'nil'))
end

local config_meta = {}
config_meta.__index = config_meta

--[[
-- merges current active profile (self.profile) with given defaults and returns
-- the resulting config table
--]]
function config_meta:GetConfig()
    if not self.profile then return end

    local local_config = {}

    for k,v in pairs(self.defaults) do
        -- apply default config
        local_config[k] = v
    end

    for k,v in pairs(self.profile) do
        if self.defaults[k] == nil or self.defaults[k] == v then
            -- unset variables which don't exist or which equal the defaults
            self.profile[k] = nil
        else
            -- apply saved variables from profile
            local_config[k] = v
        end
    end

    return local_config
end

function config_meta:SetConfig(k,v)
    if not self.profile then return end
    self.profile[k] = v

    -- post complete profile to saved variable
    -- TODO set to other profiles maybe?
    _G[self.gsv_name].profiles[self.csv.profile] = self.profile

    -- TODO debug
    LibStub('Kui-1.0').print(self.profile)
    LibStub('Kui-1.0').print(_G[self.gsv_name].profiles[self.csv.profile])

    -- dispatch to configChanged listeners
    if type(self.listeners) == 'table' then
        for i,listener_tbl in ipairs(self.listeners) do
            local listener,func = unpack(listener_tbl)

            if  listener and
                type(func) == 'string' and
                type(listener[func]) == 'function'
            then
                listener[func](listener,self,k,v)
            elseif type(func) == 'function' then
                func(self,k,v)
            end
        end
    end
end

function config_meta:GetProfile(profile_name)
    if not profile_name then
        profile_name = 'default'
    end

    if not self.gsv.profiles[profile_name] then
        self.gsv.profiles[profile_name] = {}
    end

    return self.gsv.profiles[profile_name]
end

--[[
-- alias for GetProfile(active_profile_name)
-- sets config_meta.profile to active profile
--]]
function config_meta:GetActiveProfile()
    self.profile = self:GetProfile(self.csv.profile)
    return self.profile
end

function config_meta:RegisterConfigChanged(arg1,arg2)
    if not self.listeners then
        self.listeners = {}
    end

    if type(arg1) == 'table' and type(arg2) == 'string' and arg1[arg2] then
        tinsert(self.listeners,{arg1,arg2})
    elseif type(arg1) == 'function' then
        tinsert(self.listeners,{nil,arg1})
    else
       kc:print('invalid arguments to RegisterConfigChanged: no function')
    end
end

function kc:Initialise(var_prefix,defaults)
    local config_tbl = {}
    setmetatable(config_tbl, config_meta)
    config_tbl.defaults = defaults

    local g_name, c_name = var_prefix..'Saved', var_prefix..'CharacterSaved'

    if not _G[g_name] then _G[g_name] = {} end
    if not _G[c_name] then _G[c_name] = {} end

    local gsv, csv = _G[g_name], _G[c_name]

    if not gsv.profiles then
        gsv.profiles = {}
    end

    if not csv.profile then
        csv.profile = 'default'
    end

    config_tbl.gsv_name = g_name
    config_tbl.csv_name = c_name

    config_tbl.gsv = gsv
    config_tbl.csv = csv

    config_tbl:GetActiveProfile()
    return config_tbl
end