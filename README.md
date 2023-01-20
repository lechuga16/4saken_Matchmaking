## Complementos de emparejamiento

![4saken](https://4saken.us/img/logo.c11e96a8.png)

- En el siguiente documento se explicará el funcionamiento de los complementos desarrollados para apoyar el funcionamiento del sitio web 4saken.us dentro de los servidores modificados competitivamente del videojuego ‘Left 4 Dead 2’.
- Se considerara que servidores utilizaran la configuración competitiva del repositorio de [L4D2-Competitive-Rework](https://github.com/SirPlease/L4D2-Competitive-Rework).

# Directorios 📁
- left4dead2: Este será el repositorio principal donde se desarrollaran los complementos básicos para el funcionamiento del sistema, en él se puede encontrar los complementos termínanos o en desarrollo.
- Adicionales: Se almacena los complementos secundarios, además de su configuración que se respalda por el reglamento ‘Integración al proyecto 4saken’.

# Estructura del proyecto
```
< Raíz del Proyecto >
  |
  |-- left4dead2/
  |    |
  |    |-- addons/
  |    |    |-- sourcemod/
  |    |         |
  |    |         |-- configs/
  |    |         |    |-- forsaken/
  |    |         |         |-- example_IP.json
  |    |         |         |-- Maps.json
  |    |         |
  |    |         |-- data/
  |    |         |    |-- system2/
  |    |         |         |-- linux/
  |    |         |         |    |-- amd64/
  |    |         |         |    |    |-- Codecs/
  |    |         |         |    |    |    |-- Rar.so
  |    |         |         |    |    |-- 7z
  |    |         |         |    |    |-- 7z.so
  |    |         |         |    |    |-- copyright
  |    |         |         |    |    |-- License.txt
  |    |         |         |    |
  |    |         |         |    |-- i386/
  |    |         |         |    |    |-- Codecs/
  |    |         |         |    |    |    |-- Rar.so
  |    |         |         |    |    |-- 7z
  |    |         |         |    |    |-- 7z.so
  |    |         |         |    |    |-- copyright
  |    |         |         |    |    |-- License.txt
  |    |         |         |    |
  |    |         |         |    |-- info.txt
  |    |         |         |    |-- License.txt
  |    |         |         |
  |    |         |         |-- ca-bundle.crt
  |    |         |
  |    |         |-- extensions/
  |    |         |    |-- system2.ext.so
  |    |         |
  |    |         |-- plugins/
  |    |         |    |-- matchmaking/
  |    |         |         |-- forsaken_endgame.smx
  |    |         |         |-- forsaken_jarvis.smx
  |    |         |         |-- forsaken_mmr.smx
  |    |         |         |-- forsaken_skills.smx
  |    |         |         |-- forsaken.smx
  |    |         |
  |    |         |-- scripting/
  |    |         |    |-- include/
  |    |         |    |    |-- kento_rankme/
  |    |         |    |    |     |-- cmds.inc
  |    |         |    |    |     |-- cvars.inc
  |    |         |    |    |     |-- natives.inc
  |    |         |    |    |     |-- rankme.inc
  |    |         |    |    |
  |    |         |    |    |-- SteamWorks.inc
  |    |         |    |    |-- builtinvotes.inc
  |    |         |    |    |-- chat-processor.inc
  |    |         |    |    |-- colors.inc
  |    |         |    |    |-- colorvariables.inc
  |    |         |    |    |-- hexstocks.inc
  |    |         |    |    |-- hextags.inc
  |    |         |    |    |-- hl_gangs.inc
  |    |         |    |    |-- l4d2_mission_manager.inc
  |    |         |    |    |-- logger.inc
  |    |         |    |    |-- mostactive.inc
  |    |         |    |    |-- myjbwarden.inc
  |    |         |    |    |-- smac.inc
  |    |         |    |    |-- smac_cvars.inc
  |    |         |    |    |-- smac_stocks.inc
  |    |         |    |    |-- smac_wallhack.inc
  |    |         |    |    |-- warden.inc
  |    |         |    |
  |    |         |    |-- lilac/
  |    |         |    |    |-- lilac_aimbot.sp
  |    |         |    |    |-- lilac_aimlock.sp
  |    |         |    |    |-- lilac_angles.sp
  |    |         |    |    |-- lilac_anti_duck_delay.sp
  |    |         |    |    |-- lilac_backtrack.sp
  |    |         |    |    |-- lilac_bhop.sp
  |    |         |    |    |-- lilac_config.sp
  |    |         |    |    |-- lilac_convar.sp
  |    |         |    |    |-- lilac_database.sp
  |    |         |    |    |-- lilac_globals.sp
  |    |         |    |    |-- lilac_lerp.sp
  |    |         |    |    |-- lilac_macro.sp
  |    |         |    |    |-- lilac_noisemaker.sp
  |    |         |    |    |-- lilac_ping.sp
  |    |         |    |    |-- lilac_stock.sp
  |    |         |    |    |-- lilac_string.sp
  |    |         |    |
  |    |         |    |-- updater/
  |    |         |    |    |-- api.sp
  |    |         |    |    |-- download.sp
  |    |         |    |    |-- download_steamworks.sp
  |    |         |    |    |-- filesys.sp
  |    |         |    |    |-- plugins.sp
  |    |         |    |
  |    |         |    |-- SaveChat.sp
  |    |         |    |-- chat-processor.sp
  |    |         |    |-- hextags.sp
  |    |         |    |-- l4d2_block_medikits.sp
  |    |         |    |-- l4d2_familyshare.sp
  |    |         |    |-- l4d2_list_missions.sp
  |    |         |    |-- l4d2_mission_manager.sp
  |    |         |    |-- l4d2_vote_manager3.sp
  |    |         |    |-- lilac.sp
  |    |         |
  |    |         |-- translations/
  |    |              |-- es/
  |    |              |    |-- l4d2_familyshare.phrases.txt
  |    |              |    |-- l4d2_vote_manager.phrases.txt
  |    |              |    |-- lilac.phrases.txt
  |    |              |    |-- smac.phrases.txt
  |    |              |    |-- sourcetv_antikick.phrases.txt
  |    |              |    |-- vacbans2.phrases.txt
  |    |              |    |-- vote_custom_campaigns.phrases.txt
  |    |              |
  |    |              |-- l4d2_familyshare.phrases.txt
  |    |              |-- l4d2_vote_manager.phrases.txt
  |    |              |-- lilac.phrases.txt
  |    |              |-- maps.phrases.txt
  |    |              |-- missions.phrases.txt
  |    |              |-- smac.phrases.txt
  |    |              |-- sourcetv_antikick.phrases.txt
  |    |              |-- vacbans2.phrases.txt
  |    |              |-- vote_custom_campaigns.phrases.txt
  |    |
  |    |
  |    |
  |    |
  |    |
  |    |
  |    |-- cfg/
  |         |-- sourcemod/
  |              |-- forsaken_endgame.cfg
  |              |-- forsaken_jarvis.cfg
  |              |-- forsaken_mmr.cfg
  |              |-- forsaken_skills.cfg
  |              |-- forsaken.cfg
  |
  |-- README.md
```
