local partyBase = 0x02024284 -- início da Party Pokémon
local personalityValueOffset = 0x0  

local function isShiny(pid, tid, sid)
    local pidHigh = math.floor(pid / 0x10000)
    local pidLow = pid % 0x10000
    local xor = tid ~ sid
    xor = xor ~ pidHigh
    xor = xor ~ pidLow
    return xor < 8
end

-- Corrigido: lê direto o PID (4 bytes little endian)
local function readPersonalityValue()
    return memory.read_u32_le(partyBase + personalityValueOffset)
end

-- Corrigido: lê IVs reais do Pokémon na party
local function getIVs(pokemonBase)
    -- IVs ficam em 2 bytes (word) na posição 0x1C
    local ivData = memory.read_u32_le(pokemonBase + 0x1C)

    local hp     =  ivData        & 0x1F
    local atk    = (ivData >> 5)  & 0x1F
    local def    = (ivData >> 10) & 0x1F
    local spd    = (ivData >> 15) & 0x1F
    local spatk  = (ivData >> 20) & 0x1F
    local spdef  = (ivData >> 25) & 0x1F

    return hp, atk, def, spatk, spdef, spd
end

local function softReset()
    joypad.set({A=true, B=true, Start=true, Select=true})
    emu.frameadvance()
    joypad.set({})
    emu.frameadvance()

    for i=1,60 do
        emu.frameadvance()
    end

    joypad.set({Start=true})
    emu.frameadvance()
    joypad.set({})
    emu.frameadvance()
    
    for i=1,30 do
        emu.frameadvance()
    end
end

local function loadSaveState()
    savestate.loadslot(1)
    emu.frameadvance()
end

-- Ajustado: só precisa rodar 1 vez
local function selectCharmander()
    for i = 1, 15 do
        joypad.set({A=true})
        emu.frameadvance()
        emu.frameadvance()
        joypad.set({})
        emu.frameadvance()
        emu.frameadvance()
    end
end

local function waitForPokemonLoad()
    local minWait = 20
    local maxWait = 1800
    local waitCount = 0
    
    while waitCount < maxWait do
        local pid = readPersonalityValue()
        if pid ~= 0 and waitCount > minWait then
            console.log("Pokémon carregado após " .. waitCount .. " frames")
            return true
        end
        emu.frameadvance()
        waitCount = waitCount + 1
    end
    
    console.log("Timeout: Pokémon não foi carregado")
    return false
end

local function readTrainerIDs()
    local tid = memory.read_u16_le(0x02025D8E)
    local sid = memory.read_u16_le(0x02025D90)
    return tid, sid
end

local function checkPokemonInParty()
    local species = memory.read_u16_le(partyBase + 0x08)
    return species ~= 0
end

-- Loop principal
local attemptCount = 0
loadSaveState()

while true do
    attemptCount = attemptCount + 1

    softReset()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()
    selectCharmander()

    if waitForPokemonLoad() and checkPokemonInParty() then
        local pid = readPersonalityValue()
        local tid, sid = readTrainerIDs()
        local hp, atk, def, spatk, spdef, spd = getIVs(partyBase)

        if pid == 0 then
            console.log("Tentativa " .. attemptCount .. ": PID zero")
        elseif isShiny(pid, tid, sid) then
            console.log(string.format(
                "Tentativa %d: SHINY ENCONTRADO! PID: 0x%08X | IVs HP:%d Atk:%d Def:%d SpAtk:%d SpDef:%d Spd:%d",
                attemptCount, pid, hp, atk, def, spatk, spdef, spd))
            break
        else
            console.log(string.format(
                "Tentativa %d: Não shiny. PID: 0x%08X | IVs HP:%d Atk:%d Def:%d SpAtk:%d SpDef:%d Spd:%d",
                attemptCount, pid, hp, atk, def, spatk, spdef, spd))
        end
    else
        console.log("Tentativa " .. attemptCount .. ": Falha ao carregar Pokémon")
    end
end
