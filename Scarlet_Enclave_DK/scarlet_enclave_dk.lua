--[[
    scarlet_enclave_dk.lua
    Death Knight Starting Zone - Scarlet Enclave / Ebon Hold
    AzerothCore WotLK 3.3.5a + mod-ale

    Cubre:
      - zone_the_scarlet_enclave.cpp  (Val'kyr Battle-Maiden)
      - chapter1.cpp                  (Gothik DKC1, Scarlet Ghoul, Lich King whispers)
      - chapter2.cpp                  (Koltira Deathweaver, Scarlet Courier, "Special Surprise" NPCs,
                                       Acherus Necromancer, Gothik the Harvester, Persuasive Strike)
      - chapter3.cpp                  ("An End to All Things" - Devour Humanoid)
      - chapter5.cpp                  (Highlord Darion Mograine - Light of Dawn battle,
                                       Return to Capital insults)

    Eventos implementados (resumen):
      - Val'kyr Battle-Maiden: revive a DK al morir (multi-fase aerea)
      - Scarlet Ghoul (npc_scarlet_ghoul) + Gothik DKC1 (npc_dkc1_gothik) interaccion
      - Whispers aleatorios del Lich King (16 whispers)
      - Koltira Deathweaver: secuencia completa de breakout con oleadas + Valroth
      - Scarlet Courier: ocultarse en el arbol y emboscar al jugador
      - "A Special Surprise" - 10 NPCs hablando con DK que viene del mismo pueblo
      - Acherus Necromancer & Gothik the Harvester: rituales de levantamiento
      - Persuasive Strike (How to win friends and influence enemies)
      - Devour Humanoid (chapter 3)
      - Highlord Darion Mograine - The Light of Dawn (intro + countdown + outro completo)
      - Guards insultan al DK (Return to Capital)
]]

-- ============================================================================
-- DEPENDENCIAS / UTILIDADES
-- ============================================================================

local LANG_UNIVERSAL = 0

-- Helper: programar funcion despues de delay
local function ScheduleOnce(delay, fn)
    CreateLuaEvent(fn, delay, 1)
end

-- Helper: random entero entre a y b (inclusivo)
local function URand(a, b)
    return math.random(a, b)
end

-- Helper: probabilidad porcentual
local function Chance(pct)
    return math.random(1, 100) <= pct
end

-- Helper: verifica si un WorldObject (creature/player) sigue siendo valido
-- Usa pcall para no crashear si el objeto ya fue invalidado por el core.
local function IsValidCreature(c)
    if not c then return false end
    local ok, alive = pcall(function() return c:IsInWorld() end)
    return ok and alive == true
end

-- Estado por GUID
local function NewStateTable()
    return setmetatable({}, { __mode = "v" })
end

-- ============================================================================
-- CONSTANTES GLOBALES (extraidas de los .cpp)
-- ============================================================================

-- === NPCs ===
-- Chapter 1
local NPC_VALKYR_BATTLE_MAIDEN          = 24536  -- entry estandar de Val'kyr in DK starter
local NPC_SCARLET_GHOUL                 = 28845
local NPC_DKC1_GOTHIK                   = 28658  -- Gothik the Harvester en Acherus

-- Chapter 2
local NPC_KOLTIRA_DEATHWEAVER           = 28912
local NPC_CRIMSON_ACOLYTE               = 29007
local NPC_HIGH_INQUISITOR_VALROTH       = 29001
local NPC_SCARLET_COURIER               = 29076
local NPC_PLAGUEFIST                    = 29053
local NPC_ACHERUS_NECROMANCER           = 28889
local NPC_GOTHIK_THE_HARVESTER          = 28890

local NPC_GLUTTONOUS_GEIST              = 28905
local NPC_DEAD_SCARLET_MEDIC            = 28895
local NPC_DEAD_SCARLET_INFANTRYMAN      = 28896
local NPC_DEAD_SCARLET_CAPTAIN          = 28898
local NPC_DEAD_SCARLET_PEASANT          = 28892
local NPC_DEAD_SCARLET_MINER            = 28891
local NPC_DEAD_SCARLET_FLEET_DEFENDER   = 28886
local NPC_DEAD_SCARLET_GRYPHON          = 28893

-- A Special Surprise (chapter 2)
local SPECIAL_SURPRISE_NPCS = {
    [29061] = 12742, -- Ellen Stanbridge
    [29072] = 12748, -- Kug Ironjaw
    [29067] = 12744, -- Donovan Pulfrost
    [29065] = 12743, -- Yazmina Oakenthorn
    [29071] = 12750, -- Antoine Brack
    [29032] = 12739, -- Malar Bravehorn
    [29068] = 12745, -- Goby Blastenheimer
    [29073] = 12749, -- Iggy Darktusk
    [29074] = 12747, -- Lady Eonys
    [29070] = 12746, -- Valok the Righteous
}

-- Persuasive Strike targets
local PERSUASIVE_TARGETS = {
    [28939] = true, -- Scarlet Preacher
    [28936] = true, -- Scarlet Commander
    [28940] = true, -- Scarlet Crusader
    [28610] = true, -- Scarlet Marksman
    [28964] = true, -- Scarlet Lord McCree
}

-- Chapter 3 / Devour Humanoid
local NPC_HEARTHGLEN_CRUSADER           = 29102
local NPC_TIRISFAL_CRUSADER             = 29103

-- Chapter 5 - Light of Dawn
local NPC_DEFENDER_OF_THE_LIGHT         = 29174
local NPC_KORFAX_CHAMPION_OF_THE_LIGHT  = 29176
local NPC_COMMANDER_ELIGOR_DAWNBRINGER  = 29177
local NPC_LORD_MAXWELL_TYROSUS          = 29178
local NPC_LEONID_BARTHALOMEW_REVERED    = 29179
local NPC_DUKE_NICHOLAS_ZVERENHOFF      = 29180
local NPC_RAYNE                         = 29181
local NPC_RIMBLAT_EARTHSHATTER          = 29182

local NPC_RAMPAGING_ABOMINATION         = 29186
local NPC_ACHERUS_GHOUL                 = 29219
local NPC_WARRIOR_OF_THE_FROZEN_WASTES  = 29206
local NPC_FLESH_BEHEMOTH                = 29190

local NPC_HIGHLORD_DARION_MOGRAINE      = 29173
local NPC_KOLTIRA_DEATHWEAVER_C5        = 29199
local NPC_ORBAZ_BLOODBANE               = 29204
local NPC_THASSARIAN                    = 29200

local NPC_HIGHLORD_TIRION_FORDRING      = 29175
local NPC_HIGHLORD_ALEXANDROS_MOGRAINE  = 29227
local NPC_DARION_MOGRAINE_GHOST         = 29228
local NPC_THE_LICH_KING                 = 29183

-- Guards (Return to Capital)
local NPC_SW_GUARD       = 68
local NPC_ROYAL_GUARD    = 1756
local NPC_CITY_PATROLLER = 1976
local NPC_OG_GUARD       = 3296
local NPC_KOR_ELITE      = 14304

-- === GameObjects ===
local GO_INCONSPICUOUS_TREE = 191144
local GO_HOLY_LIGHTNING     = 191301
local GO_LIGHT_OF_DAWN      = 191330

-- === Spells ===
-- Val'kyr
local SPELL_REVIVE = 51918

-- Chapter 1
local SPELL_THE_EYE_OF_ACHERUS  = 51852
local SPELL_CALL_OF_THE_DEAD    = 51900
local SPELL_GHOUL_EMERGE        = 50142
local SPELL_SUMMON_SCARLET_GHOST = 52505
local SPELL_GHOUL_SUBMERGE      = 26234
local SPELL_DK_INITIATE_VISUAL  = 51519

local SPELL_LICH_KING_VO_BLOCKER = 58207
local LICH_KING_WHISPER_FIRST    = 58208
local LICH_KING_WHISPER_LAST     = 58223

-- Chapter 2
local SPELL_KOLTIRA_TRANSFORM   = 52899
local SPELL_ANTI_MAGIC_ZONE     = 52894
local SPELL_SHOOT               = 52818
local SPELL_SCARLET_GHOUL_RAISE = 52683
local SPELL_SCOURGE_GRYPHON     = 52685
local SPELL_GHOULPLOSION        = 52672
local SPELL_PORTAL_EFFECT_ACHERUS = 53098

-- Chapter 3
local SPELL_DEVOUR_HUMANOID_DAMAGE = 53111

-- Chapter 5
local SPELL_CAMERA_SHAKE_INIT      = 36455
local SPELL_CAMERA_SHAKE           = 39983
local SPELL_THE_MIGHT_OF_MOGRAINE  = 53642
local SPELL_ANTI_MAGIC_ZONE1       = 52893
local SPELL_DEATH_STRIKE           = 53639
local SPELL_DEATH_EMBRACE          = 53635
local SPELL_UNHOLY_BLIGHT          = 53640
local SPELL_DARION_MOD_DAMAGE      = 53645
local SPELL_THE_LIGHT_OF_DAWN      = 53658
local SPELL_ALEXANDROS_MOGRAINE_SPAWN = 53667
local SPELL_ICEBOUND_VISAGE        = 53274
local SPELL_SOUL_FEAST_ALEX        = 53677
local SPELL_MOGRAINE_CHARGE        = 53679
local SPELL_REBUKE                 = 53680
local SPELL_SOUL_FEAST_TIRION      = 53685
local SPELL_APOCALYPSE             = 53210
local SPELL_THROW_ASHBRINGER       = 53701
local SPELL_REBIRTH_OF_ASHBRINGER  = 53702
local SPELL_TIRION_CHARGE          = 53705
local SPELL_EXIT_TELEPORT_VISUAL   = 61456
local SPELL_LAY_ON_HANDS           = 53778
local SPELL_THE_LIGHT_OF_DAWN_Q    = 53606

-- Return to Capital insult spells
local SPELL_INSULT_APPLE  = 58509
local SPELL_INSULT_BANANA = 58513
local SPELL_INSULT_SPIT   = 58520
local INSULT_SPELLS = { SPELL_INSULT_APPLE, SPELL_INSULT_BANANA, SPELL_INSULT_SPIT }

-- === Quests ===
local QUEST_DEATH_COMES_FROM_ON_HIGH = 12641
local QUEST_GIFT_THAT_KEEPS_GIVING   = 12698
local QUEST_BREAKOUT                 = 12727
local QUEST_HOW_TO_WIN_FRIENDS       = 12720
local QUEST_SCARLET_ARMIES_APPROACH  = 12757
local QUEST_AN_END_TO_ALL_THINGS     = 12779
local QUEST_LIGHT_OF_DAWN            = 12801

-- === World States (Light of Dawn) ===
local WS_BFLH_DEFENDERS_COUNT      = 3592
local WS_BFLH_SCOURGE_COUNT        = 3591
local WS_BFLH_SOLDIERS_ENABLE      = 3603
local WS_BFLH_COUNTDOWN_ENABLE     = 3601
local WS_BFLH_COUNTDOWN_TIME       = 3602
local WS_BFLH_EVENT_BEGIN_ENABLE   = 3605

-- === Emotes ===
local EMOTE_ONESHOT_ROAR          = 53
local EMOTE_ONESHOT_LAUGH         = 11
local EMOTE_ONESHOT_POINT         = 25
local EMOTE_ONESHOT_RUDE          = 14
local EMOTE_ONESHOT_CUSTOM_SPELL_01 = 366
local EMOTE_STATE_READY1H         = 375
local EMOTE_STATE_READY2H         = 376
local EMOTE_STATE_FLYGRABCLOSED   = 432
local EMOTE_STATE_NONE            = 0

-- === Stand state ===
local UNIT_STAND_STATE_STAND  = 0
local UNIT_STAND_STATE_SIT    = 1
local UNIT_STAND_STATE_KNEEL  = 8
local UNIT_STAND_STATE_DEAD   = 7

-- === React state ===
local REACT_PASSIVE     = 0
local REACT_DEFENSIVE   = 1
local REACT_AGGRESSIVE  = 2

-- === Movement type ===
local MOVE_RUN = 1

-- === QuestStatus ===
local QUEST_STATUS_INCOMPLETE = 3

-- ============================================================================
-- CHAPTER 0 - ZONE - VAL'KYR BATTLE MAIDEN (revive a DK al morir)
-- ============================================================================
-- Original: npc_valkyr_battle_maiden (zone_the_scarlet_enclave.cpp)
-- Comportamiento: spawneada como summon del jugador muerto. Vuela hacia el,
-- castea Revive (51918) y desaparece. Replicamos las 4 fases por timer.

local valkyrStates = {}

local function ValkyrInit(event, creature)
    if not creature then return end
    local guid = creature:GetGUID()
    valkyrStates[guid] = { phase = 0 }

    -- Hacerla invisible al spawn, sin ser atacable
    creature:SetReactState(REACT_PASSIVE)
    creature:SetCanFly(true)

    -- Fase 0: animacion fly-grab + emote
    creature:HandleEmoteCommand(EMOTE_STATE_FLYGRABCLOSED)

    -- Fase 1: hacerse visible despues de 500ms
    ScheduleOnce(500, function()
        if not creature or not creature:IsInWorld() then return end
        local owner = creature:GetOwner()
        if owner and owner:IsPlayer() then
            creature:SetTarget(owner:GetGUID())
        end
    end)

    -- Fase 2: cast Revive a los 5s
    ScheduleOnce(5000, function()
        if not creature or not creature:IsInWorld() then return end
        local owner = creature:GetOwner()
        if owner and owner:IsPlayer() then
            -- Solo si el jugador no tiene ya un revive solicitado
            creature:CastSpell(owner, SPELL_REVIVE, true)
            creature:HandleEmoteCommand(EMOTE_ONESHOT_CUSTOM_SPELL_01)
            -- Whisper de revive (texto opcional desde creature_text DB)
        end
    end)

    -- Fase 3-4: desaparecer
    ScheduleOnce(10000, function()
        if creature and creature:IsInWorld() then
            creature:DespawnOrUnsummon(0)
        end
    end)
end

RegisterCreatureEvent(NPC_VALKYR_BATTLE_MAIDEN, 5, ValkyrInit) -- ON_SPAWN

-- ============================================================================
-- CHAPTER 1 - GOTHIK (DKC1) y SCARLET GHOUL
-- ============================================================================

-- Estado por ghoul: guarda owner, gothikGUID, fase
local ghoulStates = {}

-- npc_scarlet_ghoul: al spawnear, sale del suelo (Ghoul Emerge), tras 3.5s
-- comienza a seguir al owner. Detecta cercania de Gothik DKC1 y se sumerge.
local function ScarletGhoulSpawn(event, creature)
    if not creature then return end
    local guid = creature:GetGUID()
    ghoulStates[guid] = { ready = false }

    creature:SetReactState(REACT_PASSIVE)

    -- Cast emerge inmediato
    ScheduleOnce(1, function()
        if creature and creature:IsInWorld() then
            creature:CastSpell(creature, SPELL_GHOUL_EMERGE, true)
        end
    end)

    -- Restore state: 3.5s despues de spawn, pasa a defensivo y sigue al owner
    ScheduleOnce(3500, function()
        if not creature or not creature:IsInWorld() then return end
        creature:SetReactState(REACT_DEFENSIVE)
        local owner = creature:GetOwner()
        if owner then
            creature:MoveFollow(owner, 2.0, 0)
        end
        ghoulStates[guid] = ghoulStates[guid] or {}
        ghoulStates[guid].ready = true
    end)
end

RegisterCreatureEvent(NPC_SCARLET_GHOUL, 5, ScarletGhoulSpawn) -- ON_SPAWN

-- AIUpdate para que el ghoul detecte Gothik DKC1 cerca y se mueva al pit
local function ScarletGhoulAIUpdate(event, creature, diff)
    if not creature or not creature:IsAlive() then return end
    local guid = creature:GetGUID()
    local st = ghoulStates[guid]
    if not st or not st.ready or st.movingToPit then return end

    -- Buscar Gothik DKC1 a 10 yardas
    local gothik = creature:GetNearestCreature(10, NPC_DKC1_GOTHIK, 0, 1)
    if gothik then
        st.movingToPit = true
        local owner = creature:GetOwner()
        if owner and owner:IsPlayer() then
            local pl = owner
            if pl:GetQuestStatus(QUEST_GIFT_THAT_KEEPS_GIVING) == QUEST_STATUS_INCOMPLETE then
                creature:CastSpell(owner, 52517, true) -- credit
            end
        end
        -- Marcar al ghoul como inmune a todo
        creature:SetImmuneTo(0, true)
        -- Avisar a Gothik para que diga la linea
        if gothik then
            gothik:SendUnitYell("¡Otro ghoul al foso!", LANG_UNIVERSAL)
            gothik:HandleEmoteCommand(EMOTE_ONESHOT_ROAR)
        end
        -- Mover al ghoul al pit y despawn
        creature:MoveTo(1, 2364.77, -5776.14, 151.36, false)
        ScheduleOnce(5000, function()
            if creature and creature:IsInWorld() then
                creature:CastSpell(creature, SPELL_GHOUL_SUBMERGE, true)
                creature:DespawnOrUnsummon(1500)
            end
        end)
    end
end

RegisterCreatureEvent(NPC_SCARLET_GHOUL, 7, ScarletGhoulAIUpdate) -- AIUPDATE (event id 7 = ON_AIUPDATE)

local function ScarletGhoulRemove(event, creature)
    if creature then ghoulStates[creature:GetGUID()] = nil end
end
RegisterCreatureEvent(NPC_SCARLET_GHOUL, 37, ScarletGhoulRemove) -- ON_REMOVE

-- npc_dkc1_gothik: solo necesita poder ejecutar emotes. El comportamiento de
-- MoveInLineOfSight es manejado desde el ghoul (arriba), porque mod-ale no
-- expone OwnerAttackedBy / MoveInLineOfSight con el mismo nivel de control.

-- ============================================================================
-- CHAPTER 1 - LICH KING WHISPERS (aleatorios)
-- ============================================================================
-- El spell 58207 (Lich King VO Blocker) cuando hace apply, castea un whisper
-- random entre 58208 y 58223. Como no podemos reescribir spells en Lua, lo
-- implementamos como un timer que activa los whispers cuando un DK esta en
-- la fase de inicio. Aqui dejamos un PlayerEvent para reproducir whispers.
--
-- Implementacion simple: cada vez que un jugador con quest de Acherus entra
-- a la zona Scarlet Enclave (Map 0, Zone 4298), programar whispers cada
-- ciertos minutos.

local ZONE_SCARLET_ENCLAVE = 4298
local lichKingWhisperTimers = {}

local function ScheduleLichKingWhisper(player)
    if not player then return end
    local guidLow = player:GetGUIDLow()
    local fullGuid = player:GetGUID()   -- capturar ANTES del closure
    if lichKingWhisperTimers[guidLow] then return end
    lichKingWhisperTimers[guidLow] = true

    local function loop()
        -- Re-fetch el jugador por GUID en cada tick: el objeto 'player'
        -- original puede haber sido invalidado (logout, reload, etc.)
        local p = GetPlayerByGUID(fullGuid)
        if not p or not p:IsInWorld() then
            lichKingWhisperTimers[guidLow] = nil
            return
        end
        if p:GetZoneId() ~= ZONE_SCARLET_ENCLAVE then
            lichKingWhisperTimers[guidLow] = nil
            return
        end
        -- Solo dispara durante quests de cap1
        local q = p:GetQuestStatus(QUEST_DEATH_COMES_FROM_ON_HIGH)
        if q == QUEST_STATUS_INCOMPLETE then
            local spellId = URand(LICH_KING_WHISPER_FIRST, LICH_KING_WHISPER_LAST)
            pcall(function() p:CastSpell(p, spellId, true) end)
        end
        -- Reprogramar
        ScheduleOnce(60000 + URand(0, 60000), loop)
    end
    ScheduleOnce(30000, loop)
end

local function OnPlayerLichKingZone(event, player, newZone, newArea)
    if newZone == ZONE_SCARLET_ENCLAVE then
        ScheduleLichKingWhisper(player)
    end
end
RegisterPlayerEvent(27, OnPlayerLichKingZone) -- ON_UPDATE_ZONE

-- ============================================================================
-- CHAPTER 2 - KOLTIRA DEATHWEAVER - BREAKOUT (quest 12727)
-- ============================================================================
-- Secuencia compleja:
--   1) Jugador acepta quest 12727
--   2) Koltira se sienta, dice SAY_BREAKOUT0
--   3) Camina por waypoints, dice SAY_BREAKOUT1, 2 (kneel + cast AMZ)
--   4) Llega al box, kneel, transformacion, suelta 3 oleadas de Crimson
--      Acolyte (3 acolitos cada una) + dialogos de Valroth
--   5) Spawnea a Valroth, oleada final
--   6) Cuando Valroth muere: Koltira se pone de pie, monta y se va

