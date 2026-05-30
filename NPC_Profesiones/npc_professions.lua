-- Original author: pangolp (Walter Pagani)
-- Actualizado para mod-ale (AzerothCore Lua Engine) WotLK 3.3.5a
-- Correcciones: GossipMenuAddItem 7 params, GossipSetText local, nombres de params normalizados,
--               logica del boton Cerrar Menu corregida (se muestra cuando itemCount == 0)

local NPC_ENTRY = 200004
local SMSG_NPC_TEXT_UPDATE = 384
local MAX_GOSSIP_TEXT_OPTIONS = 8

local professions = {
    { id = 1, iconId = 3, skillId = 171, skillName = "Alquimia", spells = {3101, 3464, 11611, 28596, 51304} },
    { id = 2, iconId = 3, skillId = 393, skillName = "Desuello", spells = {8617, 8618, 10768, 32678, 50305} },
    { id = 3, iconId = 3, skillId = 333, skillName = "Encantamiento", spells = {7412, 7413, 13920, 28029, 51313} },
    { id = 4, iconId = 3, skillId = 164, skillName = "Herreria", spells = {3100, 3538, 9785, 29844, 51300} },
    { id = 5, iconId = 3, skillId = 202, skillName = "Ingeniería", spells = {4037, 4038, 12656, 30350, 51306} },
    { id = 6, iconId = 3, skillId = 773, skillName = "Inscripcion", spells = {45358, 45359, 45360, 45361, 45363} },
    { id = 7, iconId = 3, skillId = 755, skillName = "Joyeria", spells = {25230, 28894, 28895, 28897, 51311} },
    { id = 8, iconId = 3, skillId = 186, skillName = "Mineria", spells = {2576, 3564, 10248, 29354, 50310} },
    { id = 9, iconId = 3, skillId = 165, skillName = "Peleteria", spells = {3104, 3811, 10662, 32549, 51302} },
    { id = 10, iconId = 3, skillId = 197, skillName = "Sastreria", spells = {3909, 3910, 12180, 26790, 51309} },
    { id = 11, iconId = 3, skillId = 182, skillName = "Herboristeria", spells = {2368, 3570, 11993, 28695, 50300} },
    { id = 12, iconId = 3, skillId = 185, skillName = "Cocina", spells = {3102, 3413, 18260, 33359, 51296} },
    { id = 13, iconId = 3, skillId = 356, skillName = "Pesca", spells = {7731, 7732, 18248, 33095, 51294} },
    { id = 14, iconId = 3, skillId = 129, skillName = "Primeros auxilios", spells = {3274, 7924, 10846, 27028, 45542} },
}

local function GossipSetTextProfessions(player, text, textID)
    local data = CreatePacket(SMSG_NPC_TEXT_UPDATE, 100)
    data:WriteULong(textID or 0x7FFFFFFF)
    for i = 1, MAX_GOSSIP_TEXT_OPTIONS do
        data:WriteFloat(0) -- Probability
        data:WriteString(text) -- Text
        data:WriteString(text) -- Text
        data:WriteULong(0) -- language
        data:WriteULong(0) -- emote
        data:WriteULong(0) -- emote
        data:WriteULong(0) -- emote
        data:WriteULong(0) -- emote
        data:WriteULong(0) -- emote
        data:WriteULong(0) -- emote
    end
    player:SendPacket(data)
end

local function OnGossipHello(event, player, object)
    if (player:IsInCombat() == false) then
        player:GossipClearMenu()
        GossipSetTextProfessions(player, "Hola |c990B0Bee$n|h|r, soy Oscar Isidro Parrilli, actual senador nacional de la Argentina. Como tengo algo de tiempo libre en el Senado, el servidor de Wow, al que estás jugando me pidió que se ayude a subir aquellas profesiones que te dan pereza. $B$BEs SIMPLE, solamente debes ir, tomar la profesión esa que te da pereza subir y volver a hablar conmigo. Yo me encargare de subirte la profesión a 450. Eso sí, no te daré ninguna receta.")
        local itemCount = 0
        if (player:GetLevel() == 80) then
            for _, profession in pairs(professions) do
                if ((player:HasSkill(profession.skillId)) and (player:GetSkillValue(profession.skillId) ~= 450)) then
                    player:GossipMenuAddItem(profession.iconId, profession.skillName, 1, profession.id, false, "", 0)
                    itemCount = itemCount + 1
                end
            end
            -- Mostrar "Cerrar Menú" cuando no hay ninguna profesión que subir
            if (itemCount == 0) then
                player:GossipMenuAddItem(0, "Cerrar Menú", 0, 99, false, "", 0)
            end
        else
            player:SendAreaTriggerMessage("El jugador no es nivel 80.")
        end
        player:GossipSendMenu(0x7FFFFFFF, object)
    else
        player:SendAreaTriggerMessage("El jugador esta en combate.")
    end
end

local function OnGossipSelect(event, player, object, sender, intid, code, menuid)
    for _, profession in pairs(professions) do
        if (intid == profession.id) then
            for _, spell in ipairs(profession.spells) do
                if (player:HasSpell(spell) == false) then
                    player:LearnSpell(spell)
                end
            end
            player:AdvanceSkill(profession.skillId, player:GetMaxSkillValue(profession.skillId))
        end
    end
    player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnGossipSelect)
