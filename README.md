## Complementos de emparejamiento

![4saken](https://4saken.us/img/logo.c11e96a8.png)

- En el siguiente documento se explicará el funcionamiento de los complementos desarrollados para apoyar el funcionamiento del sitio web 4saken.us dentro de los servidores modificados competitivamente del videojuego ‘Left 4 Dead 2’.
- Se considerara que servidores utilizaran la configuración competitiva del repositorio de [L4D2-Competitive-Rework](https://github.com/SirPlease/L4D2-Competitive-Rework).

# Directorios 📁
- left4dead2: Este será el repositorio principal donde se desarrollaran los complementos básicos para el funcionamiento del sistema, en él se puede encontrar los complementos termínanos o en desarrollo.
- Adicionales: Se almacena los complementos secundarios, además de su configuración que se respalda por el reglamento ‘Integración al proyecto 4saken’.

# Estructura del proyecto
```
📦left4dead2
 ┣ 📂addons
 ┃ ┗ 📂sourcemod
 ┃ ┃ ┣ 📂configs
 ┃ ┃ ┃ ┗ 📂forsaken
 ┃ ┃ ┃ ┃ ┣ 📜example_IP.json
 ┃ ┃ ┃ ┃ ┗ 📜Maps.json
 ┃ ┃ ┣ 📂data
 ┃ ┃ ┃ ┗ 📂system2
 ┃ ┃ ┃ ┃ ┣ 📂linux
 ┃ ┃ ┃ ┃ ┃ ┣ 📂amd64
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📂Codecs
 ┃ ┃ ┃ ┃ ┃ ┃ ┃ ┗ 📜Rar.so
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜7z
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜7z.so
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜copyright
 ┃ ┃ ┃ ┃ ┃ ┃ ┗ 📜License.txt
 ┃ ┃ ┃ ┃ ┃ ┣ 📂i386
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📂Codecs
 ┃ ┃ ┃ ┃ ┃ ┃ ┃ ┗ 📜Rar.so
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜7z
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜7z.so
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜copyright
 ┃ ┃ ┃ ┃ ┃ ┃ ┗ 📜License.txt
 ┃ ┃ ┃ ┃ ┃ ┣ 📜info.txt
 ┃ ┃ ┃ ┃ ┃ ┗ 📜License.txt
 ┃ ┃ ┃ ┃ ┗ 📜ca-bundle.crt
 ┃ ┃ ┣ 📂extensions
 ┃ ┃ ┃ ┗ 📜system2.ext.so
 ┃ ┃ ┣ 📂plugins
 ┃ ┃ ┃ ┗ 📂matchmaking
 ┃ ┃ ┃ ┃ ┣ 📜forsaken.smx
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_endgame.smx
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_jarvis.smx
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_mmr.smx
 ┃ ┃ ┃ ┃ ┗ 📜forsaken_skills.smx
 ┃ ┃ ┣ 📂scripting
 ┃ ┃ ┃ ┣ 📂forsaken
 ┃ ┃ ┃ ┃ ┣ 📜jarvis_ban.sp
 ┃ ┃ ┃ ┃ ┣ 📜jarvis_blockvote.sp
 ┃ ┃ ┃ ┃ ┣ 📜jarvis_checkmatch.sp
 ┃ ┃ ┃ ┃ ┣ 📜jarvis_prematch.sp
 ┃ ┃ ┃ ┃ ┣ 📜jarvis_ragequit.sp
 ┃ ┃ ┃ ┃ ┣ 📜jarvis_readyup.sp
 ┃ ┃ ┃ ┃ ┣ 📜jarvis_reserved.sp
 ┃ ┃ ┃ ┃ ┣ 📜jarvis_teams.sp
 ┃ ┃ ┃ ┃ ┣ 📜jarvis_waiting.sp
 ┃ ┃ ┃ ┃ ┣ 📜mmr_duel.sp
 ┃ ┃ ┃ ┃ ┣ 📜mmr_prematch.sp
 ┃ ┃ ┃ ┃ ┣ 📜mmr_pug.sp
 ┃ ┃ ┃ ┃ ┣ 📜mmr_scrims.sp
 ┃ ┃ ┃ ┃ ┣ 📜mmr_skill.sp
 ┃ ┃ ┃ ┃ ┣ 📜Skill_TablesFormat.sp
 ┃ ┃ ┃ ┃ ┣ 📜Skill_TablesFormat2.sp
 ┃ ┃ ┃ ┃ ┗ 📜Skill_TablesFormatAll.sp
 ┃ ┃ ┃ ┣ 📂include
 ┃ ┃ ┃ ┃ ┣ 📂json
 ┃ ┃ ┃ ┃ ┃ ┣ 📂helpers
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜decode.inc
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜errors.inc
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜metastringmap.inc
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜string.inc
 ┃ ┃ ┃ ┃ ┃ ┃ ┣ 📜typedstringmap.inc
 ┃ ┃ ┃ ┃ ┃ ┃ ┗ 📜unicode.inc
 ┃ ┃ ┃ ┃ ┃ ┣ 📜array.inc
 ┃ ┃ ┃ ┃ ┃ ┣ 📜definitions.inc
 ┃ ┃ ┃ ┃ ┃ ┗ 📜object.inc
 ┃ ┃ ┃ ┃ ┣ 📂system2
 ┃ ┃ ┃ ┃ ┃ ┣ 📜legacy.inc
 ┃ ┃ ┃ ┃ ┃ ┗ 📜request.inc
 ┃ ┃ ┃ ┃ ┣ 📜admin.inc
 ┃ ┃ ┃ ┃ ┣ 📜adminmenu.inc
 ┃ ┃ ┃ ┃ ┣ 📜adt.inc
 ┃ ┃ ┃ ┃ ┣ 📜adt_array.inc
 ┃ ┃ ┃ ┃ ┣ 📜adt_stack.inc
 ┃ ┃ ┃ ┃ ┣ 📜adt_trie.inc
 ┃ ┃ ┃ ┃ ┣ 📜banning.inc
 ┃ ┃ ┃ ┃ ┣ 📜basecomm.inc
 ┃ ┃ ┃ ┃ ┣ 📜bitbuffer.inc
 ┃ ┃ ┃ ┃ ┣ 📜clientprefs.inc
 ┃ ┃ ┃ ┃ ┣ 📜clients.inc
 ┃ ┃ ┃ ┃ ┣ 📜colors.inc
 ┃ ┃ ┃ ┃ ┣ 📜commandfilters.inc
 ┃ ┃ ┃ ┃ ┣ 📜commandline.inc
 ┃ ┃ ┃ ┃ ┣ 📜confogl.inc
 ┃ ┃ ┃ ┃ ┣ 📜console.inc
 ┃ ┃ ┃ ┃ ┣ 📜convars.inc
 ┃ ┃ ┃ ┃ ┣ 📜core.inc
 ┃ ┃ ┃ ┃ ┣ 📜cstrike.inc
 ┃ ┃ ┃ ┃ ┣ 📜datapack.inc
 ┃ ┃ ┃ ┃ ┣ 📜dbi.inc
 ┃ ┃ ┃ ┃ ┣ 📜dhooks.inc
 ┃ ┃ ┃ ┃ ┣ 📜entity.inc
 ┃ ┃ ┃ ┃ ┣ 📜entitylump.inc
 ┃ ┃ ┃ ┃ ┣ 📜entity_prop_stocks.inc
 ┃ ┃ ┃ ┃ ┣ 📜events.inc
 ┃ ┃ ┃ ┃ ┣ 📜files.inc
 ┃ ┃ ┃ ┃ ┣ 📜float.inc
 ┃ ┃ ┃ ┃ ┣ 📜forsaken.inc
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_endgame.inc
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_jarvis.inc
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_l4d2util.inc
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_left4dhooks.inc
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_reserved.inc
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_stocks.inc
 ┃ ┃ ┃ ┃ ┣ 📜functions.inc
 ┃ ┃ ┃ ┃ ┣ 📜geoip.inc
 ┃ ┃ ┃ ┃ ┣ 📜glicko.inc
 ┃ ┃ ┃ ┃ ┣ 📜halflife.inc
 ┃ ┃ ┃ ┃ ┣ 📜handles.inc
 ┃ ┃ ┃ ┃ ┣ 📜helpers.inc
 ┃ ┃ ┃ ┃ ┣ 📜json.inc
 ┃ ┃ ┃ ┃ ┣ 📜keyvalues.inc
 ┃ ┃ ┃ ┃ ┣ 📜l4d2_skill_detect.inc
 ┃ ┃ ┃ ┃ ┣ 📜lang.inc
 ┃ ┃ ┃ ┃ ┣ 📜logging.inc
 ┃ ┃ ┃ ┃ ┣ 📜mapchooser.inc
 ┃ ┃ ┃ ┃ ┣ 📜menus.inc
 ┃ ┃ ┃ ┃ ┣ 📜nextmap.inc
 ┃ ┃ ┃ ┃ ┣ 📜profiler.inc
 ┃ ┃ ┃ ┃ ┣ 📜protobuf.inc
 ┃ ┃ ┃ ┃ ┣ 📜readyup.inc
 ┃ ┃ ┃ ┃ ┣ 📜regex.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdkhooks.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_client.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_engine.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_entinput.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_entoutput.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_functions.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_gamerules.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_hooks.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_sound.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_stocks.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_stringtables.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_tempents.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_tempents_stocks.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_trace.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_variant_t.inc
 ┃ ┃ ┃ ┃ ┣ 📜sdktools_voice.inc
 ┃ ┃ ┃ ┃ ┣ 📜sorting.inc
 ┃ ┃ ┃ ┃ ┣ 📜sourcebanspp.inc
 ┃ ┃ ┃ ┃ ┣ 📜sourcecomms.inc
 ┃ ┃ ┃ ┃ ┣ 📜sourcemod.inc
 ┃ ┃ ┃ ┃ ┣ 📜string.inc
 ┃ ┃ ┃ ┃ ┣ 📜system2.inc
 ┃ ┃ ┃ ┃ ┣ 📜testing.inc
 ┃ ┃ ┃ ┃ ┣ 📜testsuite.inc
 ┃ ┃ ┃ ┃ ┣ 📜textparse.inc
 ┃ ┃ ┃ ┃ ┣ 📜tf2.inc
 ┃ ┃ ┃ ┃ ┣ 📜tf2_stocks.inc
 ┃ ┃ ┃ ┃ ┣ 📜timers.inc
 ┃ ┃ ┃ ┃ ┣ 📜topmenus.inc
 ┃ ┃ ┃ ┃ ┣ 📜unixtime_sourcemod.inc
 ┃ ┃ ┃ ┃ ┣ 📜usermessages.inc
 ┃ ┃ ┃ ┃ ┣ 📜vector.inc
 ┃ ┃ ┃ ┃ ┣ 📜version.inc
 ┃ ┃ ┃ ┃ ┗ 📜version_auto.inc
 ┃ ┃ ┃ ┣ 📜forsaken.sp
 ┃ ┃ ┃ ┣ 📜forsaken_endgame.sp
 ┃ ┃ ┃ ┣ 📜forsaken_jarvis.sp
 ┃ ┃ ┃ ┣ 📜forsaken_mmr.sp
 ┃ ┃ ┃ ┣ 📜forsaken_mmr.sp.old
 ┃ ┃ ┃ ┣ 📜forsaken_native.sp
 ┃ ┃ ┃ ┣ 📜forsaken_reserved.sp.old
 ┃ ┃ ┃ ┣ 📜forsaken_skills.sp
 ┃ ┃ ┃ ┣ 📜json_test.sp
 ┃ ┃ ┃ ┣ 📜system2_http.sp
 ┃ ┃ ┃ ┣ 📜system2_test.sp
 ┃ ┃ ┃ ┣ 📜testsuite_example.sp
 ┃ ┃ ┃ ┗ 📜unixtime_test.sp
 ┃ ┃ ┗ 📂translations
 ┃ ┃ ┃ ┣ 📂es
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_endgame.phrases.txt
 ┃ ┃ ┃ ┃ ┣ 📜forsaken_jarvis.phrases.txt
 ┃ ┃ ┃ ┃ ┗ 📜forsaken_mmr.phrases.txt
 ┃ ┃ ┃ ┣ 📜forsaken_endgame.phrases.txt
 ┃ ┃ ┃ ┣ 📜forsaken_jarvis.phrases.txt
 ┃ ┃ ┃ ┗ 📜forsaken_mmr.phrases.txt
 ┗ 📂cfg
 ┃ ┗ 📂sourcemod
 ┃ ┃ ┣ 📜forsaken.cfg
 ┃ ┃ ┣ 📜forsaken_endgame.cfg
 ┃ ┃ ┣ 📜forsaken_jarvis.cfg
 ┃ ┃ ┣ 📜forsaken_mmr.cfg
 ┃ ┃ ┗ 📜forsaken_skills.cfg
```