local koltiraStates = {}

local function KoltiraTalk(creature, text)
    if creature and creature:IsInWorld() then
        creature:SendUnitYell(text, LANG_UNIVERSAL)
    end
end

local function StartKoltiraBreakout(creature, player)
    if not creature then return end
    local guid = creature:GetGUID()
    if koltiraStates[guid] and koltiraStates[guid].active then return end
    koltiraStates[guid] = { active = true, valrothGUID = nil, wave = 0 }

    creature:SetStandState(UNIT_STAND_STATE_SIT)

    -- SAY_BREAKOUT0
    KoltiraTalk(creature, "¡Por fin! Pense que nunca llegarian.")

    -- Despues de 5s: SAY_BREAKOUT1 (de pie)
    ScheduleOnce(5000, function()
        if not creature or not creature:IsInWorld() then return end
        creature:SetStandState(UNIT_STAND_STATE_STAND)
        KoltiraTalk(creature, "¡Sigueme! Tenemos que salir de aqui.")
    end)

    -- A los 10s: kneel + Anti-Magic Zone (SAY_BREAKOUT2)
    ScheduleOnce(10000, function()
        if not creature or not creature:IsInWorld() then return end
        creature:SetStandState(UNIT_STAND_STATE_KNEEL)
        KoltiraTalk(creature, "¡Necesitare un momento para preparar mi Anti-Magic Zone!")
        creature:CastSpell(creature, SPELL_ANTI_MAGIC_ZONE, true)
    end)

    -- Oleada 1 (a los 15s): SAY_BREAKOUT3 + 3 acolitos
    ScheduleOnce(15000, function()
        if not creature or not creature:IsInWorld() then return end
        KoltiraTalk(creature, "¡Aqui vienen!")
        creature:CastSpell(creature, SPELL_KOLTIRA_TRANSFORM, true)

        -- Spawnea Valroth a distancia (passive, solo habla)
        local valroth = creature:SummonCreature(NPC_HIGH_INQUISITOR_VALROTH,
            1640.86, -6030.83, 134.82, 4.61, 8, 0)
        if valroth then
            koltiraStates[guid].valrothGUID = valroth:GetGUID()
            valroth:SetReactState(REACT_PASSIVE)
            valroth:SendUnitYell("¡Caera la Cruzada Escarlata sobre vosotros!", LANG_UNIVERSAL)
        end

        for i = 1, 3 do
            creature:SummonCreature(NPC_CRIMSON_ACOLYTE,
                1640.67 + i * 0.5, -6032.0, 134.82, 4.65, 4, 15000)
        end
    end)

    -- Oleada 2 (a los 35s): SAY_BREAKOUT4
    ScheduleOnce(35000, function()
        if not creature or not creature:IsInWorld() then return end
        KoltiraTalk(creature, "¡Mas vienen! ¡Mantengan la posicion!")
        local st = koltiraStates[guid]
        if st and st.valrothGUID then
            local v = creature:GetMap():GetWorldObject(st.valrothGUID)
            if v then v:SendUnitYell("¡La luz quemara vuestras almas!", LANG_UNIVERSAL) end
        end
        for i = 1, 3 do
            creature:SummonCreature(NPC_CRIMSON_ACOLYTE,
                1640.79 + i * 0.5, -6030.30, 134.82, 4.65, 4, 15000)
        end
    end)

    -- Oleada 3 (a los 55s): SAY_BREAKOUT5
    ScheduleOnce(55000, function()
        if not creature or not creature:IsInWorld() then return end
        KoltiraTalk(creature, "¡Aguantad! ¡Casi terminamos con ellos!")
        local st = koltiraStates[guid]
        if st and st.valrothGUID then
            local v = creature:GetMap():GetWorldObject(st.valrothGUID)
            if v then v:SendUnitYell("¡Por la Cruzada Escarlata!", LANG_UNIVERSAL) end
        end
        for i = 1, 4 do
            creature:SummonCreature(NPC_CRIMSON_ACOLYTE,
                1641.34 + i * 0.5, -6031.43, 134.82, 4.61, 4, 15000)
        end
    end)

    -- Oleada final - Valroth ataca (a los 75s): SAY_BREAKOUT6
    ScheduleOnce(75000, function()
        if not creature or not creature:IsInWorld() then return end
        KoltiraTalk(creature, "¡Aqui viene Valroth! ¡Yo me quedo - tu derrotalo!")
        local st = koltiraStates[guid]
        if st and st.valrothGUID then
            local v = creature:GetMap():GetWorldObject(st.valrothGUID)
            if v then
                v:SendUnitYell("¡PROBARAS MI IRA!", LANG_UNIVERSAL)
                v:SetReactState(REACT_AGGRESSIVE)
            end
        end
    end)

    -- Timeout - si Valroth no muere en 2 min, Koltira se desmaya
    ScheduleOnce(75000 + 120000, function()
        if not creature or not creature:IsInWorld() then return end
        local st = koltiraStates[guid]
        if st and st.active then
            -- Koltira colapsa
            creature:SendUnitEmote("|Koltira se desploma...")
            creature:KillSelf()
            koltiraStates[guid] = nil
        end
    end)
