-- Original author: pangolp (Walter Pagani)
-- Actualizado para mod-ale (AzerothCore Lua Engine) WotLK 3.3.5a
-- Correcciones: GossipMenuAddItem 7 params en todos los items, GossipSetText local,
--               variables quests y questRewardStatus locales en callbacks, indentacion normalizada,
--               auto-registro en DB via WorldDBQuery/WorldDBExecute (solo inserta si no existe)

local npcEntry = 200003
local SMSG_NPC_TEXT_UPDATE = 384
local MAX_GOSSIP_TEXT_OPTIONS = 8

local ALIANZA = 0
local HORDA   = 1

-- Auto-registro en DB: solo inserta si no existe.
-- Si se inserta por primera vez, reiniciar el servidor para que el cache se actualice.
local function InitNPC()
    local e = npcEntry
    if not WorldDBQuery("SELECT 1 FROM creature_template WHERE entry=" .. e .. " LIMIT 1") then
        WorldDBExecute("INSERT INTO `creature_template` (`entry`,`difficulty_entry_1`,`difficulty_entry_2`,`difficulty_entry_3`,`KillCredit1`,`KillCredit2`,`name`,`subname`,`IconName`,`gossip_menu_id`,`minlevel`,`maxlevel`,`exp`,`faction`,`npcflag`,`speed_walk`,`speed_run`,`speed_swim`,`speed_flight`,`detection_range`,`rank`,`dmgschool`,`DamageModifier`,`BaseAttackTime`,`RangeAttackTime`,`BaseVariance`,`RangeVariance`,`unit_class`,`unit_flags`,`unit_flags2`,`dynamicflags`,`family`,`type`,`type_flags`,`lootid`,`pickpocketloot`,`skinloot`,`PetSpellDataId`,`VehicleId`,`mingold`,`maxgold`,`AIName`,`MovementType`,`HoverHeight`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`ExperienceModifier`,`RacialLeader`,`movementId`,`RegenHealth`,`CreatureImmunitiesId`,`flags_extra`,`ScriptName`,`VerifiedBuild`) VALUES (" .. e .. ",0,0,0,0,0,'Jaime Stiuso','Reputaciones Rasganorte',NULL,0,83,83,2,35,1,1,1,1,1,20,3,0,35,2000,2000,1,1,1,768,2048,0,0,6,36,0,0,0,0,0,0,0,'',0,1,2000,1,1,1,0,0,1,0,2,'',12340)")
        WorldDBExecute("INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (" .. e .. ",0,18718,1,1,0)")
        print("[npc_misiones_rasganorte] creature_template " .. e .. " insertado — reinicia el servidor para activarlo")
    end
    if not WorldDBQuery("SELECT 1 FROM creature WHERE id1=" .. e .. " LIMIT 1") then
        WorldDBExecute("INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (4000003," .. e .. ",0,0,571,0,0,1,1,0,5787.9,443.588,658.783,0.190944,300,0,0,27890000,0,0,0,0,0,'',0,0,'NPC Reputaciones Rasganorte')")
        print("[npc_misiones_rasganorte] Spawn " .. e .. " insertado en creature")
    end
end
InitNPC()

