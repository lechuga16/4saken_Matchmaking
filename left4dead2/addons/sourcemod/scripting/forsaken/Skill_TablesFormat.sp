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
#if defined _4sakenSkill_TablesFormat_included
	#endinput
#endif
#define _4sakenSkill_TablesFormat_included



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
	if (!g_cvarSkeet.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Skeet | Survivor:%N Hunter:%N", survivor, hunter);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))
		
	if(IsFakeClient(hunter))
		StrCat(sSteamID2, sizeof(sSteamID2), "hunter");
	else
		GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(0, sMapName, sSteamID, sSteamID2);
}

public void OnSkeetMelee(int survivor, int hunter)
{
	if (!g_cvarSkeetMelee.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Skeet-Melee | Survivor:%N Hunter:%N", survivor, hunter);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))
		
	if(IsFakeClient(hunter))
		StrCat(sSteamID2, sizeof(sSteamID2), "hunter");
	else
		GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(1, sMapName, sSteamID, sSteamID2);
}

public void OnSkeetGL(int survivor, int hunter)
{
	if (!g_cvarSkeetGL.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Skeet Granate Laucher | Survivor:%N Hunter:%N", survivor, hunter);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))
		
	if(IsFakeClient(hunter))
		StrCat(sSteamID2, sizeof(sSteamID2), "hunter");
	else
		GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(2, sMapName, sSteamID, sSteamID2);
}

public void OnSkeetSniper(int survivor, int hunter)
{
	if (!g_cvarSkeetSniper.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Skeet-Sniper | Survivor:%N Hunter:%N", survivor, hunter);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))
		
	if(IsFakeClient(hunter))
		StrCat(sSteamID2, sizeof(sSteamID2), "hunter");
	else
		GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(3, sMapName, sSteamID, sSteamID2);
}

public void OnChargerLevel(int survivor, int charger)
{
	if (!g_cvarChargerLevel.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Charger-Level | Survivor:%N Charger:%N", survivor, charger);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))
		
	if(IsFakeClient(charger))
		StrCat(sSteamID2, sizeof(sSteamID2), "charger");
	else
		GetClientAuthId(charger, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(4, sMapName, sSteamID, sSteamID2);
}

public void OnHunterDeadstop(int survivor, int hunter)
{
	if (!g_cvarHunterDeadstop.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Hunter-Deadstop | Survivor:%N Hunter:%N", survivor, hunter);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))
		
	if(IsFakeClient(hunter))
		StrCat(sSteamID2, sizeof(sSteamID2), "hunter");
	else
		GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(5, sMapName, sSteamID, sSteamID2);
}

public void OnTongueCut(int survivor, int smoker)
{
	if (!g_cvarTongueCut.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Tongue-Cut | Survivor:%N Smoker:%N", survivor, smoker);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))
		
	if(IsFakeClient(smoker))
		StrCat(sSteamID2, sizeof(sSteamID2), "smoker");
	else
		GetClientAuthId(smoker, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(6, sMapName, sSteamID, sSteamID2);
}

public void OnTankRockSkeeted(int survivor, int tank)
{
	if (!g_cvarTankRockSkeeted.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Tank Skeet-Rock | Survivor:%N Tank:%N", survivor, tank);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))
		
	if(IsFakeClient(tank))
		StrCat(sSteamID2, sizeof(sSteamID2), "tank");
	else
		GetClientAuthId(tank, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(7, sMapName, sSteamID, sSteamID2);
}

public void OnTankRockEaten(int tank, int survivor)
{
	if (!g_cvarTankRockEaten.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Tank Skeet-Rock Eaten | Survivor:%N Tank:%N", survivor, tank);

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))
		
	if(IsFakeClient(tank))
		StrCat(sSteamID2, sizeof(sSteamID2), "tank");
	else
		GetClientAuthId(tank, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryFormat(8, sMapName, sSteamID, sSteamID2);
}

void QueryFormat(int iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2)
{
	char sQuery[256];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected) VALUES ('%s', '%s', '%s');", sTFormat[iTable], sMapName, sSteamID, sSteamID2);
	g_Database.Query(OnUpdateTable, sQuery);
}