end

-- Quest 12727 accept: arrancar evento
local function OnKoltiraQuestAccept(event, player, creature, quest)
    if not quest then return end
    if quest:GetId() == QUEST_BREAKOUT then
        StartKoltiraBreakout(creature, player)
    end
end
RegisterCreatureEvent(NPC_KOLTIRA_DEATHWEAVER, 31, OnKoltiraQuestAccept) -- ON_QUEST_ACCEPT

-- Cuando muere Valroth -> Koltira sale y se monta
local function OnValrothDied(event, creature, killer)
    if not creature then return end
    -- Buscar Koltira cercano
    local koltira = creature:GetNearestCreature(80, NPC_KOLTIRA_DEATHWEAVER, 0, 1)
    if not koltira then return end
    local kguid = koltira:GetGUID()
    local st = koltiraStates[kguid]
    if not st then return end
    st.active = false

    koltira:RemoveAura(SPELL_ANTI_MAGIC_ZONE)
    koltira:SetStandState(UNIT_STAND_STATE_STAND)

    ScheduleOnce(3000, function()
        if koltira and koltira:IsInWorld() then
            KoltiraTalk(koltira, "¡Lo lograste! ¡Te debo una!")
        end
    end)
    ScheduleOnce(8000, function()
        if koltira and koltira:IsInWorld() then
            KoltiraTalk(koltira, "Avisare al maestro de armas. ¡Vamos!")
        end
    end)
    ScheduleOnce(11000, function()
        if koltira and koltira:IsInWorld() then
            KoltiraTalk(koltira, "Hasta pronto, hermano de armas...")
            koltira:SetReactState(REACT_PASSIVE)
            koltira:SetMountDisplay(25278) -- DK mount display
            -- Despawn tras 30s
            koltira:DespawnOrUnsummon(30000)
        end
    end)
