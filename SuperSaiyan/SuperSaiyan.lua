-- ============================================================
-- SuperSaiyan.lua
-- Sistema de Ki al estilo Super Saiyan para AzerothCore + mod-ale
-- Autor: mod-ale-scripter (AzerothCore Lua Engine)
-- ============================================================
--
-- INSTALACION:
--   Coloca este archivo en tu carpeta lua_scripts/
--   No requiere SQL ni configuracion adicional.
--
-- USO EN JUEGO:
--   El Ki se acumula al matar, recibir danio y causar danio.
--   Cuando Ki llega a 100 la transformacion se activa AUTOMATICAMENTE.
--   Comandos GM: .saiyan off | .saiyan status | .saiyan reset
--
-- NOTAS TECNICAS:
--   - Transformacion automatica cuando Ki >= KI_MAX
--   - Secuencia cinematografica con emotes y auras escalonadas via CreateLuaEvent
--   - Secuencia de salida con emotes al agotarse el Ki
--   - Usa Unit:PerformEmote(id) y Unit:EmoteState(id) para animaciones
--   - Usa Unit:AddAura() para capas visuales 3D de la transformacion
--   - Timer global de 1 segundo para drenar Ki durante transformacion
--
-- IDs de emote usados (enum Emote de SharedDefines.h):
--   EMOTE_ONESHOT_KNEEL      = 16
--   EMOTE_STATE_KNEEL        = 68
--   EMOTE_ONESHOT_ROAR       = 15
--   EMOTE_ONESHOT_BATTLE_ROAR = 53
--   EMOTE_ONESHOT_SPELL_CAST = 51
--   EMOTE_STATE_STAND        = 26
-- ============================================================

-- ─── AIO — Interfaz de Ki ──────────────────────────────────────
local AIO = AIO or require("AIO")
if AIO.IsMainState and not AIO.IsMainState() then return end

-- ============================================================
-- CONFIGURACION — modificar aqui segun preferencia
-- ============================================================
local CFG = {
    -- Limites de Ki
    KI_MAX              = 100,
    KI_START            = 0,

    -- Ganancias de Ki
    KI_PER_KILL         = 10,   -- al matar una criatura o jugador
    KI_PER_DAMAGE_TAKEN = 5,    -- al recibir danio
    KI_PER_DAMAGE_DEALT = 2,    -- al causar danio (por golpe)

    -- Drenaje durante transformacion (por segundo)
    KI_DRAIN_PER_SECOND = 5,

    -- Cooldown de transformacion en segundos
    TRANSFORM_COOLDOWN  = 60,

    -- Multiplicadores en estado Super Saiyan
    SPEED_MULTIPLIER    = 1.5,  -- velocidad x1.5
    DAMAGE_MULTIPLIER   = 2.0,  -- danio causado x2
    HEAL_MULTIPLIER     = 1.5,  -- curacion recibida x1.5
    STAT_MULTIPLIER     = 10,   -- todas las estadisticas x10 (Fuerza, Agilidad, Resistencia, Intelecto, Espiritu)

    -- Tipo de movimiento para SetSpeed (MOVE_RUN = 1)
    MOVE_RUN            = 1,

    -- Intervalo del timer global en ms (1 segundo)
    TIMER_INTERVAL      = 1000,

    -- Umbral minimo de cambio para mostrar mensaje de Ki al jugador
    -- (evita spam al recibir muchos golpes seguidos)
    KI_MSG_THRESHOLD    = 5,

    -- ------------------------------------------------------------
    -- SPELLS VISUALES DE TRANSFORMACION (capas 3D escalonadas)
    -- Si algun aura no se ve, prueba con .aura <ID> en juego y cambia el valor aqui.
    -- ------------------------------------------------------------
    -- Capa 1 (t=500ms): energia inicial que surge / columna
    AURA_SPELL_SURGE    = 57819,  -- columna de energia ascendente

    -- Capa 2 (t=1000ms): brillo radiante circular
    AURA_SPELL_RADIANT  = 24018,  -- Holy aura circular

    -- Capa 3 (t=1500ms): particulas swirl 3D
    AURA_SPELL_SWIRL    = 34477,  -- particulas orbitales

    -- Auras permanentes combinadas — se re-aplican juntas cada 1 segundo
    AURA_SPELL_POWER    = 20375,  -- Sello de Orden (Seal of Command)

    -- Spell de Consagracion — se lanza al momento de transformarse
    CONSECRATION_SPELL  = 48819,  -- Consagracion rango 8 (el mas alto en WotLK)

    -- Intervalo en ms para re-aplicar ambas auras
    AURA_REFRESH_INTERVAL = 300,

    -- Rayos que caen durante la transformacion
    -- Si no se ven, prueba estos IDs con .aura <ID> en juego y pon el que mas te guste:
    --   51490 = Thunderstorm (tormenta shaman, rayo circular)
    --   48897 = Lightning Bolt rango 11 (rayo directo)
    --   49271 = Chain Lightning rango 7 (rayo en cadena)
    --   26044 = Call Lightning
    --   63494 = Nether Lightning
    --   54531 = Electrical Storm
    LIGHTNING_SPELL_2 = 63494,  -- rayo visual

    -- Efecto Huracan del druida — tormenta de rayos/viento giratorio
    -- Rango 5 (WotLK 3.3.5a) — mejor visual con .aura 48467
    -- Alternativas: 16914 (R1), 17401 (R2), 17402 (R3), 27012 (R4)
    HURRICANE_SPELL   = 16914,  -- Hurricane Rank 1

    -- Terremoto L70ETC — aura de area instantanea de 10 yardas, 4 segundos
    EARTHQUAKE_SPELL  = 42499,  -- L70ETC Earthquake

    -- Equipo de GM equipado durante la transformacion Super Saiyan
    -- Al transformarse se equipa automaticamente y se restaura al salir
    SS_GEAR_HEAD  = 12064,  -- GM Hood    (cabeza) → EQUIP_SLOT_HEAD  = 0
    SS_GEAR_CHEST = 2586,   -- GM Robe    (pecho)  → EQUIP_SLOT_CHEST = 4
    SS_GEAR_FEET  = 11508,  -- GM Slipper (pies)   → EQUIP_SLOT_FEET  = 7

    -- Cabello Super Saiyan — se aplica al transformarse y se restaura al salir
    -- PLAYER_BYTES (campo 153): byte 2 = estilo, byte 3 = color
    --
    -- HUMAN MALE — hair_id verificados desde BarberShopStyle.dbc (Race=1, Sex=0, Type=0):
    --    0 = Calvo           1 = Campesino     2 = Soldado
    --    3 = Monje (fraile)  4 = Barbaro       5 = Gallardo
    --    6 = Suelto          7 = Cortesano     8 = Erudito
    --    9 = Picaron        10 = Divino muerte 11 = Sanson
    --   12 = Principe       13 = DE PUNTA      14 = Hacia atras
    --   15 = Coleta alta    16 = Pegado
    --
    -- HUMAN MALE — indices de color (CharSections, secuencial, verificados en juego):
    --   0 = Negro          1 = Marron oscuro  2 = Marron
    --   3 = Marron claro   4 = Rubio oscuro   5 = RUBIO DORADO
    --   6 = ?              7 = ?              8..12 = otros
    --
    -- SS_HAIR_COLOR      = color durante la transformacion (rubio dorado)
    -- SS_HAIR_COLOR_NORMAL = color fuera de transformacion (negro — color natural)
    SS_HAIR_COLOR        = 5,   -- Rubio dorado (Golden Blonde, verificado en juego)
    SS_HAIR_COLOR_NORMAL = 0,   -- Negro (color natural del personaje fuera de SS)
    SS_HAIR_STYLE        = 13,  -- De punta (Spiky, hair_id=13 verificado en BarberShopStyle.dbc)
}

-- ============================================================
-- ESTADO POR JUGADOR
-- ============================================================
-- Clave: GUIDLow (uint32) del jugador
local playerKi            = {}   -- Ki actual [guidLow] = number (0..KI_MAX)
local playerTransformed   = {}   -- Si esta transformado [guidLow] = bool
local playerCooldown      = {}   -- Timestamp del fin del cooldown [guidLow] = number
local playerLastKiMsg     = {}   -- Ultimo Ki que se mostro en pantalla [guidLow] = number
local playerSequencing    = {}   -- True si la secuencia de transformacion esta en curso [guidLow] = bool
local playerOriginalStats = {}   -- Stats originales antes de x10 [guidLow] = {[0..4]=valor}
local playerOriginalHP    = {}   -- MaxHealth original antes de x10 [guidLow] = number
local playerSavedGear     = {}   -- Equipo original antes de equipar gear GM [guidLow] = {[slot]=entry}
local playerOriginalHair  = {}   -- Cabello original antes del SS [guidLow] = {color=n, style=n}