local function GossipSetTextRep(player, text, textID)
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
        GossipSetTextRep(player, "Hola $c. Soy Jaime. Trabajo para los servicios de inteligencia, no puedo contarte demasiado, pero debido a que a veces subir las reputaciones con estas facciones lleva tiempo y estamos probando el contenido, me dijeron que puedo completarte algunas misiones para ver intendentes y que puedas usar determinados ítems que requieren de esas reputaciones. Dime que reputación de la lista quieres subir…$B$BPD. Tenes que ser nivel 80 para poder usar este servicio.")
        if (player:GetLevel() == 80) then
            if (player:GetTeam() == ALIANZA) then
                if (player:GetQuestRewardStatus(12898) == false) then
                    player:GossipMenuAddItem(0, '¡Los caballeros de la Espada de Ébano!', 1, 10, false, "", 0)
                end
                if (player:GetReputation(1090) ~= 42999) then
                    player:GossipMenuAddItem(0, '¡Kirin Tor!', 1, 11, false, "", 0)
                end
                if (player:GetReputation(1091) ~= 42999) then
                    player:GossipMenuAddItem(0, '¡El Acuerdo del Reposo del Dragón!', 1, 12, false, "", 0)
                end
                if (player:GetReputation(1156) ~= 42999) then
                    player:GossipMenuAddItem(0, '¡El Veredicto Cinéreo!', 1, 13, false, "", 0)
                end
                if (player:GetQuestRewardStatus(12924) == false) then
                    player:GossipMenuAddItem(0, '¡Los Hijos de Hodir!', 1, 14, false, "", 0)
                end
                if (player:GetReputation(1106) ~= 42999) then
                    player:GossipMenuAddItem(0, '¡Cruzada Argenta!', 1, 15, false, "", 0)
                end
            else
                if (player:GetQuestRewardStatus(12899) == false) then
                    player:GossipMenuAddItem(0, '¡Los caballeros de la Espada de Ébano!', 1, 10, false, "", 0)
                end
                if (player:GetReputation(1090) ~= 42999) then
                    player:GossipMenuAddItem(0, '¡Kirin Tor!', 1, 11, false, "", 0)
                end
                if (player:GetReputation(1091) ~= 42999) then
                    player:GossipMenuAddItem(0, '¡El Acuerdo del Reposo del Dragón!', 1, 12, false, "", 0)
                end
                if (player:GetReputation(1156) ~= 42999) then
                    player:GossipMenuAddItem(0, '¡El Veredicto Cinéreo!', 1, 13, false, "", 0)
                end
                if (player:GetQuestRewardStatus(12924) == false) then
                    player:GossipMenuAddItem(0, '¡Los Hijos de Hodir!', 1, 14, false, "", 0)
                end
                if (player:GetReputation(1106) ~= 42999) then
                    player:GossipMenuAddItem(0, '¡Cruzada Argenta!', 1, 15, false, "", 0)
                end
            end
        end
        player:GossipSendMenu(0x7FFFFFFF, object)
    end
end

local function OnGossipSelect(event, player, object, sender, intid, code, menuid)
    if (intid == 10) then
        local quests
        if (player:GetTeam() == ALIANZA) then
            quests = {12887, 12891, 12893, 12896, 12898}
        else
            quests = {12892, 12891, 12893, 12897, 12899}
        end
        for i, quest in ipairs(quests) do
            local questRewardStatus = player:GetQuestRewardStatus(quest)
            if (questRewardStatus == false) then
                player:AddQuest(quest)
                player:CompleteQuest(quest)
                player:RewardQuest(quest)
            end
        end
        player:SetReputation(1098, 42999)
    end
    if (intid == 11) then
        player:SetReputation(1090, 42999)
    end
    if (intid == 12) then
        player:SetReputation(1091, 42999)
    end
    if (intid == 13) then
        player:SetReputation(1156, 42999)
    end
    if (intid == 14) then
        local quests = {12843, 12846, 12841, 12905, 12906, 12907, 12908, 12921, 12969, 12970, 12971, 12972, 12851, 12856, 13063, 12900, 12983, 12996, 12997, 13061, 13062, 12886, 13064, 12915, 12922, 12956, 12915, 12924}
        for i, quest in ipairs(quests) do
            local questRewardStatus = player:GetQuestRewardStatus(quest)
            if (questRewardStatus == false) then
                player:AddQuest(quest)
                player:CompleteQuest(quest)
                player:RewardQuest(quest)
            end
        end
        player:SetReputation(1119, 42999)
    end
    if (intid == 15) then
        player:SetReputation(1106, 42999)
    end
    player:GossipComplete()
end

RegisterCreatureGossipEvent(npcEntry, 1, OnGossipHello)
RegisterCreatureGossipEvent(npcEntry, 2, OnGossipSelect)