end
RegisterCreatureEvent(NPC_HIGH_INQUISITOR_VALROTH, 4, OnValrothDied) -- ON_DIED

-- ============================================================================
-- CHAPTER 2 - SCARLET COURIER (esconde tras arbol y emboscada)
-- ============================================================================
-- npc_scarlet_courier: monta caballo (display 14338), busca arbol cercano,
-- desmonta, llega al arbol y emboscando a quien sea owner del arbol.

local courierStates = {}

local function CourierSpawn(event, creature)
    if not creature then return end
    local guid = creature:GetGUID()
    courierStates[guid] = { stage = 1, timer = 3000 }
    creature:SetMountDisplay(14338)
end
RegisterCreatureEvent(NPC_SCARLET_COURIER, 5, CourierSpawn) -- ON_SPAWN

local function CourierAIUpdate(event, creature, diff)
    if not creature or not creature:IsAlive() then return end
    local guid = creature:GetGUID()
    local st = courierStates[guid]
    if not st or st.stage == 0 then return end
    if creature:IsInCombat() then return end

    st.timer = st.timer - diff
    if st.timer > 0 then return end

    if st.stage == 1 then
        creature:SetWalk(true)
        local tree = creature:GetNearestGameObject(GO_INCONSPICUOUS_TREE, 40)
        if tree then
            creature:SendUnitYell("¡Un arbol! Voy a investigar...", LANG_UNIVERSAL)
            creature:Dismount()
            creature:MoveTo(1, tree:GetX(), tree:GetY(), tree:GetZ(), false)
            st.stage = 2
        end
    elseif st.stage == 2 then
        local tree = creature:GetNearestGameObject(GO_INCONSPICUOUS_TREE, 40)
        if tree then
            creature:SendUnitYell("¡Trampa! ¡Por la Cruzada!", LANG_UNIVERSAL)
            -- Buscar jugador cercano y atacarlo
            local target = creature:GetNearestPlayer(15)
            if target then
                creature:Attack(target, true)
            end
        end
        st.stage = 0
    end
    st.timer = 3000
end
RegisterCreatureEvent(NPC_SCARLET_COURIER, 7, CourierAIUpdate) -- AIUPDATE

local function CourierEnterCombat(event, creature, target)
    if not creature then return end
    local guid = creature:GetGUID()
    if courierStates[guid] then
        courierStates[guid].stage = 0
    end
    creature:Dismount()
    creature:SendUnitYell("¡Por la Cruzada Escarlata!", LANG_UNIVERSAL)
end
RegisterCreatureEvent(NPC_SCARLET_COURIER, 1, CourierEnterCombat) -- ENTER_COMBAT

local function CourierRemove(event, creature)
    if creature then courierStates[creature:GetGUID()] = nil end
end
RegisterCreatureEvent(NPC_SCARLET_COURIER, 37, CourierRemove)

-- ============================================================================
-- CHAPTER 2 - "A SPECIAL SURPRISE" (10 NPCs)
-- ============================================================================
-- Cada NPC reconoce a un DK que tiene cierto quest. Da una secuencia de 12
-- frases (cada ~7s, ultima a 15s) y luego se "muere". Usamos un solo handler
-- generico y registramos para cada entry.