-- ─── AIO — Enviar estado de Ki al cliente ─────────────────────
local function SendKiUI(player)
    local guid  = player:GetGUIDLow()
    local ki    = playerKi[guid] or 0
    local state = "normal"
    if playerTransformed[guid] then
        state = "transformed"
    elseif playerSequencing[guid] then
        state = "sequencing"
    end
    AIO.Msg():Add("SS_KiUpdate", ki, state):Send(player)
end

-- ============================================================
-- FUNCIONES AUXILIARES
-- ============================================================

-- Multiplica todas las estadisticas x STAT_MULTIPLIER usando HandleStatFlatModifier
-- ESTRATEGIA DE RESTAURACION:
--   En lugar de llamar HandleStatFlatModifier(bonus, false), llamamos
--   HandleStatFlatModifier(-bonus, true). Matematicamente identico, pero evita
--   cualquier problema de conversion booleana en los bindings de mod-ale.
--   C++ hace: modifier += apply ? amount : -amount
--     apply=true,  amount=+bonus  → modifier += +bonus  (aplica)
--     apply=true,  amount=-bonus  → modifier += -bonus  (revierte) ← usamos esto
--     apply=false, amount=+bonus  → modifier += -bonus  (deberia revertir, pero puede fallar)
-- Indices de UNIT_FIELD_STAT en WotLK AzerothCore (UpdateFields.h verificado):
-- OBJECT_END=0x0006=6, offsets: STAT0=0x4E(78), STAT1=0x4F, STAT2=0x50, STAT3=0x51, STAT4=0x52
-- => indices absolutos: 6+78=84, 85, 86, 87, 88
local UNIT_FIELD_STAT_BASE = 84  -- UNIT_FIELD_STAT0; STAT_i = 84+i

local function ApplyStatBoost(player)
    local guid = player:GetGUIDLow()
    -- GUARD: evita apilar el boost si se llama dos veces sin restaurar primero
    if playerOriginalStats[guid] then return end

    playerOriginalStats[guid] = {}
    playerOriginalHP[guid]    = player:GetMaxHealth()

    -- Fuerza=0, Agilidad=1, Resistencia=2, Intelecto=3, Espiritu=4
    for i = 0, 4 do
        local base  = player:GetStat(i)
        local bonus = math.floor(base * (CFG.STAT_MULTIPLIER - 1))
        -- Guardamos AMBOS: el stat original (para SetUInt32Value) y el bonus (para HandleStatFlatModifier)
        playerOriginalStats[guid][i] = { stat = math.floor(base), bonus = bonus }
        player:HandleStatFlatModifier(i, 1, bonus, true)   -- TOTAL_VALUE +bonus
    end

    -- HP x10 garantizado
    local newHP = playerOriginalHP[guid] * CFG.STAT_MULTIPLIER
    player:SetMaxHealth(newHP)
    player:SetHealth(newHP)
end

-- Restaura todas las estadisticas a sus valores originales.
-- Doble mecanismo de restauracion:
--   1) HandleStatFlatModifier con -bonus (apply=true) — limpia el modificador interno
--   2) SetUInt32Value sobre el campo UNIT_FIELD_STAT — fuerza el valor visual correcto
-- Ambos son necesarios: (1) limpia el calculo interno, (2) garantiza el display inmediato.
local function RestoreStats(player)
    local guid = player:GetGUIDLow()
    if not playerOriginalStats[guid] then return end

    for i = 0, 4 do
        local data = playerOriginalStats[guid][i]
        if data then
            -- Metodo 1: revertir el modificador interno con -bonus (evita bug de apply=false)
            if data.bonus and data.bonus > 0 then
                player:HandleStatFlatModifier(i, 1, -data.bonus, true)
            end
            -- Metodo 2: forzar el campo visual directamente al valor original guardado
            player:SetUInt32Value(UNIT_FIELD_STAT_BASE + i, data.stat)
        end
    end
    playerOriginalStats[guid] = nil

    if playerOriginalHP[guid] then
        local origHP = playerOriginalHP[guid]
        player:SetMaxHealth(origHP)
        if player:GetHealth() > origHP then
            player:SetHealth(origHP)
        end
        playerOriginalHP[guid] = nil
    end
end

-- ============================================================
-- GEAR DE SUPER SAIYAN — Equipa equipo GM al transformarse
-- Guarda el equipo original de cada slot para restaurarlo al salir
-- Slots WoW: 0=HEAD, 4=CHEST, 7=FEET
-- ============================================================

-- Tabla de slots ↔ item GM (se inicializa una vez tras cargar CFG)
local SS_GEAR_SLOTS = {
    { slot = 0, entry = CFG.SS_GEAR_HEAD  },   -- GM Hood
    { slot = 4, entry = CFG.SS_GEAR_CHEST },   -- GM Robe
    { slot = 7, entry = CFG.SS_GEAR_FEET  },   -- GM Sandals
}

-- Equipa el equipo GM en los 3 slots.
-- Flujo: destruye el item original del slot (no va a bolsa) → equipa GM directamente.
-- Al salir del SS, los items originales se recrean con AddItem.
-- RemoveItem(entryId, 99) usa DestroyItemCount que busca en equipo + bolsas.
local function EquipSSGear(player)
    local guid = player:GetGUIDLow()
    if playerSavedGear[guid] then return end
    playerSavedGear[guid] = {}

    -- Limpiar residuos de transformaciones anteriores (no deberian existir, pero por seguridad)
    for _, gear in ipairs(SS_GEAR_SLOTS) do
        pcall(function() player:RemoveItem(gear.entry, 99) end)
    end

    for _, gear in ipairs(SS_GEAR_SLOTS) do
        local slot  = gear.slot
        local entry = gear.entry

        pcall(function()
            -- Paso 1: guardar entry del item equipado actualmente y DESTRUIRLO
            -- El item NO va a la bolsa — el slot queda vacio inmediatamente
            local currentItem = player:GetEquippedItemBySlot(slot)
            if currentItem then
                local savedEntry = nil
                pcall(function() savedEntry = currentItem:GetEntry() end)
                if savedEntry then
                    playerSavedGear[guid][slot] = savedEntry
                    player:RemoveItem(currentItem, 1)   -- destruye el item del slot
                end
            end

            -- Paso 2: añadir item GM e introducirlo en el slot (ahora vacio)
            local gmItem = player:AddItem(entry, 1)
            if gmItem then
                player:EquipItem(gmItem, slot)
            end
        end)
    end
end

-- Destruye el equipo GM (equipo + bolsa) y recrea el item original en el slot.
-- AddItem crea una copia nueva del item (entry original, durabilidad completa).
local function UnequipSSGear(player)
    local guid = player:GetGUIDLow()
    if not playerSavedGear[guid] then return end

    for _, gear in ipairs(SS_GEAR_SLOTS) do
        local slot  = gear.slot
        local entry = gear.entry

        pcall(function()
            -- Destruir item GM — DestroyItemCount busca en equipo + todas las bolsas
            player:RemoveItem(entry, 99)

            -- Recrear item original y equiparlo en el slot
            local savedEntry = playerSavedGear[guid][slot]
            if savedEntry then
                local origItem = player:AddItem(savedEntry, 1)
                if origItem then
                    player:EquipItem(origItem, slot)
                end
            end
        end)
    end

    playerSavedGear[guid] = nil
end

-- ============================================================
-- CABELLO SUPER SAIYAN — Cambia el color (y opcionalmente estilo) al rubio dorado
-- PLAYER_BYTES = campo 153  (UNIT_END=148 + offset 5)
--   uint32 layout (little-endian): Skin | (Face<<8) | (HairStyle<<16) | (HairColor<<24)
--   byte 0 = Skin, byte 1 = Face, byte 2 = HairStyle, byte 3 = HairColor
-- Usamos SetUInt32Value para escribir los 4 bytes atomicamente en lugar de
-- SetByteValue x2 (mas fiable para forzar la actualizacion visual del cliente).
-- ============================================================
local PLAYER_BYTES_FIELD = 153  -- UNIT_END(148) + 0x05

