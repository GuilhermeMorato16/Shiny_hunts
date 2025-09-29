-- Exibe informações da ROM
local romName = gameinfo.getromname()
local romHash = gameinfo.getromhash()
console.log("ROM carregada: " .. romName)
console.log("Hash: " .. romHash)

-- Endereços para FireRed (ajustados)
local partyCountAddress = 0x02024029 -- Número de Pokémon na party
local partyBase = 0x0202402C -- Base da party data
local tidAddress = 0x02025AE8 -- TID
local sidAddress = 0x02025AEA -- SID

-- Tamanho de cada entrada de Pokémon na party (100 bytes)
local POKEMON_SIZE = 100

-- Lê dados descriptografados do Pokémon
local function readPokemonData(slotIndex)
    local pokemonOffset = partyBase + (slotIndex * POKEMON_SIZE)
    
    -- Lê os dados básicos (não criptografados)
    local pid = memory.read_u32_le(pokemonOffset + 0x00)
    local otid = memory.read_u32_le(pokemonOffset + 0x04)
    
    if pid == 0 then
        return nil -- Pokémon não existe neste slot
    end
    
    -- Lê dados criptografados (começam no offset 0x20)
    local encryptedDataOffset = pokemonOffset + 0x20
    local encryptionKey = pid ~ otid
    
    -- Descriptografa os 48 bytes de dados
    local decryptedData = {}
    for i = 0, 47, 4 do
        local encryptedValue = memory.read_u32_le(encryptedDataOffset + i)
        decryptedData[i] = encryptedValue ~ encryptionKey
    end
    
    -- Determina a ordem das substructures baseada no PID
    local substructOrder = (pid % 24)
    local orderMappings = {
        [0] = {0, 1, 2, 3}, -- GAEM
        [1] = {0, 1, 3, 2}, -- GAME
        [2] = {0, 2, 1, 3}, -- GEAM
        [3] = {0, 2, 3, 1}, -- GEMA  
        [4] = {0, 3, 1, 2}, -- GMAE
        [5] = {0, 3, 2, 1}, -- GMEA
        [6] = {1, 0, 2, 3}, -- AGEM
        [7] = {1, 0, 3, 2}, -- AGME
        [8] = {2, 0, 1, 3}, -- AEGM
        [9] = {3, 0, 1, 2}, -- AEMG
        [10] = {1, 2, 0, 3}, -- AMGE
        [11] = {1, 3, 0, 2}, -- AMEG
        [12] = {2, 1, 0, 3}, -- EGAM
        [13] = {3, 1, 0, 2}, -- EGMA
        [14] = {2, 0, 1, 3}, -- EAGM
        [15] = {3, 0, 1, 2}, -- EAMG
        [16] = {2, 3, 0, 1}, -- EMGA
        [17] = {3, 2, 0, 1}, -- EMAG
        [18] = {1, 2, 3, 0}, -- MGAE
        [19] = {1, 3, 2, 0}, -- MGEA
        [20] = {2, 1, 3, 0}, -- MAGE
        [21] = {2, 3, 1, 0}, -- MAEG
        [22] = {3, 1, 2, 0}, -- MEGA
        [23] = {3, 2, 1, 0}, -- MEAG
    }
    
    local order = orderMappings[substructOrder]
    
    -- Reorganiza as substructures (cada uma tem 12 bytes)
    local reorderedData = {}
    for i = 0, 3 do
        local srcSubstruct = order[i + 1] -- Lua é 1-indexado
        for j = 0, 11 do
            reorderedData[i * 12 + j] = decryptedData[srcSubstruct * 12 + j]
        end
    end
    
    -- Extrai informações das substructures reorganizadas
    local species = reorderedData[0] & 0xFFFF -- Growth: Species (bytes 0-1)
    local ivData = reorderedData[44] -- Misc: IV data (bytes 44-47)
    
    return {
        pid = pid,
        otid = otid,
        species = species,
        ivData = ivData or 0
    }
end

-- Fórmula shiny correta
local function isShiny(pid, tid, sid)
    local pidHigh = math.floor(pid / 0x10000)
    local pidLow = pid % 0x10000
    local xorResult = tid ~ sid ~ pidHigh ~ pidLow
    return xorResult < 8
end

local function getIVs(ivData)
    if ivData == 0 then
        return 0, 0, 0, 0, 0, 0
    end
    
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
    for i=1,120 do emu.frameadvance() end
end

local function loadSaveState()
    savestate.loadslot(1)
    for i=1,60 do emu.frameadvance() end
end

