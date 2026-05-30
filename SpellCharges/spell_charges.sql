-- ============================================================================
-- spell_charges.sql
-- ----------------------------------------------------------------------------
-- Database: acore_world  (WorldDB)
-- Run this script against the WORLD database, NOT the characters database.
--
-- Example (from a mysql client):
--   mysql -u acore -p acore_world < spell_charges.sql
--
-- The Lua script (spell_charges.lua) also calls CREATE TABLE IF NOT EXISTS on
-- startup, so the table will be auto-created. This file lets you pre-seed the
-- configuration before the server starts and document the expected schema.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `spell_charges_spells` (
  `spell_id` INT UNSIGNED NOT NULL,
  `group_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `max_charges` TINYINT UNSIGNED NOT NULL,
  `base_cooldown` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- Schema notes
-- ----------------------------------------------------------------------------
-- spell_id      : WotLK 3.3.5a spell ID (see Spell.dbc / acore_world.spell_*)
-- group_id      : 0 = this spell has its own private charge pool.
--                 Any non-zero value means "share charges with every other
--                 row that has the same group_id" (use this for ranks or for
--                 spells you want to put on a shared resource).
-- max_charges   : Total charges available (must be >= 2 for the script to
--                 register the spell — otherwise it's just a normal cooldown).
-- base_cooldown : Recharge time per charge, in MILLISECONDS.
--                 Example: 30000 = 30 seconds per recharge.
--
-- The Lua script will ignore rows with max_charges < 2 or base_cooldown <= 0.
-- ----------------------------------------------------------------------------

-- ============================================================================
-- WotLK 3.3.5a EXAMPLES (commented out — uncomment the ones you want)
-- ============================================================================

-- --------------------------------------------------------------------------
-- Example 1: Heroism / Bloodlust as a charge-based raid cooldown
--   Instead of the normal 10-minute cooldown, give shamans 2 charges that
--   recharge every 5 minutes (300000 ms). Both spells share the same pool
--   via group_id = 32182 so that a Horde shaman who specs into Heroism via
--   a glyph etc. cannot bypass the limit by alternating spell IDs.
-- --------------------------------------------------------------------------
-- INSERT INTO `spell_charges_spells` (`spell_id`, `group_id`, `max_charges`, `base_cooldown`)
-- VALUES
--   (32182, 32182, 2, 300000),   -- Heroism  (Alliance shaman)
--   (2825,  32182, 2, 300000)    -- Bloodlust (Horde shaman)
-- ON DUPLICATE KEY UPDATE
--   `group_id` = VALUES(`group_id`),
--   `max_charges` = VALUES(`max_charges`),
--   `base_cooldown` = VALUES(`base_cooldown`);

-- --------------------------------------------------------------------------
-- Example 2: Priest Flash Heal — 3 quick charges, each recharging in 8s
--   Useful for a "burst healing" feel. All ranks share one pool via
--   group_id = 2061 so leveling alts don't get a fresh pool per rank.
-- --------------------------------------------------------------------------
-- INSERT INTO `spell_charges_spells` (`spell_id`, `group_id`, `max_charges`, `base_cooldown`)
-- VALUES
--   (2061,  2061, 3, 8000),    -- Flash Heal Rank 1
--   (9472,  2061, 3, 8000),    -- Flash Heal Rank 2
--   (9473,  2061, 3, 8000),    -- Flash Heal Rank 3
--   (9474,  2061, 3, 8000),    -- Flash Heal Rank 4
--   (10915, 2061, 3, 8000),    -- Flash Heal Rank 5
--   (10916, 2061, 3, 8000),    -- Flash Heal Rank 6
--   (10917, 2061, 3, 8000),    -- Flash Heal Rank 7
--   (25233, 2061, 3, 8000),    -- Flash Heal Rank 8
--   (25235, 2061, 3, 8000),    -- Flash Heal Rank 9
--   (48070, 2061, 3, 8000),    -- Flash Heal Rank 10
--   (48071, 2061, 3, 8000)     -- Flash Heal Rank 11
-- ON DUPLICATE KEY UPDATE
--   `group_id` = VALUES(`group_id`),
--   `max_charges` = VALUES(`max_charges`),
--   `base_cooldown` = VALUES(`base_cooldown`);

-- --------------------------------------------------------------------------
-- Example 3: Warrior Shield Bash — 2 charges, 12s recharge
--   Lets warriors interrupt twice in a short window but throttles total
--   interrupt uptime. Both ranks share the pool via group_id = 72.
-- --------------------------------------------------------------------------
-- INSERT INTO `spell_charges_spells` (`spell_id`, `group_id`, `max_charges`, `base_cooldown`)
-- VALUES
--   (72,   72, 2, 12000),   -- Shield Bash Rank 1
--   (1671, 72, 2, 12000),   -- Shield Bash Rank 2
--   (1672, 72, 2, 12000),   -- Shield Bash Rank 3
--   (29704,72, 2, 12000)    -- Shield Bash Rank 4
-- ON DUPLICATE KEY UPDATE
--   `group_id` = VALUES(`group_id`),
--   `max_charges` = VALUES(`max_charges`),
--   `base_cooldown` = VALUES(`base_cooldown`);

-- --------------------------------------------------------------------------
-- Example 4: Mage Blink — 2 charges, 15s recharge
--   Classic "charge-based mobility" feel. Single spell ID so group_id = 0
--   (which the Lua script auto-normalizes to use spell_id as the pool key).
-- --------------------------------------------------------------------------
-- INSERT INTO `spell_charges_spells` (`spell_id`, `group_id`, `max_charges`, `base_cooldown`)
-- VALUES
--   (1953, 0, 2, 15000)     -- Blink
-- ON DUPLICATE KEY UPDATE
--   `group_id` = VALUES(`group_id`),
--   `max_charges` = VALUES(`max_charges`),
--   `base_cooldown` = VALUES(`base_cooldown`);

-- --------------------------------------------------------------------------
-- Generic template (copy / paste / edit)
-- --------------------------------------------------------------------------
-- INSERT INTO `spell_charges_spells` (`spell_id`, `group_id`, `max_charges`, `base_cooldown`)
-- VALUES
--   (12345, 12345, 2, 30000),
--   (12346, 12345, 2, 30000)
-- ON DUPLICATE KEY UPDATE
--   `group_id` = VALUES(`group_id`),
--   `max_charges` = VALUES(`max_charges`),
--   `base_cooldown` = VALUES(`base_cooldown`);
