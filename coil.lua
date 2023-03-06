#!/usr/bin/env lua54

LANES = require 'lanes'
LINDA = LANES.linda()
JSON  = require 'cjson'
CURL  = require 'cURL'

local adr     = 'https://www.coilcraft.com/api/power-inductor/parts'
local part    = 'SER2918H-153' -- 'PA6331' 'AGP4233-153'

local outputs = { 'NominalInductance', 'L', 'InductanceAtIpeak', 'Isat', 'IRMS40C'
                , 'SRFMHz', 'ACLoss', 'DCLoss', 'LossAE', 'LossN', 'LossRFac'
                , 'LossRth', 'LossVE', 'AdjustedRippleCurrent', 'AdjustedIpeak'
                , 'PartTemperature', 'Width', 'Length', 'Height', 'LossCore'
                , 'CoreMaterial', 'Mount', 'Price'}

local inputs  = { 'Temperature', 'Frequency', 'DCcurrent', 'RipplePercent'
                , 'RippleCurrent', 'PeakCurrent' }

local templateHandle = io.open('./template.json', 'r')
local template       = JSON.decode(templateHandle:read('*all'))
_                    = io.close(templateHandle)

local function sendRequest(payload)
    local curl  = require 'cURL'
    local json  = require 'cjson'
    local res = {}
    local req = curl.easy{ url        = adr
                         , post       = true
                         , httpheader = { "Content-Type: application/json"; }
                         ; postfields = json.encode(payload);
                         }
    req:setopt_writefunction(table.insert, res)
    local ok,err   = req:perform()
    local partData = {}
    res = json.decode(table.concat(res))
    for _,data in pairs(res.PartsData) do
        if data.PartNumber == part then
            partData = data
        end
    end
    -- local ok,val   = pcall(json.decode(table.concat(res)))
    -- if ok then
    --     for _,data in pairs(val.PartsData) do
    --         if data.PartNumber == part then
    --             partData = data
    --         end
    --     end
    -- else
    --     print('Error occured: ' .. val)
    --     partData = {}
    -- end
    return partData
end

local function toCsv(data)
    local line = ''
    for _,output in pairs(outputs) do
        line = line .. ',' .. data[output]
    end
    return line
end

function sendRequestParallel(tmp, frq, idc)
    print('Sending ' .. tmp .. ',' .. frq .. ',' .. idc)
    local ric = 0.5
    local rip = 100 * ric / idc
    -- local ric = idc * rip / 100;
    local rpc = ric / 2 + idc;
    template.current.idcCurrent           = idc
    template.current.rippleCurrent        = ric
    template.current.rippleCurrentPercent = rip
    template.current.ipeakCurrent         = rpc
    template.frequency.lower              = frq
    template.frequency.value              = frq
    template.temperature                  = tmp
    local xs      = tmp .. ',' .. frq .. ',' .. idc .. ',' .. rip .. ',' .. ric .. ',' .. rpc
    local res     = sendRequest(template)
    local csvLine = ''
    if next(res) ~= nil then
        local ys  = toCsv(res)
        csvLine   = xs .. ys .. '\n'
    end
    return csvLine
end

local lines    = {}
local tmpRange = {-40, -20, 0, 25, 27, 50, 85}

for _,tmp in pairs(tmpRange) do
    for frqIdx = 1,10 do
        local frq = frqIdx / 10
        for idc = 5,10 do
            -- for rip = 1,10 do
                local genLine = LANES.gen('*', sendRequestParallel)
                local csvLine = genLine(tmp,frq,idc)
                table.insert(lines, csvLine)
            -- end
        end
    end
end

local csvString = ''
for _,line in pairs(lines) do
    csvString = csvString .. line[1]
end

local csvData   = table.concat(inputs, ',') .. table.concat(outputs, ',')
                    .. '\n' .. csvString
local csvHandle = io.open('./loss.csv', 'w')
_               = csvHandle:write(csvData)
_               = io.close(csvHandle)