-- Aplica el cabello SS (estilo en punta + color rubio).
-- Ya no guardamos el color "original" porque SS_HAIR_COLOR_NORMAL es el color fijo de salida.
local function ApplyHairChange(player)
    local guid = player:GetGUIDLow()
    local pb   = player:GetUInt32Value(PLAYER_BYTES_FIELD)
    local skin  = pb % 256
    local face  = math.floor(pb / 256) % 256
    playerOriginalHair[guid] = { pb = pb }  -- guardamos solo para saber que se cambio el cabello
    local newPB = skin + (face * 256) + (CFG.SS_HAIR_STYLE * 65536) + (CFG.SS_HAIR_COLOR * 16777216)
    player:SetUInt32Value(PLAYER_BYTES_FIELD, newPB)
end

-- Restaura el cabello al estado "normal": estilo SS permanente + color natural (negro).
-- Usa SS_HAIR_COLOR_NORMAL del CFG en lugar del color guardado, por dos razones:
--   1) El color natural es un valor conocido y fijo (siempre negro)
--   2) OnLogout se dispara DESPUES de SaveToDB, asi que cambios hechos ahi no persisten
--      => la logica de "color normal" tambien se aplica en OnLogin como red de seguridad
local function RestoreHair(player)
    local guid = player:GetGUIDLow()
    if not playerOriginalHair[guid] then return end
    local pb   = player:GetUInt32Value(PLAYER_BYTES_FIELD)
    local skin  = pb % 256
    local face  = math.floor(pb / 256) % 256
    local newPB = skin + (face * 256) + (CFG.SS_HAIR_STYLE * 65536) + (CFG.SS_HAIR_COLOR_NORMAL * 16777216)
    player:SetUInt32Value(PLAYER_BYTES_FIELD, newPB)
    playerOriginalHair[guid] = nil
end

-- Fuerza el cabello al estado "normal" directamente sobre el jugador, sin necesitar
-- que playerOriginalHair este inicializado. Usada en OnLogin como correccion de relog.
local function ForceNormalHair(player)
    local pb    = player:GetUInt32Value(PLAYER_BYTES_FIELD)
    local skin  = pb % 256
    local face  = math.floor(pb / 256) % 256
    local newPB = skin + (face * 256) + (CFG.SS_HAIR_STYLE * 65536) + (CFG.SS_HAIR_COLOR_NORMAL * 16777216)
    player:SetUInt32Value(PLAYER_BYTES_FIELD, newPB)
end

-- Envia clima personalizado SOLO al jugador especificado (sin afectar la zona entera)
-- weatherType: 0=despejado, 1=lluvia, 2=nieve, 3=tormenta
-- grade: intensidad 0.0 (nada) a 1.0 (maximo)
-- abrupt: true = cambio inmediato, false = transicion suave
local function SendWeatherToPlayer(player, weatherType, grade, abrupt)
    -- SMSG_WEATHER opcode = 0x2F4 = 756 decimal (WotLK 3.3.5a build 12340)
    -- Estructura: uint32 weatherType | float grade | uint32 soundId | uint8 abrupt
    local packet = CreatePacket(756, 9)
    packet:WriteULong(weatherType)
    packet:WriteFloat(grade)
    packet:WriteULong(0)  -- soundId 0 = sonido por defecto del clima
    packet:WriteUByte(abrupt and 1 or 0)
    player:SendPacket(packet, true)
end

-- Retorna el Ki actual del jugador (inicializa si no existe)
local function GetKi(player)
    local guid = player:GetGUIDLow()
    if not playerKi[guid] then
        playerKi[guid] = CFG.KI_START
    end
    return playerKi[guid]
end

-- Retorna true si el jugador esta en cooldown de transformacion
local function IsInCooldown(player)
    local guid = player:GetGUIDLow()
    if not playerCooldown[guid] then return false end
    local now = os.time()
    return now < playerCooldown[guid]
end

-- Muestra el Ki actual al jugador como mensaje de area trigger (pantalla)

-- Agrega Ki al jugador, con clamping a KI_MAX
-- Retorna true si al agregar este Ki se llega exactamente a KI_MAX (para activar transformacion)
local function AddKi(player, amount)
    local guid = player:GetGUIDLow()
    local current = GetKi(player)

    -- No acumular Ki si ya esta transformado o en secuencia
    if playerTransformed[guid] or playerSequencing[guid] then return false end

    local wasBelow = current < CFG.KI_MAX
    local newKi = math.min(current + amount, CFG.KI_MAX)
    playerKi[guid] = newKi
    SendKiUI(player)

    -- Retornar true si AHORA llego a KI_MAX y antes no estaba ahi
    return wasBelow and (newKi >= CFG.KI_MAX)
end

-- Reduce el Ki del jugador, con clamping a 0
-- Retorna true si el Ki llego a 0
local function DrainKi(player, amount)
    local guid = player:GetGUIDLow()
    local current = playerKi[guid] or 0
    local newKi = math.max(current - amount, 0)
    playerKi[guid] = newKi
    SendKiUI(player)
    return (newKi == 0)
end

-- ============================================================
-- SECUENCIA DE SALIDA — Al terminar transformacion (Ki=0)
-- Usa emotes de agotamiento + remocion de auras
-- ============================================================
local function SequenceSalida(player)
    local guid = player:GetGUIDLow()
    local name = player:GetName()

    -- Verificar que el jugador sigue valido y vivo
    if not player:IsAlive() then return end

    -- t=0ms: emote de agotamiento (herida)
    player:PerformEmote(33)  -- EMOTE_ONESHOT_WOUND

    -- t=600ms: emote de ponerse de pie (solo visual)
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:EmoteState(26)  -- EMOTE_STATE_STAND
    end, 600, 1)

    -- t=1000ms: mensajes al jugador (solo visual)
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:SendBroadcastMessage("|cFF808080[Super Saiyan]|r Ki agotado. La transformacion ha terminado.")
    end, 1000, 1)

    print("[SuperSaiyan] " .. name .. " salio de Super Saiyan (Ki agotado).")
end