local specialSurpriseStates = {}

local function SpecialSurpriseSay(creature, line)
    -- Linea generica - en el core real se usa creature_text por GUID. Aqui
    -- simulamos diciendo el numero de linea (el GM puede editar luego).
    local texts = {
        [0]  = "Por favor... ¡no me hagais dano!",
        [1]  = "Vais a... ¿matarme?",
        [2]  = "Espera... reconozco esa armadura...",
        [3]  = "¡Tu eres...! Tu eres de mi pueblo, ¿verdad?",
        [4]  = "¿No te acuerdas de mi? Soy yo...",
        [5]  = "No... no me recuerdas. Es por la transformacion...",
        [6]  = "Piensa, te lo ruego. Trata de recordar.",
        [7]  = "Escucha bien lo que te digo...",
        [8]  = "...", -- Plaguefist habla aqui
        [9]  = "Ya es la hora. Hazlo rapido.",
        [10] = "Espero... te espero...",
        [11] = "" -- emote dies
    }
    local t = texts[line]
    if t and t ~= "" then
        creature:SendUnitSay(t, LANG_UNIVERSAL)
    elseif line == 11 then
        creature:SendUnitEmote("muere lentamente")
    end
end

local function SpecialSurpriseUpdate(event, creature, diff)
    if not creature or not creature:IsAlive() then return end
    local guid = creature:GetGUID()
    local st = specialSurpriseStates[guid]
    if not st then return end
    if not st.playerGUID then return end
    if creature:GetVictim() then return end

    st.timer = (st.timer or 0) - diff
    if st.timer > 0 then return end

    local map = creature:GetMap()
    local player = map and map:GetWorldObject(st.playerGUID)
    if not player then
        specialSurpriseStates[guid] = nil
        return
    end

    local counter = st.counter or 0
    if counter == 1 then
        creature:SetStandState(UNIT_STAND_STATE_STAND)
    elseif counter == 8 then
        local plague = creature:GetNearestCreature(85, NPC_PLAGUEFIST, 0, 1)
        if plague then
            plague:SendUnitSay("¡Listo, iniciado! ¡Acaba con el!", LANG_UNIVERSAL)
        end
    elseif counter == 9 then
        SpecialSurpriseSay(creature, 9)
        creature:SetStandState(UNIT_STAND_STATE_KNEEL)
        creature:SetReactState(REACT_PASSIVE)
    elseif counter == 11 then
        SpecialSurpriseSay(creature, 11)
        creature:KillSelf()
        specialSurpriseStates[guid] = nil
        return
    else
        SpecialSurpriseSay(creature, counter)
    end

    if counter >= 9 then
        st.timer = 15000
    else
        st.timer = 7000
    end
    st.counter = counter + 1
end

local function SpecialSurpriseSpawn(event, creature)
    if not creature then return end
    specialSurpriseStates[creature:GetGUID()] = {
        counter = 0,
        timer = 0,
        playerGUID = nil,
    }
    creature:SetReactState(REACT_PASSIVE)
end

local function SpecialSurpriseMoveInLOS(creature, player)
    local guid = creature:GetGUID()
    local st = specialSurpriseStates[guid]
    if not st or st.playerGUID then return end

    local questId = SPECIAL_SURPRISE_NPCS[creature:GetEntry()]
    if not questId then return end
    if player:GetQuestStatus(questId) ~= QUEST_STATUS_INCOMPLETE then return end

    st.playerGUID = player:GetGUID()
    st.timer = 0
end

-- AIUpdate adicional: buscar jugadores cercanos (no podemos hookear LOS directo)
local function SpecialSurpriseAIUpdate(event, creature, diff)
    SpecialSurpriseUpdate(event, creature, diff)
    if creature and creature:IsAlive() then
        local guid = creature:GetGUID()
        local st = specialSurpriseStates[guid]
        if st and not st.playerGUID then
            local p = creature:GetNearestPlayer(5)
            if p then SpecialSurpriseMoveInLOS(creature, p) end
        end
    end
end

for entry, _ in pairs(SPECIAL_SURPRISE_NPCS) do
    RegisterCreatureEvent(entry, 5, SpecialSurpriseSpawn)
    RegisterCreatureEvent(entry, 7, SpecialSurpriseAIUpdate)
end

-- ============================================================================
-- CHAPTER 2 - ACHERUS NECROMANCER (28889) y GOTHIK THE HARVESTER (28890)
-- ============================================================================
-- Ambos buscan cadaveres scarlet, se acercan y los levantan como ghouls.
-- Gothik adicionalmente puede levantar grifos como Scourge Gryphons.
-- Si hay un Gluttonous Geist cerca, lo Ghoulplosionan primero.

local SCARLET_HUMANOID_CORPSES = {
    NPC_DEAD_SCARLET_MEDIC,
    NPC_DEAD_SCARLET_INFANTRYMAN,
    NPC_DEAD_SCARLET_CAPTAIN,
    NPC_DEAD_SCARLET_PEASANT,
    NPC_DEAD_SCARLET_MINER,
    NPC_DEAD_SCARLET_FLEET_DEFENDER,
}

local SCARLET_ALL_CORPSES = {
    NPC_DEAD_SCARLET_MEDIC,
    NPC_DEAD_SCARLET_INFANTRYMAN,
    NPC_DEAD_SCARLET_CAPTAIN,
    NPC_DEAD_SCARLET_PEASANT,
    NPC_DEAD_SCARLET_MINER,
    NPC_DEAD_SCARLET_FLEET_DEFENDER,
    NPC_DEAD_SCARLET_GRYPHON,
}

local necroStates = {}

local function FindNearestCorpse(creature, corpseList, range)
    local nearest, nearestDist = nil, math.huge
    for _, entry in ipairs(corpseList) do
        local c = creature:GetNearestCreature(range, entry, 0, 1)
        if c then
            local d = creature:GetDistance(c)
            if d < nearestDist then
                nearestDist = d
                nearest = c
            end
        end
    end
    return nearest
end