local function pressA(duration)
    duration = duration or 1
    for i = 1, duration do
        joypad.set({A=true})
        emu.frameadvance()
    end
    joypad.set({})
    for i = 1, 10 do emu.frameadvance() end
end
local function pressB(duration)
    duration = duration or 1
    for i = 1, duration do
        joypad.set({B=true})
        emu.frameadvance()
    end
    joypad.set({})
    for i = 1, 10 do emu.frameadvance() end
end

local function moveDirection(direction, steps)
    steps = steps or 1
    for step = 1, steps do
        for frame = 1, 16 do
            joypad.set({[direction]=true})
            emu.frameadvance()
        end
        joypad.set({})
        for i = 1, 8 do emu.frameadvance() end
    end
end

local function selectCharmanderSequence()
    console.log("Iniciando seleção do Charmander...")
    
    -- Espera carregar a tela do laboratório
    for i = 1, 180 do emu.frameadvance() end
    
    -- Caminha até Charmander (pokeball da direita)
    -- moveDirection("Right", 2)
    -- moveDirection("Up", 1)
    
    -- Pressiona A para selecionar
    pressA(1)
    for i = 1, 60 do emu.frameadvance() end
    
    -- Confirma seleção (vários As para passar os diálogos)
    for i = 1, 40 do
        pressA(1)
        for j = 1, 30 do emu.frameadvance() end
    end
    for i = 1, 20 do
        pressB(1)
        for j = 1, 30 do emu.frameadvance() end
    end
    moveDirection("Down", 3)
    moveDirection("Left", 4)
    moveDirection("Down", 3)
    for i = 1, 40 do
        pressA(1)
        for j = 1, 30 do emu.frameadvance() end
    end
    
    console.log("Sequência de seleção concluída")
end

local function waitForPokemonLoad()
    local maxWait = 8000
    local waitCount = 0
    
    console.log("Aguardando Pokémon carregar...")
    
    while waitCount < maxWait do
        local partyCount = memory.read_u8(partyCountAddress)
        
        if partyCount > 0 then
            local pokemonData = readPokemonData(0) -- Primeiro slot
            if pokemonData and pokemonData.pid ~= 0 then
                console.log(string.format("Pokémon carregado! Species: %d, PID: 0x%08X", 
                    pokemonData.species, pokemonData.pid))
                return pokemonData
            end
        end
        
        if waitCount % 500 == 0 then
            console.log(string.format("Aguardando... %d/%d frames", waitCount, maxWait))
        end
        
        emu.frameadvance()
        waitCount = waitCount + 1
    end
    
    console.log("Timeout: Pokémon não foi carregado")
    return nil
end

local function readTrainerIDs()
    local tid = memory.read_u16_le(tidAddress)
    local sid = memory.read_u16_le(sidAddress)
    return tid, sid
end

-- Loop principal
local attemptCount = 0

console.log("=== INICIANDO BUSCA POR STARTER SHINY ===")
loadSaveState()

while true do
    attemptCount = attemptCount + 1
    console.log(string.format("=== TENTATIVA %d ===", attemptCount))

    softReset()
    selectCharmanderSequence()

    local pokemonData = waitForPokemonLoad()
    
    if pokemonData then
        local tid, sid = readTrainerIDs()
        local hp, atk, def, spatk, spdef, spd = getIVs(pokemonData.ivData)

        -- Debug na primeira tentativa
        if attemptCount == 1 then
            console.log(string.format("Debug - TID: %d, SID: %d", tid, sid))
            console.log(string.format("PID: 0x%08X, OTID: 0x%08X, Species: %d", 
                pokemonData.pid, pokemonData.otid, pokemonData.species))
        end

        if tid == 0 and sid == 0 then
            console.log("TID/SID não detectados - verifique os endereços")
        elseif isShiny(pokemonData.pid, tid, sid) then
            console.log(string.format(
                "🌟 SHINY ENCONTRADO! 🌟\nTentativa: %d\nPID: 0x%08X\nTID: %d | SID: %d\nIVs: HP:%d Atk:%d Def:%d SpAtk:%d SpDef:%d Spd:%d",
                attemptCount, pokemonData.pid, tid, sid, hp, atk, def, spatk, spdef, spd))
            break
        else
            if attemptCount % 50 == 0 then
                console.log(string.format(
                    "Tentativa %d: Normal - PID: 0x%08X | IVs: HP:%d Atk:%d Def:%d SpAtk:%d SpDef:%d Spd:%d",
                    attemptCount, pokemonData.pid, hp, atk, def, spatk, spdef, spd))
            end
        end
    else
        console.log("Pokémon não carregou a tempo")
    end
end