-- ============================================================
-- SECUENCIA DE ENTRADA — Al llegar a Ki=100 (automatico)
-- Escalonada con CreateLuaEvent para efecto cinematografico 3D
-- ============================================================
local function SequenceTransformacion(player)
    local guid = player:GetGUIDLow()
    local name = player:GetName()

    -- Marcar como en secuencia para bloquear AddKi y evitar doble trigger
    playerSequencing[guid] = true
    SendKiUI(player)

    -- ══════════════════════════════════════════════════════════════
    -- FASE 1 — DESPERTAR (0-2s)
    -- El Ki empieza a moverse. Lento, pesado, inevitable.
    -- ══════════════════════════════════════════════════════════════

    -- t=0ms: rodilla en tierra — el peso del Ki aplasta al jugador
    player:PerformEmote(16)
    player:SendAreaTriggerMessage("|cFFFFD700Tu Ki ha alcanzado su limite...|r")
    player:PlayDirectSound(31)              -- zumbido electrico inicial
    SendWeatherToPlayer(player, 3, 0.25, false)  -- tormenta debil empieza a formarse

    -- t=800ms: estado kneel bloqueado + Ki comienza a fluir
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:EmoteState(68)
        p:SendBroadcastMessage("|cFF808080[Ki] Algo despierta dentro de ti...|r")
        p:PlayDirectSound(33)               -- Lightning Shield buzz: Ki vibrando
    end, 800, 1)

    -- t=1600ms: HURACAN comienza a canalizar
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:CastSpell(p, CFG.HURRICANE_SPELL, true)
    end, 1600, 1)

    -- ══════════════════════════════════════════════════════════════
    -- FASE 2 — PRIMERA ENERGIA (2.5-6s)
    -- Las capas de aura aparecen cada 2 segundos exactos.
    -- ══════════════════════════════════════════════════════════════

    -- t=2500ms: SURGE — primera capa, energia cruda surge del cuerpo
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.AURA_SPELL_SURGE, p)
        p:SendAreaTriggerMessage("|cFFCCCCCC...el Ki fluye...|r")
        p:PlayDirectSound(1483)             -- Chain Lightning crackle
    end, 2500, 1)

    -- t=4500ms: RADIANT — segunda capa + primer trueno + tormenta sube
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.AURA_SPELL_RADIANT, p)
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
        p:SendAreaTriggerMessage("|cFFFFFF00La energia se acumula... insoportable...|r")
        p:PlayDirectSound(13006)            -- Shaman Thunder: primer trueno
        SendWeatherToPlayer(p, 3, 0.45, false)
    end, 4500, 1)

    -- t=6500ms: SWIRL — tercera capa orbital + terremoto leve + tormenta crece
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.AURA_SPELL_SWIRL, p)
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
        p:SendBroadcastMessage("|cFFFF8800[Ki] El suelo tiembla bajo tu poder...|r")
        p:PlayDirectSound(3090)             -- ThunderClap
        p:PlayDirectSound(1485)             -- EarthquakeCameraShake
        p:AddAura(6524, p)
        p:CastSpell(p, CFG.EARTHQUAKE_SPELL, true)
        SendWeatherToPlayer(p, 3, 0.6, false)
    end, 6500, 1)

    -- ══════════════════════════════════════════════════════════════
    -- FASE 3 — ACELERACION (7.5-11s)
    -- Rayos cada vez mas rapidos. 700ms → 600ms → 500ms entre golpes.
    -- ══════════════════════════════════════════════════════════════

    -- t=7500ms: rayo + aviso de tension
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
        p:SendAreaTriggerMessage("|cFFFF4400Ya no puedes contener este poder!!!|r")
    end, 7500, 1)

    -- t=8200ms: rayo + trueno (700ms desde anterior)
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
        p:PlayDirectSound(13006)
    end, 8200, 1)

    -- t=8900ms: rayo (700ms desde anterior)
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
    end, 8900, 1)

    -- t=9500ms: rayo + terremoto (600ms desde anterior)
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
        p:PlayDirectSound(1485)
        p:AddAura(6524, p)
        p:CastSpell(p, CFG.EARTHQUAKE_SPELL, true)
        SendWeatherToPlayer(p, 3, 0.75, false)
    end, 9500, 1)

    -- t=10100ms: rayo + trueno (600ms desde anterior)
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
        p:PlayDirectSound(13006)
    end, 10100, 1)

    -- t=10600ms: rayo (500ms desde anterior) — EL DESBORDE
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
        p:SendBroadcastMessage("|cFFFF0000[Ki] EL PODER SE DESBORDA!!!|r")
        p:PlayDirectSound(10030)            -- Bloodlust: explosion de Ki
        p:PlayDirectSound(1485)
        p:AddAura(6524, p)
        p:CastSpell(p, CFG.EARTHQUAKE_SPELL, true)
        SendWeatherToPlayer(p, 3, 0.88, false)
    end, 10600, 1)

    -- t=11100ms: rayo (500ms desde anterior)
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
    end, 11100, 1)

    -- t=11600ms: ultimo rayo antes del silencio (500ms desde anterior)
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
    end, 11600, 1)

    -- ══════════════════════════════════════════════════════════════
    -- FASE 4 — CLIMAX (12.3s): El rugido que lo cambia todo
    -- ══════════════════════════════════════════════════════════════

    -- t=12300ms: RUGIDO — pausa dramatica de 700ms tras el ultimo rayo
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:PerformEmote(53)
        p:SendAreaTriggerMessage("|cFFFF2200A  A  A  A  A  A  A  R  R  R  G  G  H  H  !!!|r")
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
        p:PlayDirectSound(13753)            -- ProtoDragonRoar: rugido epico
        p:PlayDirectSound(1485)
        p:AddAura(6524, p)
        p:CastSpell(p, CFG.EARTHQUAKE_SPELL, true)
        SendWeatherToPlayer(p, 3, 1.0, true)  -- tormenta MAXIMA — cambio abrupto
    end, 12300, 1)

    -- ══════════════════════════════════════════════════════════════
    -- FASE 5 — TRANSFORMACION (13.8s): El poder explota hacia afuera
    -- ══════════════════════════════════════════════════════════════

    -- t=13800ms: SUPER SAIYAN — 1.5s exactos despues del rugido
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then
            playerSequencing[guid] = false
            playerTransformed[guid] = false
            return
        end

        playerTransformed[guid] = true
        playerSequencing[guid] = false
        SendKiUI(p)

        p:SetSpeed(CFG.MOVE_RUN, 7.0, true)
        p:CastSpell(p, CFG.AURA_SPELL_POWER, true)
        p:AddAura(CFG.LIGHTNING_SPELL_2, p)
        p:CastSpell(p, CFG.CONSECRATION_SPELL, true)
        p:SetScale(1.15)

        -- Multiplicar todas las estadisticas x10
        ApplyStatBoost(p)

        -- Equipar equipo de GM (guarda el equipo original para restaurarlo al salir)
        EquipSSGear(p)

        -- Cambiar cabello a rubio dorado Super Saiyan
        ApplyHairChange(p)

        p:SendBroadcastMessage("|cFFFFD700[Super Saiyan]|r Tu poder supera todos los limites!")
        p:SendAreaTriggerMessage("|cFF00FFFF~ SUPER SAIYAN ACTIVADO ~|r")
        p:PlayDirectSound(7315)             -- Infernal Impact: boom de nacimiento
        p:PlayDirectSound(17741)            -- CC Earthquake: explosion final
        p:AddAura(6524, p)
        p:CastSpell(p, CFG.EARTHQUAKE_SPELL, true)
        SendWeatherToPlayer(p, 0, 0.0, true)  -- el cielo se despeja — el poder absorbe la tormenta
    end, 13800, 1)

    -- t=15000ms: anuncio global — 1.2s despues de la transformacion
    CreateLuaEvent(function(e)
        SendWorldMessage("|cFFFFD700[Super Saiyan]|r |cFF00FF00" .. name .. "|r SE HA TRANSFORMADO EN |cFFFFD700SUPER SAIYAN|r!")
    end, 15000, 1)

    -- t=16500ms: pose de combate — 1.5s despues del anuncio
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsAlive() then return end
        p:EmoteState(26)
    end, 16500, 1)

    print("[SuperSaiyan] " .. name .. " inicio secuencia de transformacion (GUID: " .. guid .. ")")
end

-- ============================================================
-- Cancela la transformacion del jugador (bypass de secuencia — cancelacion manual)
-- ============================================================
local function CancelTransformation(player, reason)
    local guid = player:GetGUIDLow()

    if not playerTransformed[guid] then return end

    local name = player:GetName()

    -- Marcar como no transformado
    playerTransformed[guid] = false
    SendKiUI(player)

    -- Restaurar velocidad normal
    player:SetSpeed(CFG.MOVE_RUN, 1.0, true)

    -- Restaurar estadisticas originales
    RestoreStats(player)

    -- Remover equipo GM y restaurar equipo original
    UnequipSSGear(player)

    -- Restaurar cabello original
    RestoreHair(player)

    -- Remover TODAS las auras visuales
    player:RemoveAura(CFG.AURA_SPELL_SURGE)
    player:RemoveAura(CFG.AURA_SPELL_RADIANT)
    player:RemoveAura(CFG.AURA_SPELL_SWIRL)
    player:RemoveAura(CFG.AURA_SPELL_POWER)

    player:RemoveAura(CFG.LIGHTNING_SPELL_2)

    -- Restaurar escala normal
    player:SetScale(1.0)

    -- Limpiar clima — cielo despejado al salir del SS
    SendWeatherToPlayer(player, 0, 0.0, true)

    -- Restaurar emote state a normal
    player:EmoteState(26)  -- EMOTE_STATE_STAND

    -- Mensaje al jugador
    local msg = reason or "La transformacion ha terminado."
    player:SendBroadcastMessage("|cFF808080[Super Saiyan]|r " .. msg)

    print("[SuperSaiyan] " .. name .. " salio de Super Saiyan (" .. msg .. ")")
end

-- Reinicia completamente el estado de un jugador
local function ResetPlayer(player)
    local guid = player:GetGUIDLow()

    -- Cancelar transformacion si esta activa
    if playerTransformed[guid] then
        CancelTransformation(player, "Estado reiniciado.")
    end

    -- Limpiar flag de secuencia si estaba en curso
    playerSequencing[guid] = false

    playerKi[guid]         = 0
    playerTransformed[guid] = false
    playerCooldown[guid]   = nil
    playerLastKiMsg[guid]  = -1

    SendKiUI(player)
    player:SendBroadcastMessage("|cFF808080[Super Saiyan]|r Tu Ki ha sido reiniciado.")