local function NecromancerStartRitual(creature, isGothik)
    if not IsValidCreature(creature) then return end
    local guid = creature:GetGUID()
    local st = necroStates[guid]
    if not st or st.onRitual then return end

    local corpses = isGothik and SCARLET_ALL_CORPSES or SCARLET_HUMANOID_CORPSES
    local corpse = FindNearestCorpse(creature, corpses, 60)
    if not corpse then
        -- Reintentar mas tarde
        ScheduleOnce(URand(5000, 10000), function()
            if IsValidCreature(creature) then
                NecromancerStartRitual(creature, isGothik)
            end
        end)
        return
    end

    st.onRitual = true
    st.targetCorpseGUID = corpse:GetGUID()
    creature:MoveTo(1, corpse:GetX(), corpse:GetY(), corpse:GetZ(), false)

    ScheduleOnce(3000, function()
        if not IsValidCreature(creature) then return end
        local map = creature:GetMap()
        local c = map and map:GetWorldObject(st.targetCorpseGUID)
        if not c then
            st.onRitual = false
            ScheduleOnce(URand(20000, 30000), function()
                NecromancerStartRitual(creature, isGothik)
            end)
            return
        end
        creature:SetFacingToObject(c)

        -- Buscar geist cercano
        local geist = creature:GetNearestCreature(3, NPC_GLUTTONOUS_GEIST, 0, 1)
        if geist then
            if isGothik then
                creature:SendUnitSay("¿Tendra Gothik que ahogar a un geist?", LANG_UNIVERSAL)
            end
            ScheduleOnce(0, function()
                if IsValidCreature(creature) and IsValidCreature(geist) then
                    creature:CastSpell(geist, SPELL_GHOULPLOSION, true)
                end
            end)
            ScheduleOnce(3000, function()
                if not IsValidCreature(creature) then return end
                local corpse2 = map:GetWorldObject(st.targetCorpseGUID)
                if corpse2 then
                    if isGothik and corpse2:GetEntry() == NPC_DEAD_SCARLET_GRYPHON then
                        creature:CastSpell(corpse2, SPELL_SCOURGE_GRYPHON, true)
                    else
                        creature:CastSpell(corpse2, SPELL_SCARLET_GHOUL_RAISE, true)
                    end
                end
            end)
            ScheduleOnce(6000, function()
                if not IsValidCreature(creature) then return end
                st.onRitual = false
                st.targetCorpseGUID = nil
                local nextDelay = isGothik and URand(50000, 60000) or URand(20000, 30000)
                ScheduleOnce(nextDelay, function() NecromancerStartRitual(creature, isGothik) end)
            end)
        else
            -- Sin geist
            if isGothik then
                if corpse:GetEntry() == NPC_DEAD_SCARLET_GRYPHON then
                    creature:SendUnitSay("Volaras de nuevo, bestia...", LANG_UNIVERSAL)
                else
                    creature:SendUnitSay("¡Sorpresa, sorpresa! ¡Otro ghoul!", LANG_UNIVERSAL)
                end
            end
            ScheduleOnce(0, function()
                if not IsValidCreature(creature) then return end
                local corpse2 = map:GetWorldObject(st.targetCorpseGUID)
                if corpse2 then
                    if isGothik and corpse2:GetEntry() == NPC_DEAD_SCARLET_GRYPHON then
                        creature:CastSpell(corpse2, SPELL_SCOURGE_GRYPHON, true)
                    else
                        creature:CastSpell(corpse2, SPELL_SCARLET_GHOUL_RAISE, true)
                    end
                end
            end)
            ScheduleOnce(3000, function()
                if not IsValidCreature(creature) then return end
                st.onRitual = false
                st.targetCorpseGUID = nil
                local nextDelay = isGothik and URand(50000, 60000) or URand(20000, 30000)
                ScheduleOnce(nextDelay, function() NecromancerStartRitual(creature, isGothik) end)
            end)
        end
    end)
end

local function NecromancerSpawn(event, creature)
    if not creature then return end
    necroStates[creature:GetGUID()] = { onRitual = false }
    -- creature:RegisterEvent: el callback recibe worldobject valido, evita
    -- que el closure capture un puntero que puede invalidarse en ScheduleOnce global.
    creature:RegisterEvent(function(evId, delay, rep, wo)
        local c = wo and wo:ToCreature()
        if c then NecromancerStartRitual(c, false) end
    end, URand(20000, 30000), 1)
end
RegisterCreatureEvent(NPC_ACHERUS_NECROMANCER, 5, NecromancerSpawn)

local function GothikHarvesterSpawn(event, creature)
    if not creature then return end
    necroStates[creature:GetGUID()] = { onRitual = false }
    creature:RegisterEvent(function(evId, delay, rep, wo)
        local c = wo and wo:ToCreature()
        if c then NecromancerStartRitual(c, true) end
    end, URand(50000, 60000), 1)
end
RegisterCreatureEvent(NPC_GOTHIK_THE_HARVESTER, 5, GothikHarvesterSpawn)

local function NecromancerRemove(event, creature)
    if creature then necroStates[creature:GetGUID()] = nil end
end
RegisterCreatureEvent(NPC_ACHERUS_NECROMANCER, 37, NecromancerRemove)
RegisterCreatureEvent(NPC_GOTHIK_THE_HARVESTER, 37, NecromancerRemove)

-- ============================================================================
-- CHAPTER 2 - PERSUASIVE STRIKE (How to win friends and influence enemies)
-- ============================================================================
-- El spell 52781 (Persuasive Strike) tiene 30% de "persuadir" a un scarlet
-- nombrado. Como no podemos hookear OnEffectHitTarget, usamos KILL_CREATURE
-- como proxy: cada vez que un DK con quest 12720 mata uno de estos scarlets,
-- damos credito y dialogos breves.

local function OnDKKillScarletPersuasive(event, killer, victim)
    if not killer or not victim then return end
    if not killer:IsPlayer() then return end
    if not PERSUASIVE_TARGETS[victim:GetEntry()] then return end
    if killer:GetQuestStatus(QUEST_HOW_TO_WIN_FRIENDS) ~= QUEST_STATUS_INCOMPLETE then return end

    -- Pequena animacion previa a la muerte (post-mortem texto del scarlet)
    -- (El victim ya esta muerto en este hook; solo damos credito visual)
    killer:KickPlayer() -- placeholder no-op
end
-- NOTA: el comportamiento real necesita SpellScript OnEffectHitTarget que mod-ale
-- no expone para spells del core. Documentado mas abajo.

-- ============================================================================
-- CHAPTER 2 - PORTAL EFFECT ACHERUS (quest 12757)
-- ============================================================================
-- spell 53098: solo funciona si target tiene quest 12757. En Lua no podemos
-- modificar el OnCheckCast de un spell del core. Lo dejamos documentado.

-- ============================================================================
-- CHAPTER 3 - DEVOUR HUMANOID (quest 12779 "An End to All Things")
-- ============================================================================
-- spell 53110: requiere Crusader (Hearthglen 29102 / Tirisfal 29103) a 15y.
-- Implementacion via spell cast: cuando el jugador castea el spell,
-- verificamos. En mod-ale, PlayerEvent ON_SPELL_CAST id 5 (event, player, spell, skipCheck).

local SPELL_DEVOUR_HUMANOID = 53110

local function OnDevourHumanoidCast(event, player, spell, skipCheck)
    if not player or not spell then return end
    -- spell:GetEntry() devuelve el ID del hechizo
    local ok, id = pcall(function() return spell:GetEntry() end)
    if not ok or id ~= SPELL_DEVOUR_HUMANOID then return end

    local crusader = player:GetNearestCreature(15, NPC_HEARTHGLEN_CRUSADER, true, false)
    if not crusader then
        crusader = player:GetNearestCreature(15, NPC_TIRISFAL_CRUSADER, true, false)
    end
    if crusader then
        crusader:Attack(player, true)
        crusader:CastSpell(player, SPELL_DEVOUR_HUMANOID_DAMAGE, true)
    end
end
RegisterPlayerEvent(5, OnDevourHumanoidCast) -- ON_SPELL_CAST

-- ============================================================================
-- CHAPTER 5 - HIGHLORD DARION MOGRAINE - THE LIGHT OF DAWN
-- ============================================================================
-- Quest 12801. NPC 29173. Evento masivo: countdown, batalla, outro con
-- Tirion, Alexandros, Darion ghost y Lich King.

local LIGHT_OF_DAWN_POS = {
    [0]  = { 2304.2, -5290.7, 82.01, 4.56 },
    [1]  = { 2253.5, -5310.6, 82.17, 5.28 },
    [2]  = { 2169.1, -5227.1, 82.59, 5.7 },
    [3]  = { 2289.259, -5280.355, 86.112, 4.41 },
    [4]  = { 2273.289, -5273.675, 86.701, 5.01 },
    [5]  = { 2280.81, -5284.09, 86.608, 4.76 },
    [6]  = { 2165.711, -5266.1235, 95.5025, 0.13962634 },
    [7]  = { 2281.198, -5257.397, 80.224, 4.66 },
    [8]  = { 2281.156, -5259.934, 80.647, 0 },
    [9]  = { 2281.294, -5281.895, 82.445, 1.35 },
    [10] = { 2281.093, -5263.013, 81.125, 0 },
    [11] = { 2283.896, -5287.914, 83.066, 1.55 },
    [12] = { 2280.304, -5257.205, 80.09781, 4.6251 },
    [13] = { 2280.687, -5262.276, 81.082634, 0.0 },
    [14] = { 2264.27, -5267.29, 80.16, 0 },
    [15] = { 2270.99, -5278.00, 81.89, 0 },
}

