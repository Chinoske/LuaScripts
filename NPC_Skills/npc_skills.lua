-- Original author: pangolp (Walter Pagani)
-- Actualizado para mod-ale (AzerothCore Lua Engine) WotLK 3.3.5a
-- Correcciones: GossipMenuAddItem 7 params, GossipSetText local, checkSpells local,
--               logica de "Aprender todo" simplificada, nombres de params normalizados,
--               auto-registro en DB via WorldDBQuery/WorldDBExecute (solo inserta si no existe)

local NPC_ENTRY = 200005
local SMSG_NPC_TEXT_UPDATE = 384
local MAX_GOSSIP_TEXT_OPTIONS = 8

local skills = {
    { id = 1,  spellId = 264,  skillId = 45,  skillName = 'Arcos' },
    { id = 2,  spellId = 5011, skillId = 226, skillName = 'Ballestas' },
    { id = 3,  spellId = 2567, skillId = 176, skillName = 'Armas arrojadizas' },
    { id = 4,  spellId = 1180, skillId = 173, skillName = 'Dagas' },
    { id = 5,  spellId = 200,  skillId = 229, skillName = 'Arma de asta' },
    { id = 6,  spellId = 198,  skillId = 54,  skillName = 'Mazas' },
    { id = 7,  spellId = 199,  skillId = 160, skillName = 'Mazas de dos manos' },
    { id = 8,  spellId = 266,  skillId = 46,  skillName = 'Armas de fuego' },
    { id = 9,  spellId = 201,  skillId = 43,  skillName = 'Espadas de una mano' },
    { id = 10, spellId = 202,  skillId = 55,  skillName = 'Espadas de dos manos' },
    { id = 11, spellId = 5009, skillId = 228, skillName = 'Varitas' },
    { id = 12, spellId = 196,  skillId = 44,  skillName = 'Hachas de una mano' },
    { id = 13, spellId = 197,  skillId = 172, skillName = 'Hachas de dos manos' },
    { id = 14, spellId = 227,  skillId = 136, skillName = 'Bastones' },
    { id = 15, spellId = 204,  skillId = 95,  skillName = 'Defensa' },
    { id = 16, spellId = 203,  skillId = 162, skillName = 'Sin armas' },
}

-- Auto-registro en DB: solo inserta si no existe.
-- Si se inserta por primera vez, reiniciar el servidor para que el cache se actualice.
local function InitNPC()
    local e = NPC_ENTRY
    if not WorldDBQuery("SELECT 1 FROM creature_template WHERE entry=" .. e .. " LIMIT 1") then
        WorldDBExecute("INSERT INTO `creature_template` (`entry`,`difficulty_entry_1`,`difficulty_entry_2`,`difficulty_entry_3`,`KillCredit1`,`KillCredit2`,`name`,`subname`,`IconName`,`gossip_menu_id`,`minlevel`,`maxlevel`,`exp`,`faction`,`npcflag`,`speed_walk`,`speed_run`,`speed_swim`,`speed_flight`,`detection_range`,`rank`,`dmgschool`,`DamageModifier`,`BaseAttackTime`,`RangeAttackTime`,`BaseVariance`,`RangeVariance`,`unit_class`,`unit_flags`,`unit_flags2`,`dynamicflags`,`family`,`type`,`type_flags`,`lootid`,`pickpocketloot`,`skinloot`,`PetSpellDataId`,`VehicleId`,`mingold`,`maxgold`,`AIName`,`MovementType`,`HoverHeight`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`ExperienceModifier`,`RacialLeader`,`movementId`,`RegenHealth`,`CreatureImmunitiesId`,`flags_extra`,`ScriptName`,`VerifiedBuild`) VALUES (" .. e .. ",0,0,0,0,0,'René Favaloro','Skills: 400',NULL,0,83,83,2,35,1,1,1,1,1,20,3,0,35,2000,2000,1,1,1,768,2048,0,0,6,36,0,0,0,0,0,0,0,'',0,1,2000,1,1,1,0,0,1,0,2,'',0)")
        WorldDBExecute("INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES (" .. e .. ",0,18718,1,1,0)")
        print("[npc_skills] creature_template " .. e .. " insertado — reinicia el servidor para activarlo")
    end
    if not WorldDBQuery("SELECT 1 FROM creature WHERE id1=" .. e .. " LIMIT 1") then
        WorldDBExecute("INSERT INTO `creature` (`guid`,`id1`,`id2`,`id3`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES (4000005," .. e .. ",0,0,571,0,0,1,1,0,5791.41,434.75,658.783,0.578921,300,0,0,27890000,0,0,0,0,0,'',0,0,'NPC Skills 400')")
        print("[npc_skills] Spawn " .. e .. " insertado en creature")
    end
end
InitNPC()

local function GossipSetTextSkills(player, text, textID)
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

-- Devuelve true si hay al menos una habilidad aprendida que no está al máximo (400)
local function checkSpells(skillList, player)
    local missingSkillCount = 0
    for _, value in pairs(skillList) do
        if ((player:HasSpell(value.spellId)) and (player:GetSkillValue(value.skillId) ~= 400)) then
            missingSkillCount = missingSkillCount + 1
        end
    end
    return missingSkillCount > 0
end

local function OnGossipHello(event, player, object)
    if (player:IsInCombat() == false) then
        player:GossipClearMenu()
        GossipSetTextSkills(player, "Saludos |c990B0Bee$n|h|r. Bienvenido al Servidor. Mi objetivo es subirte la habilidad de armas hasta el 400. Pero primero necesitas visitar el instructor para aprender dicha habilidad si no la conoces.$B$B- Requiere nivel 80.$B- Requiere conocer la habilidad.")
        if (player:GetLevel() == 80) then
            for _, value in pairs(skills) do
                if ((player:HasSpell(value.spellId)) and (player:GetSkillValue(value.skillId) ~= 400)) then
                    player:GossipMenuAddItem(0, value.skillName, 1, value.id, false, "", 0)
                end
            end
            if checkSpells(skills, player) then
                player:GossipMenuAddItem(0, 'Aprender todo', 1, #skills + 1, false, "", 0)
            end
        end
        player:GossipSendMenu(0x7FFFFFFF, object)
    end
end

local function OnGossipSelect(event, player, object, sender, intid, code, menuid)
    for _, value in pairs(skills) do
        if (intid == value.id) then
            player:AdvanceSkill(value.skillId, player:GetMaxSkillValue(value.skillId))
        end
    end
    if (intid == #skills + 1) then
        player:AdvanceSkillsToMax()
    end
    player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnGossipSelect)