end

-- ============================================================
-- TIMER GLOBAL — 1 segundo
-- Drena el Ki de todos los jugadores transformados
-- ============================================================
local function OnGlobalTimer(event)
    local players = GetPlayersInWorld()
    if not players then return end

    for _, player in pairs(players) do
        if player and player:IsAlive() then
            local guid = player:GetGUIDLow()

            if playerTransformed[guid] then
                -- Drenar Ki
                local reached_zero = DrainKi(player, CFG.KI_DRAIN_PER_SECOND)

                -- Si llego a 0, activar secuencia de salida
                if reached_zero then
                    -- Marcar como no transformado antes de la secuencia
                    playerTransformed[guid] = false

                    -- Restaurar stats INMEDIATAMENTE (sin delays) para garantizar que no queden activos
                    player:SetSpeed(CFG.MOVE_RUN, 1.0, true)
                    player:SetScale(1.0)
                    RestoreStats(player)
                    UnequipSSGear(player)
                    RestoreHair(player)
                    player:RemoveAura(CFG.AURA_SPELL_SURGE)
                    player:RemoveAura(CFG.AURA_SPELL_RADIANT)
                    player:RemoveAura(CFG.AURA_SPELL_SWIRL)
                    player:RemoveAura(CFG.AURA_SPELL_POWER)
                    player:RemoveAura(CFG.LIGHTNING_SPELL_2)

                    -- Limpiar clima al agotarse el Ki
                    SendWeatherToPlayer(player, 0, 0.0, true)

                    -- Secuencia visual de salida (emotes, mensajes) — solo visual
                    SequenceSalida(player)
                    SendKiUI(player)
                end
            end
        end
    end
end

-- Registrar timer global que se repite cada segundo (0 = infinito)
CreateLuaEvent(OnGlobalTimer, CFG.TIMER_INTERVAL, 0)

-- ============================================================
-- TIMER DE AURA — 100ms
-- Re-aplica el aura dorada en todos los jugadores transformados
-- Timer separado para no interferir con el drain de Ki (1 seg)
-- ============================================================
local function OnAuraTimer(event)
    local players = GetPlayersInWorld()
    if not players then return end

    for _, player in pairs(players) do
        if player and player:IsAlive() then
            local guid = player:GetGUIDLow()
            if playerTransformed[guid] then
                -- Renovar sellos + rayos + huracan persistentes cada AURA_REFRESH_INTERVAL
                player:CastSpell(player, CFG.AURA_SPELL_POWER, true)

                player:AddAura(CFG.LIGHTNING_SPELL_2, player)
            end
        end
    end
end

CreateLuaEvent(OnAuraTimer, CFG.AURA_REFRESH_INTERVAL, 0)

-- ============================================================
-- HOOK: OnKillCreature — +10 Ki al matar criatura
-- ============================================================
local function OnKillCreature(event, killer, killed)
    if not killer or not killer:IsAlive() then return end

    local reached_max = AddKi(killer, CFG.KI_PER_KILL)

    -- Activar transformacion automaticamente si llego a Ki_MAX
    if reached_max and not IsInCooldown(killer) then
        SequenceTransformacion(killer)
    end
end

AIO.AddAddon("lua_scripts/SuperSaiyan_client.lua", "SuperSaiyanUI")

RegisterPlayerEvent(7, OnKillCreature)

-- ============================================================
-- HOOK: OnKillPlayer — +10 Ki al matar otro jugador
-- ============================================================
local function OnKillPlayer(event, killer, killed)
    if not killer or not killer:IsAlive() then return end

    local reached_max = AddKi(killer, CFG.KI_PER_KILL)

    -- Activar transformacion automaticamente si llego a Ki_MAX
    if reached_max and not IsInCooldown(killer) then
        SequenceTransformacion(killer)
    end
end

RegisterPlayerEvent(6, OnKillPlayer)

-- ============================================================
-- HOOK: OnDealDamage — +2 Ki al causar danio (cada golpe)
-- Tambien aplica el multiplicador de danio x2 si esta transformado
-- Firma: (event, player, target, damage, damagetype)
-- ============================================================
local function OnDealDamage(event, player, target, damage, damagetype)
    if not player or not player:IsAlive() then return end

    local guid = player:GetGUIDLow()

    -- Ganar Ki por causar danio (solo si no esta transformado ni en secuencia)
    if not playerTransformed[guid] and not playerSequencing[guid] then
        local reached_max = AddKi(player, CFG.KI_PER_DAMAGE_DEALT)

        -- Activar transformacion automaticamente si llego a Ki_MAX
        if reached_max and not IsInCooldown(player) then
            SequenceTransformacion(player)
        end
    end

    -- Si esta transformado, multiplicar el danio causado x2
    if playerTransformed[guid] then
        local newDamage = math.floor(damage * CFG.DAMAGE_MULTIPLIER)
        return newDamage
    end
end

RegisterPlayerEvent(72, OnDealDamage)

-- ============================================================
-- HOOK: OnDamage (danio RECIBIDO) — +5 Ki al recibir danio
-- Firma: (event, player, target, damage)
-- ============================================================
local function OnDamageReceived(event, player, attacker, damage)
    if not player or not player:IsAlive() then return end

    local guid = player:GetGUIDLow()

    -- Ganar Ki al recibir danio (solo si no esta transformado ni en secuencia)
    if not playerTransformed[guid] and not playerSequencing[guid] then
        local reached_max = AddKi(player, CFG.KI_PER_DAMAGE_TAKEN)

        -- Activar transformacion automaticamente si llego a Ki_MAX
        if reached_max and not IsInCooldown(player) then
            SequenceTransformacion(player)
        end
    end
end

RegisterPlayerEvent(66, OnDamageReceived)

-- ============================================================
-- HOOK: OnModifyHealReceived — x1.5 curacion si transformado
-- Firma: (event, player, target, heal, spellInfo)
-- ============================================================
local function OnModifyHealReceived(event, player, target, heal, spellInfo)
    if not player or not player:IsAlive() then return end

    local guid = player:GetGUIDLow()

    if playerTransformed[guid] then
        local newHeal = math.floor(heal * CFG.HEAL_MULTIPLIER)
        return newHeal
    end
end

RegisterPlayerEvent(71, OnModifyHealReceived)

-- ============================================================
-- HOOK: OnLogin — inicializar estado + limpiar items GM residuales
-- Se dispara mientras el jugador ya esta cargado pero aun no visible
-- ============================================================
local function OnLogin(event, player)
    local guid = player:GetGUIDLow()

    -- Limpiar toda traza de transformacion anterior (por si el Logout no alcanzo)
    playerTransformed[guid]   = false
    playerSequencing[guid]    = false
    playerOriginalStats[guid] = nil
    playerOriginalHP[guid]    = nil
    playerSavedGear[guid]     = nil
    playerOriginalHair[guid]  = nil
    playerLastKiMsg[guid]     = -1
    if not playerKi[guid] then
        playerKi[guid] = CFG.KI_START
    end

    -- Red de seguridad: eliminar items GM que hayan quedado equipados/en bolsa
    -- (DestroyItemCount los busca en equipo + todas las bolsas)
    for _, gear in ipairs(SS_GEAR_SLOTS) do
        pcall(function() player:RemoveItem(gear.entry, 99) end)
    end

    -- Correccion post-relog: cabello y auras
    -- OnLogout se dispara DESPUES de SaveToDB, asi que los cambios hechos ahi
    -- no persisten en la BD. Los corregimos aqui en OnLogin, que ocurre ANTES
    -- del siguiente SaveToDB y por tanto SI se persisten en el proximo logout.

    -- 1) Cabello: si tiene el color SS (rubio), revertir al color normal (negro)
    local pb           = player:GetUInt32Value(PLAYER_BYTES_FIELD)
    local currentColor = math.floor(pb / 16777216) % 256
    if currentColor == CFG.SS_HAIR_COLOR then
        ForceNormalHair(player)
    end

    -- 2) Auras SS: las auras se guardan en character_aura, quitarlas al conectar
    player:RemoveAura(CFG.AURA_SPELL_SURGE)
    player:RemoveAura(CFG.AURA_SPELL_RADIANT)
    player:RemoveAura(CFG.AURA_SPELL_SWIRL)
    player:RemoveAura(CFG.AURA_SPELL_POWER)
    player:RemoveAura(CFG.LIGHTNING_SPELL_2)
    player:RemoveAura(6524)  -- aura visual final de transformacion

    player:SendBroadcastMessage("|cFFFFD700[Super Saiyan]|r Sistema de Ki activo. Acumula Ki en combate.")
    player:SendBroadcastMessage("|cFFFFD700[Super Saiyan]|r Al llegar a 100 Ki la transformacion se activara automaticamente!")

    SendKiUI(player)