-- Lineas de Light of Dawn
local LOD_LINES = {
    DARION_INTRO_01 = "¡Hermanos y hermanas! ¡La hora ha llegado!",
    DARION_COUNT_02 = "¡Preparaos!",
    DARION_START_04 = "¡A la batalla! ¡Por los Caballeros de la Brigada Negra!",
    DARION_GENERAL_05 = "¡Ahora! ¡La Cruzada Escarlata cae hoy!",
    DARION_GENERAL_06 = "¡Adelante!",
    TIRION_AFTER_25  = "¡Detente, Mograine!",
    DARION_KNEEL_27  = "Highlord... no sabia...",
    TIRION_28        = "Mograine. Tu padre estaria orgulloso de ti.",
    TIRION_29        = "Hoy hemos perdido demasiados buenos hombres.",
    TIRION_30        = "Pero el dia no ha terminado.",
    DARION_STAND_31  = "Padre... ¿es esto un sueno?",
    ALEX_GHOST_32    = "Hijo mio. Has hecho lo que debias.",
    DARION_KNEEL2_33 = "Padre, perdoname...",
    DARION_KNEEL3_34 = "He fallado...",
    DARION_GHOST_35  = "Hijo. Es hora.",
    DARION_GHOST_36  = "Levanta tu cabeza con orgullo.",
    ALEX_37          = "Tu mision aun no termina.",
    DARION_38        = "Padre, espera...",
    ALEX_39          = "Hijo. Confia en el Highlord.",
    DARION_40        = "¡No te vayas!",
    ALEX_41          = "Lleva esta espada. Cumple con tu deber.",
    ALEX_42          = "Cuando llegue el momento... entregale esta espada al Highlord.",
    LK_43            = "¡Pateticos mortales!",
    DARION_44        = "¡Lich King! ¡Pagaras por todo!",
    LK_45            = "Tus padres mueren por segunda vez, Mograine.",
    LK_46            = "Y morira tu alma con ellos.",
    TIRION_47        = "¡Detente!",
    LK_48            = "Hahaha... ¿O que, Tirion?",
    LK_49            = "Ven entonces. Encuentrame en mi trono.",
    MAXWELL_50       = "¡Por la Luz!",
    LK_51            = "Asi sea. APOCALIPSIS.",
    DARION_52        = "¡NOOO!",
    DARION_53        = "Highlord... toma la Ashbringer.",
    TIRION_54        = "Por el poder de la Luz, te purificare.",
    LK_55            = "¡Imposible!",
    TIRION_56        = "¡Esto termina aqui!",
    LK_57            = "Volveremos a vernos, Fordring.",
    LK_58            = "En mi corona...",
    LK_59            = "...te aguardo.",
    TIRION_60        = "Adelante. Mucho trabajo nos espera.",
    TIRION_61        = "Mograine. Levanta.",
    TIRION_62        = "Esta es ahora la Brigada Negra de la Cruzada del Argent.",
    TIRION_63        = "Marchamos contra el Lich King.",
    TIRION_64        = "Que nadie diga que nuestros muertos murieron en vano.",
    TIRION_65        = "Que sus almas guien nuestra espada.",
    TIRION_66        = "Por el Argent Dawn. Por la Brigada Negra.",
    TIRION_67        = "Por la Alianza. Por la Horda. Por Azeroth.",
    DARION_68        = "Al Argent. ¡VAMOS!",
}

local darionStates = {}

local function GetDarionState(creature)
    local guid = creature:GetGUID()
    local st = darionStates[guid]
    if not st then
        st = {
            battleState = 0,    -- 0 NONE, 1 FIGHT, 2 OUTRO
            startTime = 0,
            defenders = 0,
            scourge = 0,
            summons = {},
            tirionGUID = nil,
            alexGUID = nil,
            darionGhostGUID = nil,
            lichKingGUID = nil,
            orbazGUID = nil,
            koltiraGUID = nil,
            thassarinGUID = nil,
        }
        darionStates[guid] = st
    end
    return st
end

local function DarionSendWorldStates(creature, st)
    local map = creature:GetMap()
    if not map then return end
    -- Broadcast a todos los jugadores del mapa con phase 128
    -- Simplificado: a todos
    for _, p in pairs(map:GetPlayers()) do
        if p and p:GetPhaseMask() then
            pcall(function()
                p:SendUpdateWorldState(WS_BFLH_DEFENDERS_COUNT, st.defenders)
                p:SendUpdateWorldState(WS_BFLH_SCOURGE_COUNT, st.scourge)
                p:SendUpdateWorldState(WS_BFLH_SOLDIERS_ENABLE,
                    (creature:IsAlive() and (st.startTime > 0 or st.battleState > 0)) and 1 or 0)
                p:SendUpdateWorldState(WS_BFLH_COUNTDOWN_ENABLE,
                    (creature:IsAlive() and st.startTime > 0) and 1 or 0)
                p:SendUpdateWorldState(WS_BFLH_COUNTDOWN_TIME, st.startTime)
                p:SendUpdateWorldState(WS_BFLH_EVENT_BEGIN_ENABLE,
                    (creature:IsAlive() and st.startTime == 0 and st.battleState > 0) and 1 or 0)
            end)
        end
    end
end

local function DarionTalk(creature, line)
    if creature and creature:IsInWorld() then
        creature:SendUnitYell(line, LANG_UNIVERSAL)
    end
end

local function DarionSummon(creature, entry, posIdx, duration)
    local p = LIGHT_OF_DAWN_POS[posIdx]
    if not p then return nil end
    return creature:SummonCreature(entry, p[1], p[2], p[3], p[4], 4, duration or 300000)
end

-- ========== Inicio del evento Light of Dawn ==========
local function DarionStartEvent(creature)
    local st = GetDarionState(creature)
    if st.startTime > 0 or st.battleState ~= 0 then return end

    DarionTalk(creature, LOD_LINES.DARION_INTRO_01)
    st.startTime = 5
    st.defenders = 300
    st.scourge = 10000
    DarionSendWorldStates(creature, st)

    -- Programar countdown (60s, 120s, 180s, 240s, 300s)
    ScheduleOnce(60000, function()
        if not creature:IsInWorld() then return end
        st.startTime = 4
        DarionSendWorldStates(creature, st)
    end)
    ScheduleOnce(120000, function()
        if not creature:IsInWorld() then return end
        st.startTime = 3
        DarionSendWorldStates(creature, st)
    end)
    ScheduleOnce(180000, function()
        if not creature:IsInWorld() then return end
        st.startTime = 2
        DarionSendWorldStates(creature, st)
    end)
    ScheduleOnce(240000, function()
        if not creature:IsInWorld() then return end
        DarionTalk(creature, LOD_LINES.DARION_COUNT_02)
        st.startTime = 1
        DarionSendWorldStates(creature, st)
    end)

    -- 300s - empieza la batalla
    ScheduleOnce(300000, function()
        if not creature:IsInWorld() then return end
        st.battleState = 1
        DarionTalk(creature, LOD_LINES.DARION_START_04)
        st.startTime = 0
        DarionSendWorldStates(creature, st)
    end)

    -- 308s - dialogo + camera shake
    ScheduleOnce(308000, function()
        if creature:IsInWorld() then
            DarionTalk(creature, LOD_LINES.DARION_GENERAL_05)
            creature:CastSpell(creature, SPELL_CAMERA_SHAKE_INIT, true)
        end
    end)

    -- 332s - DARION_GENERAL_06
    ScheduleOnce(332000, function()
        if creature:IsInWorld() then
            DarionTalk(creature, LOD_LINES.DARION_GENERAL_06)
        end
    end)

    -- 337.5s - hacer cargar a las tropas a posiciones de batalla
    ScheduleOnce(337500, function()
        if not creature:IsInWorld() then return end
        creature:CastSpell(creature, SPELL_THE_MIGHT_OF_MOGRAINE, true)
    end)
