/*
sTFormat
- void OnSkeet(int survivor, int hunter)
- void OnSkeetMelee(int survivor, int hunter)
- void OnSkeetGL(int survivor, int hunter)
- void OnSkeetSniper(int survivor, int hunter)
- void OnChargerLevel(int survivor, int charger)
- void OnHunterDeadstop(int survivor, int hunter)
- void OnTongueCut(int survivor, int smoker)
- void OnTankRockSkeeted(int survivor, int tank)
- void OnTankRockEaten(int tank, int survivor)
*/
#if defined _Skill_TablesFormat_included
	#endinput
#endif
#define _Skill_TablesFormat_included

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

void SQLTablesFormat()
{
	for (int i = 0; i < sizeof(sTFormat); i++)
	{
		char sQuery[250];
		g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormat[i]);
		g_Database.Query(OnCreateTable, sQuery);
	}
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/
public void OnSkeet(int survivor, int hunter)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSkeet.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(hunter))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Skeet | Survivor:%N Hunter:%N", survivor, hunter);

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
	QueryFormat(skeet, sMapName, sSteamID, sSteamID2);
}

public void OnSkeetMelee(int survivor, int hunter)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSkeetMelee.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(hunter))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Skeet-Melee | Survivor:%N Hunter:%N", survivor, hunter);

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
	QueryFormat(skeetmelee, sMapName, sSteamID, sSteamID2);
}

public void OnSkeetGL(int survivor, int hunter)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSkeetGL.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(hunter))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Skeet Granate Laucher | Survivor:%N Hunter:%N", survivor, hunter);

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
	QueryFormat(skeetgl, sMapName, sSteamID, sSteamID2);
}

public void OnSkeetSniper(int survivor, int hunter)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSkeetSniper.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(hunter))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Skeet-Sniper | Survivor:%N Hunter:%N", survivor, hunter);

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
	QueryFormat(skeetsniper, sMapName, sSteamID, sSteamID2);
}

public void OnChargerLevel(int survivor, int charger)
{
	if (!g_cvarEnable.BoolValue || !g_cvarChargerLevel.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(charger))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Charger-Level | Survivor:%N Charger:%N", survivor, charger);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	if (IsFakeClient(charger))
		StrCat(sSteamID2, sizeof(sSteamID2), "infected");
	else GetClientAuthId(charger, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(chargerlevel, sMapName, sSteamID, sSteamID2);
}

public void OnHunterDeadstop(int survivor, int hunter)
{
	if (!g_cvarEnable.BoolValue || !g_cvarHunterDeadstop.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(hunter))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Hunter-Deadstop | Survivor:%N Hunter:%N", survivor, hunter);

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
	QueryFormat(hunterdeadstop, sMapName, sSteamID, sSteamID2);
}

public void OnTongueCut(int survivor, int smoker)
{
	if (!g_cvarEnable.BoolValue || !g_cvarTongueCut.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(smoker))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Tongue-Cut | Survivor:%N Smoker:%N", survivor, smoker);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	if (IsFakeClient(smoker))
		StrCat(sSteamID2, sizeof(sSteamID2), "infected");
	else GetClientAuthId(smoker, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(tonguecut, sMapName, sSteamID, sSteamID2);
}

public void OnTankRockSkeeted(int survivor, int tank)
{
	if (!g_cvarEnable.BoolValue || !g_cvarTankRockSkeeted.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(tank))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Tank Skeet-Rock | Survivor:%N Tank:%N", survivor, tank);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	if (IsFakeClient(tank))
		StrCat(sSteamID2, sizeof(sSteamID2), "infected");
	else GetClientAuthId(tank, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(tankrockskeeted, sMapName, sSteamID, sSteamID2);
}

public void OnTankRockEaten(int tank, int survivor)
{
	if (!g_cvarEnable.BoolValue || !g_cvarTankRockEaten.BoolValue)
		return;

	if (IsFakeClient(survivor) && IsFakeClient(tank))
		return;

	if (g_cvarDebug.BoolValue)
		fkn_log("Skill detected | Tank Skeet-Rock Eaten | Survivor:%N Tank:%N", survivor, tank);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if (IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	if (IsFakeClient(tank))
		StrCat(sSteamID2, sizeof(sSteamID2), "infected");
	else
		GetClientAuthId(tank, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(tankrockeaten, sMapName, sSteamID, sSteamID2);
}

void QueryFormat(TFormat iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2)
{
	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected) VALUES ('%s', '%s', '%s');", sTFormat[iTable], sMapName, sSteamID, sSteamID2);
	g_Database.Query(UpdateTFormat, sQuery, iTable);
}

public void UpdateTFormat(Database db, DBResultSet results, const char[] error, any iTable)
{
	if (results == null)
		ThrowError("Error UpdateTFormat %s: %s", sTFormat[iTable], error);
}