end

RegisterPlayerEvent(3, OnLogin)

-- ============================================================
-- HOOK: OnLogout — restaurar gear/stats/cabello antes de desconectar
-- El jugador AUN esta en el mundo cuando este hook se dispara:
-- las operaciones de item funcionan y se guardan en la BD.
-- ============================================================
local function OnLogout(event, player)
    local guid = player:GetGUIDLow()

    -- Si estaba transformado o con gear/stats alterados, restaurar TODO ahora
    -- Es seguro llamar las funciones de restauracion — el jugador sigue accesible
    if playerTransformed[guid] or playerSavedGear[guid] or playerOriginalStats[guid] then
        RestoreStats(player)      -- revierte stats x10 al original
        UnequipSSGear(player)     -- destruye items GM y recrea el equipo original
        RestoreHair(player)       -- mantiene estilo SS pero revierte color a negro
        player:SetSpeed(CFG.MOVE_RUN, 1.0, true)  -- restaurar velocidad
        player:RemoveAura(CFG.AURA_SPELL_POWER)
        player:RemoveAura(CFG.AURA_SPELL_SURGE)
        player:RemoveAura(CFG.AURA_SPELL_RADIANT)
        player:RemoveAura(CFG.AURA_SPELL_SWIRL)
        player:RemoveAura(CFG.LIGHTNING_SPELL_2)
        player:SetScale(1.0)
    end

    -- Limpiar memoria (ya no hacen falta — el jugador se va)
    playerKi[guid]            = nil
    playerTransformed[guid]   = nil
    playerCooldown[guid]      = nil
    playerLastKiMsg[guid]     = nil
    playerSequencing[guid]    = nil
    playerOriginalStats[guid] = nil
    playerOriginalHP[guid]    = nil
    playerSavedGear[guid]     = nil
    playerOriginalHair[guid]  = nil

    print("[SuperSaiyan] Estado restaurado y limpiado para GUID: " .. guid)
end

RegisterPlayerEvent(4, OnLogout)

-- ============================================================
-- HOOK: OnRepop — al morir: cancelar transformacion + resetear Ki
-- ============================================================
local function OnRepop(event, player)
    local guid = player:GetGUIDLow()
    local name = player:GetName()

    -- Limpiar flag de secuencia
    playerSequencing[guid] = false

    -- Cancelar efectos visuales si esta transformado
    if playerTransformed[guid] then
        pcall(function()
            player:RemoveAura(CFG.AURA_SPELL_SURGE)
            player:RemoveAura(CFG.AURA_SPELL_RADIANT)
            player:RemoveAura(CFG.AURA_SPELL_SWIRL)
            player:RemoveAura(CFG.AURA_SPELL_POWER)

    player:RemoveAura(CFG.LIGHTNING_SPELL_2)
            player:SetScale(1.0)
        end)
        RestoreStats(player)
        UnequipSSGear(player)
        RestoreHair(player)
        playerTransformed[guid] = false
    end

    -- Resetear Ki a 0 y LIMPIAR cooldown: el Ki va a 0, el jugador tendra que
    -- ganarlo desde cero para transformarse de nuevo — no necesita cooldown adicional.
    playerKi[guid]          = 0
    playerLastKiMsg[guid]   = -1
    playerCooldown[guid]    = nil   -- sin cooldown post-muerte: Ki=0 ya es suficiente penalizacion

    player:SendBroadcastMessage("|cFFFF0000[Super Saiyan]|r Has muerto. Tu Ki se ha perdido completamente.")

    print("[SuperSaiyan] " .. name .. " murio, Ki reiniciado a 0.")
end

RegisterPlayerEvent(35, OnRepop)

-- ============================================================
-- HOOK: OnCommand — comandos de control (.saiyan off/status/reset)
-- El comando ".saiyan" para activar YA NO EXISTE — es automatico.
-- Firma: (event, player, command, chatHandler)
-- Retornar false = interceptar el comando (no mostrarlo en chat)
-- ============================================================
local function OnCommand(event, player, command, chatHandler)
    if not player then return end  -- puede ser nil si es consola

    -- Comando: .saiyan on — forzar transformacion para testing (sube Ki a 100 y activa)
    if command == "saiyan on" then
        local guid = player:GetGUIDLow()
        if playerTransformed[guid] or playerSequencing[guid] then
            player:SendBroadcastMessage("|cFFFFD700[Super Saiyan]|r Ya estas transformado o en secuencia.")
            return false
        end
        -- Saltar cooldown y forzar Ki a 100
        playerCooldown[guid] = nil
        playerKi[guid] = CFG.KI_MAX
        player:SendBroadcastMessage("|cFFFFD700[Super Saiyan]|r [TEST] Ki forzado a 100 — activando transformacion...")
        SequenceTransformacion(player)
        return false

    -- Comando: .saiyan — info
    elseif command == "saiyan" then
        player:SendBroadcastMessage("|cFFFFD700[Super Saiyan] Comandos:|r")
        player:SendBroadcastMessage("  .saiyan on        — forzar transformacion (test)")
        player:SendBroadcastMessage("  .saiyan off       — cancelar transformacion")
        player:SendBroadcastMessage("  .saiyan status    — ver Ki y estado")
        player:SendBroadcastMessage("  .saiyan reset     — reiniciar Ki a 0")
        player:SendBroadcastMessage("  .saiyan hair      — mostrar color/estilo actuales")
        player:SendBroadcastMessage("  .saiyan hair <N>  — probar color N (0-12)")
        return false

    -- Comando: .saiyan reset — resetear Ki (acceso publico, util para testing)
    elseif command == "saiyan reset" then
        ResetPlayer(player)
        return false

    -- Comando: .saiyan status — ver estado actual
    elseif command == "saiyan status" then
        local guid = player:GetGUIDLow()
        local ki   = playerKi[guid] or 0
        local transformed = playerTransformed[guid] or false
        local sequencing  = playerSequencing[guid]  or false
        local cdLeft = 0
        if playerCooldown[guid] then
            cdLeft = math.max(0, playerCooldown[guid] - os.time())
        end

        player:SendBroadcastMessage("|cFFFFD700[Super Saiyan] Status:|r")
        player:SendBroadcastMessage("  Ki: " .. ki .. "/" .. CFG.KI_MAX)
        player:SendBroadcastMessage("  Transformado: " .. (transformed and "SI" or "NO"))
        player:SendBroadcastMessage("  Secuencia activa: " .. (sequencing and "SI" or "NO"))
        player:SendBroadcastMessage("  Cooldown restante: " .. cdLeft .. " seg")
        return false

    -- Comando: .saiyan off — desactivar transformacion manualmente
    elseif command == "saiyan off" then
        local guid = player:GetGUIDLow()
        if playerTransformed[guid] then
            CancelTransformation(player, "Transformacion desactivada manualmente.")
        elseif playerSequencing[guid] then
            -- Interrumpir secuencia en curso
            playerSequencing[guid] = false
            player:RemoveAura(CFG.AURA_SPELL_SURGE)
            player:RemoveAura(CFG.AURA_SPELL_RADIANT)
            player:RemoveAura(CFG.AURA_SPELL_SWIRL)
            player:RemoveAura(CFG.AURA_SPELL_POWER)
            player:RemoveAura(CFG.LIGHTNING_SPELL_2)
            player:SetScale(1.0)
            player:EmoteState(26)  -- EMOTE_STATE_STAND
            player:SendBroadcastMessage("|cFF808080[Super Saiyan]|r Secuencia de transformacion interrumpida.")
        else
            player:SendBroadcastMessage("|cFF808080[Super Saiyan]|r No estas transformado.")
        end
        return false

    -- Comando: .saiyan hair <N> — probar un color de cabello en vivo (0-12 para Human Male)
    -- Uso: .saiyan hair 5   (aplica color 5, escribe el numero para ver el resultado)
    elseif string.sub(command, 1, 11) == "saiyan hair" then
        local numStr = string.match(command, "saiyan hair%s+(%d+)")
        if numStr then
            local colorIdx = tonumber(numStr)
            local pb  = player:GetUInt32Value(PLAYER_BYTES_FIELD)
            local skin = pb % 256
            local face = math.floor(pb / 256) % 256
            local sty  = math.floor(pb / 65536) % 256
            local newPB = skin + (face * 256) + (sty * 65536) + (colorIdx * 16777216)
            player:SetUInt32Value(PLAYER_BYTES_FIELD, newPB)
            player:SendBroadcastMessage(string.format(
                "|cFFFFD700[SS-test] Color de cabello -> %d (edita SS_HAIR_COLOR=%d en CFG cuando encuentres el rubio)|r",
                colorIdx, colorIdx))
        else
            -- Mostrar color actual
            local pb    = player:GetUInt32Value(PLAYER_BYTES_FIELD)
            local style = math.floor(pb / 65536) % 256
            local color = math.floor(pb / 16777216) % 256
            player:SendBroadcastMessage(string.format(
                "|cFFFFD700[SS] PLAYER_BYTES: skin=%d face=%d style=%d color=%d|r",
                pb % 256, math.floor(pb/256)%256, style, color))
            player:SendBroadcastMessage("|cFFFFFF00[SS] Uso: .saiyan hair <0-12>  para probar colores|r")
        end
        return false
    end
    -- No interceptar otros comandos
