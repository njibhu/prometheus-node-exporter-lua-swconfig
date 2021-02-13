local switch_name = "switch0"
local indentationType = "\t" -- "        "

local function stripSpaces(text)
  return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function parseLine(line, indent)
  indent = indent or ""
  local key = string.gsub(line, "^" .. indent .. "([^:]+):(.+)$", "%1")
  local value, match = string.gsub(line, "^" .. indent .. "([^:]+):(.+)$", "%2")
  return key, stripSpaces(value)
end

local function parseSubType(filelines)
  local subType = {}
  local line = filelines[1]
  while line do
    if line:match("^$") == nil then
      table.insert(subType, line)
      table.remove(filelines, 1)
    else
      table.remove(filelines, 1)
      break
    end
    line = filelines[1]
  end
  return subType
end

local function parseValue(filelines)
  local previousKey
  local parsedValue = {}
  local line = filelines[1]
  while line do
    local isIndented = line:match("^" .. indentationType)
    if isIndented ~= nil then
      local key, value = parseLine(line, indentationType)
      parsedValue[key] = value
      previousKey = key
      table.remove(filelines, 1)
    else
      local value, match = string.gsub(line, "^([^:]+):(.+)$", "%2")
      if match > 0 then
        parsedValue[previousKey] = parseSubType(filelines)
      else
        return parsedValue
      end
    end
    line = filelines[1]
  end

  return parsedValue
end

local function parseOutput(data)
  local filelines = {}
  local parsedObject = {}
  for line in (data .. "\n"):gmatch("(.-)" .. "\n") do
    table.insert(filelines, line)
  end

  local line = filelines[1]
  while line do
    local key = string.gsub(line, "^([^:]+):", "%1")
    table.remove(filelines, 1)
    if key ~= "" then
      parsedObject[key] = parseValue(filelines)
    end
    line = filelines[1]
  end

  return parsedObject
end

function get_contents(filename)
  local f = io.open(filename, "rb")
  local contents = ""
  if f then
    contents = f:read "*a"
    f:close()
  end

  return contents
end

local function parseLink(text)
  local object = {}
  for property in (text .. " "):gmatch("(.-)" .. " ") do
    local key, value = parseLine(property)
    object[key] = value
  end
  return object
end

local function parseMib(text)
  local object = {}
  for index, line in ipairs(text) do
    local key, value = parseLine(line)
    object[stripSpaces(key)] = stripSpaces(value)
  end
  return object
end

-- Port metrics
local function portMetrics(swconfig)
  local portNumber = 1
  local port = swconfig["Port " .. 1]
  while port ~= nil do
    local portLink = parseLink(port["link"])
    local labels = {
      port_id = portLink["port"],
      switch_id = switch_name
    }

    local rxGoodByte = 0
    local txByte = 0
    if type(port["mib"]) ~= "string" then
      local mib = parseMib(port["mib"])
      rxGoodByte = string.gsub(mib["RxGoodByte"], "^(%d+)(.*)", "%1")
      txByte = string.gsub(mib["TxByte"], "^(%d+)(.*)", "%1")
    end

    local isUp = 0
    if portLink["link"] == "up" then
      isUp = 1
    end

    local portSpeed = 0
    if type(portLink["speed"]) == "string" then
      portSpeed = string.gsub(portLink["speed"], "^(%d+)(.*)", "%1")
    end

    metric("node_swconfig_port_rxgoodbyte_total", "counter", labels, tonumber(rxGoodByte))
    metric("node_swconfig_port_txbyte_total", "counter", labels, tonumber(txByte))
    metric("node_swconfig_port_link_up", "gauge", labels, tonumber(isUp))
    metric("node_swconfig_port_link_speed", "gauge", labels, tonumber(portSpeed))

    portNumber = portNumber + 1
    port = swconfig["Port " .. portNumber]
  end
end

-- Vlan metrics
local function vlanMetrics(swconfig)
  for name, vlan in pairs(swconfig) do
    if name:match("^VLAN") ~= nil then
      local labels = {
        vlan_id = vlan["vid"],
        vlan_name = name,
        switch_id = switch_name
      }

      for match in (vlan["ports"] .. " "):gmatch("(%d+) ") do
        metric("node_swconfig_vlan_untagged", "gauge", labels, tonumber(match))
      end
      for match in (vlan["ports"] .. " "):gmatch("(%d+)t ") do
        metric("node_swconfig_vlan_tagged", "gauge", labels, tonumber(match))
      end
    end
  end
end

-- Address resolution table metrics
local function arlMetrics(swconfig)
  local arl = swconfig["Global attributes"]["arl_table"]
  if type(arl) == "table" then
    for index, entry in ipairs(arl) do
      local key, value = parseLine(entry)
      local labels = {
        port_id = string.gsub(key, "Port ", ""),
        mac_addr = string.gsub(value, "MAC ", ""),
        switch_id = switch_name
      }
      metric("node_swconfig_port_arltable_entry", "gauge", labels, 1)
    end
  end
end

local function scrape()
  local swconfig_fd = io.popen("/sbin/swconfig dev " .. switch_name .. " show")
  local swconfig = parseOutput(swconfig_fd:read("*a"))
  swconfig_fd:close()

  portMetrics(swconfig)
  vlanMetrics(swconfig)
  arlMetrics(swconfig)
end

return {scrape = scrape}
