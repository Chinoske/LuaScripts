-- Original author: pangolp (Walter Pagani)
-- Actualizado para mod-ale (AzerothCore Lua Engine) WotLK 3.3.5a
-- Correcciones: GossipMenuAddItem 7 params, GossipSetText local, variables locales en callbacks,
--               auto-registro en DB via WorldDBQuery/WorldDBExecute (solo inserta si no existe)

local npcEntry = 200000
local SMSG_NPC_TEXT_UPDATE = 384
local MAX_GOSSIP_TEXT_OPTIONS = 8

-- Razas
local HUMANO        = 1
local ORCO          = 2
local ENANO         = 3
local ELFO_NOCTURNO = 4
local NO_MUERTO     = 5
local TAUREN        = 6
local GNOMO         = 7
local TROLL         = 8
local ELFO_DE_SANGRE = 10
local DRAENEI       = 11

-- Auto-registro en DB: solo inserta si no existe.
-- Si se inserta por primera vez, reiniciar el servidor para que el cache se actualice.
local function InitNPC()
    local e = npcEntry
    if not WorldDBQuery("SELECT 1 FROM creature_template WHERE entry=" .. e .. " LIMIT 1") then
        WorldDBExecute("INSERT INTO `creature_template` (`entry`,`difficulty_entry_1`,`difficulty_entry_2`,`difficulty_entry_3`,`KillCredit1`,`KillCredit2`,`name`,`subname`,`IconName`,`gossip_menu_id`,`minlevel`,`maxlevel`,`exp`,`faction`,`npcflag`,`speed_walk`,`speed_run`,`speed_swim`,`speed_flight`,`detection_range`,`rank`,`dmgschool`,`DamageModifier`,`BaseAttackTime`,`RangeAttackTime`,`BaseVariance`,`RangeVariance`,`unit_class`,`unit_flags`,`unit_flags2`,`dynamicflags`,`family`,`type`,`type_flags`,`lootid`,`pickpocketloot`,`skinloot`,`PetSpellDataId`,`VehicleId`,`mingold`,`maxgold`,`AIName`,`MovementType`,`HoverHeight`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`ExperienceModifier`,`RacialLeader`,`movementId`,`RegenHealth`,`CreatureImmunitiesId`,`flags_extra`,`ScriptName`,`VerifiedBuild`) VALUES (" .. e .. ",0,0,0,0,0,'The Lich King','Completar misiones dk',NULL,0,83,83,2,35,1,1,1,1,1,20,3,0,35,2000,2000,1,1,1,768,2048,0,0,6,36,0,0,0,0,0,0,0,'',0,1,2000,1,1,1,0,0,1,0,2,'',12340)")
        WorldDBExecute("INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (" .. e .. ",0,24191,1,1,0)")
        print("[npc_misiones_dk] creature_template " .. e .. " insertado — reinicia el servidor para activarlo")
    end
    if not WorldDBQuery("SELECT 1 FROM creature WHERE id1=" .. e .. " LIMIT 1") then
        WorldDBExecute("INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (4000000," .. e .. ",0,0,609,0,0,1,1,0,2375.24,-5650.85,426.127,3.766,300,0,0,27890000,0,0,1,0,0,'',0,0,'NPC Completar misiones DK')")
        print("[npc_misiones_dk] Spawn " .. e .. " insertado en creature")
    end
end
InitNPC()

local function GossipSetTextDK(player, text, textID)
    local data = CreatePacket(SMSG_NPC_TEXT_UPDATE, 100)
    data:WriteULong(textID or 0x7FFFFFFF)
    for i = 1, MAX_GOSSIP_TEXT_OPTIONS do
        data:WriteFloat(0)
        data:WriteString(text)
        data:WriteString(text)
        data:WriteULong(0)
        data:WriteULong(0)
        data:WriteULong(0)
        data:WriteULong(0)
        data:WriteULong(0)
        data:WriteULong(0)
        data:WriteULong(0)
    end
    player:SendPacket(data)
end

