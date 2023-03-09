#!/usr/bin/env lua54

-- LANES = require 'lanes'
-- LINDA = LANES.linda()
JSON  = require 'cjson'
CURL  = require 'cURL'
SOCK  = require 'socket'

local adr     = 'https://www.coilcraft.com/api/power-inductor/parts'
local part    = 'SER2918H-153' -- 'PA6331' 'AGP4233-153'
local csvPath = './' .. part .. '.csv'

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
    local res  = {}
    local req  = CURL.easy{ url        = adr
                          , post       = true
                          , httpheader = { "Content-Type: application/json"; }
                          , postfields = JSON.encode(payload)
                          , timeout    = 666
                          }
    req:setopt_writefunction(table.insert, res)
    local ok,err = req:perform()
    local success, partData = pcall(JSON.decode, table.concat(res, ''));
    if not success then
        print('Rate limited, sleeping for 30s ... ')
        print('\t' .. table.concat(res, ''))
        SOCK.sleep(30.0)
        partData = sendRequest(payload)
    end
    return partData
end

local function toCsv(res)
    local line = ''
    local partsData = res['PartsData']
    for _,data in pairs(partsData) do
        if data.PartNumber == part then
            for _,output in pairs(outputs) do
                line = line .. ',' .. (data[output] or '')
            end
        end
    end
    return line
end

local function sendRequestParallel(tmp, frq, idc)
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
    if res then
        local ys  = toCsv(res)
        csvLine   = xs .. ys
    end
    return csvLine
end

local lines    = {}
local tmpRange = {-40, -20, 0, 25, 27, 50, 85}

for i,tmp in pairs(tmpRange) do
    print('Temperature ' .. i .. ': ' .. tmp)
    for frqIdx = 1,10 do
        local frq = frqIdx / 10
        for idc = 5,10 do
            -- for rip = 1,10 do
                local csvLine = sendRequestParallel(tmp, frq, idc)
                table.insert(lines, csvLine)
            -- end
        end
    end
end

local csvString = table.concat(lines, '\n')

local csvData   = table.concat(inputs, ',') .. table.concat(outputs, ',')
                    .. '\n' .. csvString
local csvHandle = io.open(csvPath, 'w')
_               = csvHandle:write(csvData)
_               = io.close(csvHandle)