end

RegisterPlayerEvent(42, OnCommand)

-- ============================================================
-- CLEANUP DE RELOAD
-- Se ejecuta cada vez que el script se carga (.reload ale o arranque).
-- Detecta jugadores con efectos SS activos (aura o velocidad alta)
-- y los restaura aunque no existan datos en las tablas de estado.
-- ============================================================
local function CleanupOnReload()
    local players = GetPlayersInWorld()
    if not players then return end

    for _, player in pairs(players) do
        if not player or not player:IsInWorld() then goto skip end

        local guid = player:GetGUIDLow()

        -- Detectar estado SS por velocidad: SS pone 7.0x, ningun buff legitimo supera 4x
        local wasTransformed = player:GetSpeed(CFG.MOVE_RUN) >= 5.0

        if wasTransformed then
            -- Velocidad y escala
            player:SetSpeed(CFG.MOVE_RUN, 1.0, true)
            player:SetScale(1.0)

            -- Remover todas las auras SS
            player:RemoveAura(CFG.AURA_SPELL_SURGE)
            player:RemoveAura(CFG.AURA_SPELL_RADIANT)
            player:RemoveAura(CFG.AURA_SPELL_SWIRL)
            player:RemoveAura(CFG.AURA_SPELL_POWER)
            player:RemoveAura(CFG.LIGHTNING_SPELL_2)
            player:RemoveAura(6524)

            -- Restaurar stats sin los datos originales:
            -- boost = stat_base * (STAT_MULTIPLIER - 1), por lo tanto
            -- original = current / STAT_MULTIPLIER
            -- revertir = -bonus = -(current - current/STAT_MULTIPLIER)
            for i = 0, 4 do
                local cur    = player:GetStat(i)
                local orig   = math.floor(cur / CFG.STAT_MULTIPLIER)
                local bonus  = cur - orig
                if bonus > 0 then
                    player:HandleStatFlatModifier(i, 1, -bonus, true)
                    player:SetUInt32Value(UNIT_FIELD_STAT_BASE + i, orig)
                end
            end

            -- Restaurar HP (dividir por multiplicador)
            local curMaxHP = player:GetMaxHealth()
            local origMaxHP = math.floor(curMaxHP / CFG.STAT_MULTIPLIER)
            if origMaxHP > 0 then
                player:SetMaxHealth(origMaxHP)
                if player:GetHealth() > origMaxHP then
                    player:SetHealth(origMaxHP)
                end
            end

            -- Limpiar equipo SS
            for _, gear in ipairs(SS_GEAR_SLOTS) do
                pcall(function() player:RemoveItem(gear.entry, 99) end)
            end

            -- Restaurar cabello
            pcall(function() ForceNormalHair(player) end)

            -- Limpiar clima
            SendWeatherToPlayer(player, 0, 0.0, true)

            -- Emote normal
            player:EmoteState(26)

            player:SendBroadcastMessage("|cFFFF8000[Super Saiyan]|r Sistema recargado. Estado Super Saiyan restaurado.")
            print("[SuperSaiyan] CleanupOnReload: " .. player:GetName() .. " restaurado desde estado SS.")
        end

        -- Reiniciar tablas de estado para este jugador
        playerKi[guid]            = playerKi[guid] or CFG.KI_START
        playerTransformed[guid]   = false
        playerSequencing[guid]    = false
        playerOriginalStats[guid] = nil
        playerOriginalHP[guid]    = nil
        playerCooldown[guid]      = nil
        playerLastKiMsg[guid]     = -1

        ::skip::
    end
end

CleanupOnReload()

-- ============================================================
-- LOG de inicio
-- ============================================================
print("[SuperSaiyan] Sistema de Ki Super Saiyan cargado correctamente.")
print("[SuperSaiyan] Transformacion AUTOMATICA al llegar a Ki=" .. CFG.KI_MAX)
print("[SuperSaiyan] Comandos: .saiyan off | .saiyan status | .saiyan reset")
print("[SuperSaiyan] Configuracion: KI_MAX=" .. CFG.KI_MAX .. " | DRAIN=" .. CFG.KI_DRAIN_PER_SECOND .. "/seg | CD=" .. CFG.TRANSFORM_COOLDOWN .. "seg")

-- ============================================================
-- ============================================================
-- SISTEMA SHENLONG — Resurreccion cinematografica Dragon Ball
-- ============================================================
-- Cuando el jugador muere, la Val'kyr aparece volando sobre
-- el lugar de muerte, lanza un dialogo epico y resucita al
-- jugador con una secuencia escalonada via CreateLuaEvent.
--
-- Hook usado: PLAYER_EVENT_ON_REPOP (35) — cubre TODAS las
-- formas de muerte (por criatura, jugador, caida, etc.).
-- Nota: PLAYER_EVENT_ON_KILLED_BY_CREATURE (8) solo dispara
-- cuando el asesino es una criatura; no cubre muerte PvP.
--
-- Metodo SpawnCreature: WorldObject:SpawnCreature(entry, x, y, z, o, despawnTimer)
-- El NPC se genera directamente sobre el jugador caido.
--
-- NOTAS:
--   - Si el dragon no puede spawnearse, el jugador se resucita
--     directamente como fallback sin secuencia cinematografica.
--   - Al morir en cooldown la muerte es completamente normal
--     (sin interferencia de este sistema).
-- ============================================================

-- ============================================================
-- CONFIGURACION SHENLONG
-- ============================================================
local CFG_SH = {
    -- NPC que aparece al morir:
    --   29528 = Val'kyr Shadowguard (ICC) — alas, vuela, muy epica  ← ACTIVO
    --    6491 = Spirit Healer (Alliance) — fantasma blanco clasico
    --   13116 = Spirit Healer (Horde)
    NPC_ENTRY      = 38392,    -- Val'kyr
    COOLDOWN       = 300,      -- segundos entre resurrecciones (5 min)
    HEALTH_PCT     = 30,       -- % de vida al resucitar
    SPAWN_Z_OFFSET = 3,        -- metros sobre el jugador al aparecer (mas cerca)
    SPAWN_SCALE    = 3.0,      -- tamaño de la Val'kyr (1.0 = normal, 3.0 = grande)
    AURA_DRAGON    = 24018,    -- aura de luz sagrada sobre la Val'kyr
    AURA_REVIVE    = 24018,    -- aura de luz aplicada al jugador al resucitar
    SPELL_REVIVE_FLASH = 7328, -- Redemption: destello dorado de resurreccion (igual al BG)
}

-- ============================================================
-- ESTADO SHENLONG — tabla de cooldowns por jugador
-- ============================================================
-- Clave: GUIDLow (uint32) | Valor: timestamp fin de cooldown (os.time())
local shenlongCD = {}