local function OnGossipHello(event, player, object)
    if (player:IsInCombat() == false) then
        player:GossipClearMenu()
        GossipSetTextDK(player, "Saludos $n. Debido a que me han dicho que te pachorra completas todas la misiones que te he encomendado, y a que mi ejercito cada vez está más corto de gente, decidí completarte las misiones así podes seguir con tu aventura. Pero no vayas a unir a la alianza o la horda, recorda que te traje a este mundo que me dieras una mano. Nos vemos.$B$BPD. Nos vemos en el trono de hielo traidor.")
        local teamId = player:GetTeam()
        local questRewardStatus
        if (teamId == 0) then
            questRewardStatus = player:GetQuestRewardStatus(13188)
        else
            questRewardStatus = player:GetQuestRewardStatus(13189)
        end
        if ((player:GetClass() == 6) and (questRewardStatus == false)) then
            player:GossipMenuAddItem(0, '¡Completame las misiones por favor!', 1, 10, false, "", 0)
        end
        player:GossipSendMenu(0x7FFFFFFF, object)
    end
end

local function OnGossipSelect(event, player, object, sender, intid, code, menuid)
    if (intid == 10) then
        local quests = {12593, 12619, 12842, 12848, 12636, 12641, 12657, 12850, 12670, 12678, 12680, 12687, 12679, 12733, 12711, 12697, 12698, 12700, 12701, 12706, 12714, 12849, 12715, 12716, 12717, 12718, 12719, 12722, 12720, 12723, 12724, 12725, 12727, 12738, 12751, 12754, 12755, 12756, 12757, 12778, 12779, 12800, 12801, 13165, 13166}
        for i, quest in ipairs(quests) do
            local questRewardStatus = player:GetQuestRewardStatus(quest)
            if (questRewardStatus == false) then
                player:AddQuest(quest)
                player:CompleteQuest(quest)
                player:RewardQuest(quest)
            end
        end
        local teamId = player:GetTeam()
        if (teamId == 0) then
            local questRewardStatus = player:GetQuestRewardStatus(13188)
            if (questRewardStatus == false) then
                if (player:GetRace() == HUMANO)        then player:AddQuest(12742) player:CompleteQuest(12742) player:RewardQuest(12742) end
                if (player:GetRace() == ELFO_NOCTURNO) then player:AddQuest(12743) player:CompleteQuest(12743) player:RewardQuest(12743) end
                if (player:GetRace() == DRAENEI)       then player:AddQuest(12746) player:CompleteQuest(12746) player:RewardQuest(12746) end
                if (player:GetRace() == ENANO)         then player:AddQuest(12744) player:CompleteQuest(12744) player:RewardQuest(12744) end
                if (player:GetRace() == GNOMO)         then player:AddQuest(12745) player:CompleteQuest(12745) player:RewardQuest(12745) end
                player:AddQuest(13188)
                player:CompleteQuest(13188)
                player:RewardQuest(13188)
                player:CastSpell(player, 17334, false) -- TP Ventormenta
            end
        end
        if (teamId == 1) then
            local questRewardStatus = player:GetQuestRewardStatus(13189)
            if (questRewardStatus == false) then
                if (player:GetRace() == ELFO_DE_SANGRE) then player:AddQuest(12747) player:CompleteQuest(12747) player:RewardQuest(12747) end
                if (player:GetRace() == ORCO)           then player:AddQuest(12748) player:CompleteQuest(12748) player:RewardQuest(12748) end
                if (player:GetRace() == TAUREN)         then player:AddQuest(12739) player:CompleteQuest(12739) player:RewardQuest(12739) end
                if (player:GetRace() == NO_MUERTO)      then player:AddQuest(12750) player:CompleteQuest(12750) player:RewardQuest(12750) end
                if (player:GetRace() == TROLL)          then player:AddQuest(12749) player:CompleteQuest(12749) player:RewardQuest(12749) end
                player:AddQuest(13189)
                player:CompleteQuest(13189)
                player:RewardQuest(13189)
                player:CastSpell(player, 17609, false) -- TP Orgrimmar
            end
        end
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(npcEntry, 1, OnGossipHello)
RegisterCreatureGossipEvent(npcEntry, 2, OnGossipSelect)