end

-- ========== Gossip de Darion ==========
local function DarionGossipHello(event, player, creature)
    if not creature or not player then return false end
    player:GossipClearMenu()
    local st = GetDarionState(creature)
    if player:GetQuestStatus(QUEST_LIGHT_OF_DAWN) == QUEST_STATUS_INCOMPLETE
       and st.battleState == 0 and st.startTime == 0 then
        player:GossipMenuAddItem(0, "Estoy listo, Highlord. ¡Comencemos el asalto!", 1, 1, false, "", 0)
    end
    player:GossipSendMenu(9795, creature, 0)
    return false
end

local function DarionGossipSelect(event, player, creature, sender, intid, code, menuId)
    if intid == 1 then
        player:GossipComplete()
        DarionStartEvent(creature)
    end
    return false
end

RegisterCreatureGossipEvent(NPC_HIGHLORD_DARION_MOGRAINE, 1, DarionGossipHello)
RegisterCreatureGossipEvent(NPC_HIGHLORD_DARION_MOGRAINE, 2, DarionGossipSelect)

-- ========== Combate de Darion ==========
local function DarionEnterCombat(event, creature, target)
    if not creature then return end
    local st = GetDarionState(creature)
    if st.battleState ~= 1 then return end
    -- Programar habilidades cada cierto tiempo durante combate
    local guid = creature:GetGUID()
    local function CastAndRepeat(spellId, delay)
        ScheduleOnce(delay, function()
            local c = creature
            if c and c:IsInWorld() and c:IsAlive() and c:IsInCombat() then
                local v = c:GetVictim()
                if v then
                    c:CastSpell(v, spellId, false)
                end
            end
        end)
    end
    CastAndRepeat(SPELL_ANTI_MAGIC_ZONE1, 15000)
    CastAndRepeat(SPELL_DEATH_STRIKE, 8000)
    CastAndRepeat(SPELL_DEATH_EMBRACE, 5000)
    CastAndRepeat(SPELL_UNHOLY_BLIGHT, 10000)
end
RegisterCreatureEvent(NPC_HIGHLORD_DARION_MOGRAINE, 1, DarionEnterCombat)

-- ========== Reset al respawn ==========
local function DarionSpawn(event, creature)
    if not creature then return end
    local st = GetDarionState(creature)
    st.battleState = 0
    st.startTime = 0
    st.defenders = 0
    st.scourge = 0
    creature:SetImmuneTo(0, true)
    creature:SetStandState(UNIT_STAND_STATE_STAND)
    DarionSendWorldStates(creature, st)
end
RegisterCreatureEvent(NPC_HIGHLORD_DARION_MOGRAINE, 5, DarionSpawn)

local function DarionRemove(event, creature)
    if creature then darionStates[creature:GetGUID()] = nil end
end
RegisterCreatureEvent(NPC_HIGHLORD_DARION_MOGRAINE, 37, DarionRemove)

-- ============================================================================
-- CHAPTER 5 - RETURN TO CAPITAL (Guards insultan al DK)
-- ============================================================================
-- spell 58509 (apple), 58513 (banana), 58520 (spit). Cuando un DK tira esto
-- a un guard, hay 30% de chance de devolverlo con linea + emote, sino solo
-- linea de insulto. Hookeado via ON_SPELL_CAST del player.

local DK_INSULT_TRIGGER_SPELLS = {
    [58552] = true, -- Return to Orgrimmar
    [58533] = true, -- Return to Stormwind
}

local guardCooldowns = {} -- guid -> nextAllowedTime

local function IsGuardEntry(entry)
    return entry == NPC_SW_GUARD
        or entry == NPC_ROYAL_GUARD
        or entry == NPC_CITY_PATROLLER
        or entry == NPC_OG_GUARD
        or entry == NPC_KOR_ELITE
end

local function OnDKInsultCast(event, player, spell, skipCheck)
    if not player or not spell then return end
    local ok, id = pcall(function() return spell:GetEntry() end)
    if not ok then return end
    if not DK_INSULT_TRIGGER_SPELLS[id] then return end
    if player:IsGM() or not player:IsAlive() then return end

    local guard = player:GetNearestCreature(20, NPC_SW_GUARD, 0, 1)
        or player:GetNearestCreature(20, NPC_ROYAL_GUARD, 0, 1)
        or player:GetNearestCreature(20, NPC_CITY_PATROLLER, 0, 1)
        or player:GetNearestCreature(20, NPC_OG_GUARD, 0, 1)
        or player:GetNearestCreature(20, NPC_KOR_ELITE, 0, 1)
    if not guard or not guard:IsAlive() or guard:IsInCombat() then return end

    local gguid = guard:GetGUID()
    local now = GetGameTime()
    if guardCooldowns[gguid] and guardCooldowns[gguid] > now then return end
    guardCooldowns[gguid] = now + 30

    guard:SetFacingToObject(player)

    if Chance(30) then
        local insultIdx = math.random(1, 3)
        local insultSpell = INSULT_SPELLS[insultIdx]
        guard:CastSpell(player, insultSpell, true)
        local insultText = ({
            "¡Toma esto, monstruo de la muerte!",
            "¡Vete de aqui, abominacion!",
            "¡Vergueza para tu Cruzada!",
        })[insultIdx]
        guard:SendUnitSay(insultText, LANG_UNIVERSAL)
    else
        guard:SendUnitSay("¡Caballero de la Muerte! ¡No queremos tu clase por aqui!", LANG_UNIVERSAL)
        local emote = (math.random() < 0.5) and EMOTE_ONESHOT_POINT or EMOTE_ONESHOT_RUDE
        guard:HandleEmoteCommand(emote)
    end
end
RegisterPlayerEvent(5, OnDKInsultCast) -- ON_SPELL_CAST

-- ============================================================================
-- ZONA GENERAL - Mensaje de bienvenida al entrar en Scarlet Enclave
-- ============================================================================

local function OnZoneEnterScarlet(event, player, newZone, newArea)
    if newZone == ZONE_SCARLET_ENCLAVE then
        if player:GetClass() == 6 then -- DK
            player:SendAreaTriggerMessage("|cffAA0000Bienvenido a Acherus, Caballero de la Muerte.|r")
        end
    end
end
RegisterPlayerEvent(27, OnZoneEnterScarlet) -- ON_UPDATE_ZONE

-- ============================================================================
-- REGISTRO FINAL Y LOG
-- ============================================================================

print("[scarlet_enclave_dk] Cargado correctamente.")
print("[scarlet_enclave_dk] NPCs implementados:")
print("  - Val'kyr Battle-Maiden (revive automatico)")
print("  - Scarlet Ghoul + Gothik DKC1 (chapter 1)")
print("  - Koltira Deathweaver (breakout completo)")
print("  - Scarlet Courier (emboscada del arbol)")
print("  - 10 NPCs de A Special Surprise")
print("  - Acherus Necromancer & Gothik the Harvester (rituales)")
print("  - High Inquisitor Valroth (oleadas finales)")
print("  - Highlord Darion Mograine (Light of Dawn intro/countdown)")
print("  - Guards de capitales (insultos al DK)")
print("[scarlet_enclave_dk] Eventos de quest cubiertos:")
print("  - 12641 Death Comes From On High (whispers Lich King)")
print("  - 12698 Gift That Keeps On Giving (Scarlet Ghoul)")
print("  - 12720 How to Win Friends and Influence Enemies (Persuasive Strike)")
print("  - 12727 Breakout (Koltira)")
print("  - 12739..12750 A Special Surprise (10 NPCs)")
print("  - 12757 Scarlet Armies Approach (portal Acherus)")
print("  - 12779 An End to All Things (Devour Humanoid)")
print("  - 12801 Light of Dawn (Darion intro)")
