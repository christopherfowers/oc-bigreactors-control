-- Required Libraries:
local component = require("component")
local keyboard = require("keyboard")
local term = require("term")

-- Local Variables
--This is true if there is no available screen or the option -s is used
local silent = not term.isAvailable()
local ticks = 0
local maxCaseTemp = 1500
local maxCoreTemp = 1500
local targetCaseTemp = 1000
local targetCoreTemp = 1000
local criticalCoreTemp = 1750
local criticalCaseTemp = 1700
local safeStartingTemp = 700

function handleReactor(reactor)
    if reactor.getActive() then
        if not isSafeToRun(reactor) or not isPowerLow(reactor) then
            stopeReactor(reactor)
            return
        end
        if ticks >= 5 then
            ticks = 0
            if reactor.getFuelTemperature() <= targetCoreTemp and reactor.getCasingTemperature() <= targetCaseTemp then
                setRodDepth(reactor.getControlRodLevel(0) - 1)
            elseif reactor.getFuelTemperature() >= targetCoreTemp and reactor.getCasingTemperature() >= targetCaseTemp then
                setRodDepth(reactor.getControlRodLevel(0) + 1)
            end
        end
    elseif isSafeToRun(reactor) and isPowerLow(reactor) then
        startReactor(reactor)
    end
end

function isPowerLow(reactor)
    return reactor.getEnergyCapacity() > reactor.getEnergyStored()
end 

function isSafeToRun(reactor)
    if reactor.getCasingTemperature() < criticalCaseTemp and reactor.getFuelTemperature() < criticalCoreTemp then
        return true
    end
    return false
end

function isSafeToStart(reactor)
    if reacttor.getCasingTemperature() < safeStartingTemp and reactor.getFuelTemperature() < safeStartingTemp then
        return true
    end
    return false
end

function isStorageLow(reactor)
    local storageCap = reactor.getEnergyCapacity()
    local storedEnergy = reactor.getEnergyStored()
    return storedCap - storedEnergy > 0
end

function stopReactor(reactor)
    reactor.setAllControlRodLevels(100)
    reactor.setActive(false)
end

function startReactor(reactor)
    reactor.setAllControlRodLevels(60)
    reactor.setActive(false)
end

function printStats(reactor, num)
    local state = reactor.getActive()
    local stored = reactor.getEnergyStored()
    local maxEnergy = reactor.getEnergyCapacity()
    local offs = #tostring(maxEnergy) + 5
    
    if state then
        state = "On"
    else
        state = "Off"
    end
    
    term.write("Reactor " .. num .. "\n", false)
    term.clearLine()

    term.write("Reactor state:      " .. state .. "\n", false)
    term.clearLine()
    term.write("Currently stored:   " .. stored .. " RF\n", false)
    term.clearLine()
    term.write("Stored percentage:  " .. stored / maxEnergy * 100 .. " %\n", false)
    term.clearLine()
    term.write("Current Production: " .. reactor.getEnergyProducedLastTick() .. " RF/t"
    term.clearLine()
    term.write("Case Temp: " ..reactor.getCasingTemperature() .. "\n"
    term.clearLine()
    term.write("Fuel Temp: " .. reactor.getFuelTemperature() .. "\n"
end

function setRodDepth(reactor, depth) 
    reactor.setAllControlRodLevels(depth)
end

function handleControl()
    if not component.isAvailable("br_reactor") then
        return nil
    end
    
    local reactorNum = 0
    for address, componentType in component.list("br_reactor") do
        reactorNum = reactorNum + 1
        handleReactor(component.proxy(address))
        printStats(component.proxy(address), reactorNum)
    end
end

function endProgram()
    if not silent then
        term.write("\nReactor shut down.\n")
    end
    for address, componentType in component.list("br_reactor") do
        stopReactor(component.proxy(address))
    end
    os.exit()
end

--Main Program Loopcom
function run()
    while true do
        handleControl()
        if keyboard.isKeyDown(keyboard.keys.w) and keyboard.isControlDown() then
            endProgram();
        end
        tick = tick + 1
        os.sleep(1)
    end
end

run()
