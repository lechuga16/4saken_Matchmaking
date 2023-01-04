/*
sTFormat2
- void OnSkeetHurt(int survivor, int hunter, int damage, bool isOverkill)
- void OnSkeetMeleeHurt(int survivor, int hunter, int damage, bool isOverkill)
- void OnSkeetSniperHurt(int survivor, int hunter, int damage, bool isOverkill)
*/
#if defined _Skill_TablesFormat2_included
	#endinput
#endif
#define _Skill_TablesFormat2_included

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

void SQLTablesFormat2()
{
	for (int i = 0; i < sizeof(sTFormat2); i++)
	{
		char sQuery[300];
		g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `chip` INT NOT NULL, `overkill` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormat2[i]);
		g_Database.Query(OnCreateTable, sQuery);
	}
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/
public void OnSkeetHurt(int survivor, int hunter, int damage, bool isOverkill)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSkeetHurt.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(hunter))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Skeet-Hurt | Survivor:%N Hunter:%N Damage:%d Overkill:%d", survivor, hunter, damage, view_as<int>(isOverkill));

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	if (IsFakeClient(hunter))
		StrCat(sSteamID2, sizeof(sSteamID2), "infected");
	else GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat2(skeethurt, sMapName, sSteamID, sSteamID2, damage, isOverkill);
}

public void OnSkeetMeleeHurt(int survivor, int hunter, int damage, bool isOverkill)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSkeetMeleeHurt.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(hunter))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Skeet-Melee Hurt | Survivor:%N Hunter:%N Damage:%d Overkill:%d", survivor, hunter, damage, view_as<int>(isOverkill));

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	if (IsFakeClient(hunter))
		StrCat(sSteamID2, sizeof(sSteamID2), "infected");
	else GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat2(skeetmeleehurt, sMapName, sSteamID, sSteamID2, damage, isOverkill);
}

public void OnSkeetSniperHurt(int survivor, int hunter, int damage, bool isOverkill)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSkeetSniperHurt.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(hunter))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Skeet-Sniper Hurt | Survivor:%N Hunter:%N Damage:%d Overkill:%d", survivor, hunter, damage, view_as<int>(isOverkill));

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	if (IsFakeClient(hunter))
		StrCat(sSteamID2, sizeof(sSteamID2), "infected");
	else GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat2(skeetsniperhurt, sMapName, sSteamID, sSteamID2, damage, isOverkill);
}

void QueryFormat2(TFormat2 iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, int damage, bool isOverkill)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, chip, overkill) VALUES ('%s', '%s', '%s', '%d', '%d');", sTFormat2[iTable], sMapName, sSteamID, sSteamID2, damage, view_as<int>(isOverkill));
	g_Database.Query(UpdateTFormat2, sQuery, iTable);
}

public void UpdateTFormat2(Database db, DBResultSet results, const char[] error, any iTable)
{
	if (results == null)
		ThrowError("Error UpdateTFormat2 %s: %s", sTFormat[iTable], error);
}