-- ============================================================
-- SECUENCIA CINEMATOGRAFICA SHENLONG
-- Todos los callbacks usan GetPlayerByGUID(guid) para re-obtener
-- el jugador en cada etapa — nunca se captura player en closure.
-- ============================================================
local function SequenciaValkyr(guid, x, y, z, o, mapId)
    -- t=0ms: mensaje inmediato al jugador (accion sincronizada con la muerte)
    local p0 = GetPlayerByGUID(guid)
    if p0 then
        p0:SendBroadcastMessage("|cFFFFFFFF...La Luz convoca a las Val'kyr...|r")
    end

    -- t=1500ms: spawnear el dragon sobre la posicion de muerte
    CreateLuaEvent(function(e)
        local p = GetPlayerByGUID(guid)
        if not p then return end

        -- Spawnear Val'kyr sobre la posicion de muerte del jugador
        -- WorldObject:SpawnCreature(entry, x, y, z, o, spawnType, despawnTimer_ms)
        -- spawnType 3 = TEMPSUMMON_TIMED_DESPAWN — se despawnea sola a los 15 seg sin llamar nada
        local dragon = p:SpawnCreature(CFG_SH.NPC_ENTRY, x, y, z + CFG_SH.SPAWN_Z_OFFSET, o, 3, 15000)

        if not dragon then
            -- Fallback: no se pudo spawnear, resucitar directamente
            p:ResurrectPlayer(CFG_SH.HEALTH_PCT / 100, false)
            p:AddAura(CFG_SH.AURA_REVIVE, p)
            p:SendBroadcastMessage("|cFFFFFFFF[Val'kyr]|r La Luz te devuelve a los vivos...")
            print("[Valkyr] Fallback: NPC no pudo spawnearse para GUID " .. guid)
            return
        end

        -- Val'kyr amistosa, pasiva, grande y cerca del jugador
        pcall(function() dragon:SetFaction(35) end)
        pcall(function() dragon:SetReactState(2) end)  -- 2 = REACT_PASSIVE
        pcall(function() dragon:SetScale(CFG_SH.SPAWN_SCALE) end)
        pcall(function() dragon:AddAura(CFG_SH.AURA_DRAGON, dragon) end)

        -- Nota: 'dragon' queda capturado como upvalue de los closures anidados.
        -- No existe GetCreatureByGUID() en mod-ale, asi que se usa el upvalue directamente.
        -- El objeto es valido hasta que DespawnOrUnsummon() lo elimina en el ultimo callback.

        print("[Valkyr] NPC spawneado en (" .. x .. ", " .. y .. ", " .. (z + CFG_SH.SPAWN_Z_OFFSET) .. ") para GUID " .. guid)

        -- helper local: envia el dialogo como burbuja del NPC Y directo al jugador muerto
        local function Decir(texto, delay)
            CreateLuaEvent(function(e2)
                -- Burbuja visible para jugadores vivos cercanos
                pcall(function() dragon:SendUnitSay(texto, 0) end)
                -- Mensaje directo al jugador (lo ve aunque sea fantasma)
                local p2 = GetPlayerByGUID(guid)
                if p2 then
                    p2:SendBroadcastMessage("|cFFFFFFFF[Val'kyr]|r " .. texto)
                end
            end, delay, 1)
        end

        Decir("Guerrero caido... tu alma llama a las sirvientas de la Luz.", 1000)
        Decir("Has caido en batalla... pero tu destino no termina aqui.", 3000)
        Decir("Aun tienes batallas por librar... tu poder no puede apagarse.", 5000)

        -- t=7000ms: cuarto dialogo + emote
        CreateLuaEvent(function(e2)
            pcall(function() dragon:SendUnitSay("La Luz te concede una segunda oportunidad...", 0) end)
            local p2 = GetPlayerByGUID(guid)
            if p2 then p2:SendBroadcastMessage("|cFFFFFFFF[Val'kyr]|r La Luz te concede una segunda oportunidad...") end
            pcall(function() dragon:PerformEmote(53) end)
        end, 7000, 1)

        -- t=9000ms: quinto dialogo + emote final
        CreateLuaEvent(function(e2)
            pcall(function() dragon:SendUnitSay("¡LEVANTATE, GUERRERO! ¡LA LUZ TE DEVUELVE A LOS VIVOS!", 0) end)
            local p2 = GetPlayerByGUID(guid)
            if p2 then p2:SendBroadcastMessage("|cFFFFFFFF[Val'kyr]|r |cFFFFD700¡LEVANTATE, GUERRERO! ¡LA LUZ TE DEVUELVE A LOS VIVOS!|r") end
            pcall(function() dragon:PerformEmote(53) end)
        end, 9000, 1)

        -- t=10500ms: resucitar al jugador con destello de luz
        CreateLuaEvent(function(e2)
            local p2 = GetPlayerByGUID(guid)
            if not p2 then return end
            p2:ResurrectPlayer(CFG_SH.HEALTH_PCT / 100, false)
            p2:CastSpell(p2, CFG_SH.SPELL_REVIVE_FLASH, true)
            p2:AddAura(CFG_SH.AURA_REVIVE, p2)
            p2:SendAreaTriggerMessage("La Val'kyr te ha devuelto la vida. (" .. CFG_SH.HEALTH_PCT .. "% vida)")
            print("[Valkyr] Jugador GUID " .. guid .. " resucitado por Val'kyr.")
        end, 10500, 1)

        -- t=12500ms: despedida final
        CreateLuaEvent(function(e2)
            pcall(function() dragon:SendUnitSay("Que la Luz guie tu camino... hasta la proxima batalla.", 0) end)
            local p2 = GetPlayerByGUID(guid)
            if p2 then p2:SendBroadcastMessage("|cFFFFFFFF[Val'kyr]|r Que la Luz guie tu camino... hasta la proxima batalla.") end
            print("[Valkyr] Secuencia completada para GUID " .. guid)
        end, 12500, 1)
    end, 1500, 1)
end

-- ============================================================
-- HOOK: OnRepop — se dispara con CUALQUIER tipo de muerte
-- PLAYER_EVENT_ON_REPOP (35) — firma: (event, player)
-- ============================================================
local function DispararValkyr(player)
    local guid    = tostring(player:GetGUID())  -- convertir a string para evitar error de concatenacion
    local guidLow = player:GetGUIDLow()
    local x = player:GetX()
    local y = player:GetY()
    local z = player:GetZ()
    local o = player:GetO()
    local mapId = player:GetMapId()

    shenlongCD[guidLow] = os.time() + CFG_SH.COOLDOWN

    print("[Valkyr] Secuencia iniciada para " .. player:GetName() ..
          " en mapa " .. mapId .. " pos=(" .. x .. ", " .. y .. ", " .. z .. ")")

    SequenciaValkyr(guid, x, y, z, o, mapId)
end

local function OnValkyr(event, player)
    if not player then return end

    local guidLow = player:GetGUIDLow()
    local now = os.time()

    print("[Valkyr] Hook REPOP disparado para " .. player:GetName())

    -- Verificar cooldown
    if shenlongCD[guidLow] and now < shenlongCD[guidLow] then
        local remaining = shenlongCD[guidLow] - now
        player:SendBroadcastMessage("|cFFFFFFFF[Val'kyr]|r La Luz aun se recupera... (" .. remaining .. " seg)")
        return
    end

    DispararValkyr(player)
end

RegisterPlayerEvent(35, OnValkyr)

-- ============================================================
-- COMANDO .valkyr — activar secuencia manualmente para testing
-- ============================================================
local function OnValkyrCommand(event, player, command)
    if not player then return end

    if command == "valkyr" then
        local guidLow = player:GetGUIDLow()
        shenlongCD[guidLow] = nil  -- resetear cooldown para el test
        player:SendBroadcastMessage("|cFFFFFFFF[Val'kyr]|r Invocando secuencia de test...")
        DispararValkyr(player)
        return false
    end

    if command == "valkyr reset" then
        shenlongCD[player:GetGUIDLow()] = nil
        player:SendBroadcastMessage("|cFFFFFFFF[Val'kyr]|r Cooldown reseteado.")
        return false
    end
end

RegisterPlayerEvent(42, OnValkyrCommand)

-- ============================================================
-- LOG de inicio — Sistema Val'kyr
-- ============================================================
print("[Valkyr] Sistema de resurreccion cinematografica Val'kyr cargado.")
print("[Valkyr] NPC entry=" .. CFG_SH.NPC_ENTRY .. " | CD=" .. CFG_SH.COOLDOWN .. "seg | Vida=" .. CFG_SH.HEALTH_PCT .. "%")
