-- ============================================================================
-- LevelStats — SQL de instalacion
-- ============================================================================
-- Ejecutar en la base de datos de personajes (acore_characters):
--   mysql -u acore -p acore_characters < LevelStats_db.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS `custom_level_stats` (
  `guid` INT UNSIGNED NOT NULL,
  `str`  INT UNSIGNED NOT NULL DEFAULT 0,
  `agi`  INT UNSIGNED NOT NULL DEFAULT 0,
  `sta`  INT UNSIGNED NOT NULL DEFAULT 0,
  `int`  INT UNSIGNED NOT NULL DEFAULT 0,
  `spi`  INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
