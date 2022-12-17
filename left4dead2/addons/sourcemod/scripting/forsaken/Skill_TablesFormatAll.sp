/*
sTFormatAll
- void OnChargerLevelHurt(int survivor, int charger, int damage)
- void OnWitchCrown(int survivor, int damage)
- void OnWitchCrownHurt(int survivor, int damage, int chipdamage)
- void OnSmokerSelfClear(int survivor, int smoker, bool withShove)
- void OnJockeyHighPounce(int jockey, int victim, float height, bool reportedHigh)
- void OnDeathCharge(int charger, int survivor, float height, float distance, bool wasCarried)
- void OnBoomerVomitLanded(int boomer, int amount)
- void OnSpecialShoved(int survivor, int infected, int zombieClass)
- void OnBunnyHopStreak(int survivor, int streak, float maxVelocity)
- void OnCarAlarmTriggered(int survivor, int infected, CarAlarmTriggerReason reason)
- void OnBoomerPop(int survivor, int boomer, int shoveCount, float timeAlive)
- void OnSpecialClear(int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove)
- void OnHunterHighPounce(int hunter, int survivor, int actualDamage, float calculatedDamage, float height, bool reportedHigh)
*/
#if defined _4sakenSkill_TablesFormatAll_included
	#endinput
#endif
#define _4sakenSkill_TablesFormatAll_included

/****************************************************************
            C A L L B A C K   F U N C T I O N S
****************************************************************/

void SQLTablesFormatAll()
{
	for (int i = 0; i < view_as<int>(TFormatAll_Size); i++)
	{
		char sQuery[500];
		switch (i)
		{
			case 0:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `damage` INT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 1:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `damage` INT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 2:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `damage` INT NOT NULL, `chip` INT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 3:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `withShove` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 4:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `height` FLOAT NOT NULL, `reportedHigh` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 5:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `height` FLOAT NOT NULL, `distance` FLOAT NOT NULL, `wasCarried` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 6:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `infected` VARCHAR(64) NOT NULL, `amount` INT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 7:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `zombieclass` VARCHAR(64) NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 8:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `streak` INT NOT NULL, `maxvelocity` FLOAT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 9:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `CarAlarmTriggerReason` VARCHAR(64) NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 10:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `shoveCount` INT NOT NULL, `timeAlive` FLOAT NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 11:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `clearer` VARCHAR(64) NOT NULL, `pinner` VARCHAR(64) NOT NULL, `pinvictim` VARCHAR(64) NOT NULL, `zombieclass` VARCHAR(64) NOT NULL, `timeA` FLOAT NOT NULL, `timeB` FLOAT NOT NULL, `withShove` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
			case 12:
				g_Database.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%s` ( `id` INT NOT NULL AUTO_INCREMENT, `map` VARCHAR(32) NOT NULL, `survivor` VARCHAR(64) NOT NULL, `infected` VARCHAR(64) NOT NULL, `actualDamage` INT NOT NULL, `calculatedDamage` FLOAT NOT NULL, `height` FLOAT NOT NULL, `reportedHigh` BOOLEAN NOT NULL, PRIMARY KEY (`id`)) ENGINE = InnoDB;", sTFormatAll[i]);
		}
		g_Database.Query(OnCreateTable, sQuery);
	}
}

/*****************************************************************
            P L U G I N   F U N C T I O N S
*****************************************************************/
public void OnChargerLevelHurt(int survivor, int charger, int damage)
{
	if (!g_cvarChargerLevelHurt.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Charger-Level Hurt | Survivor:%N Charger:%N Damage:%d", survivor, charger, damage);

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
	QueryChargerLevelHurt(chargerlevelhurt, sMapName, sSteamID, sSteamID2, damage);
}

void QueryChargerLevelHurt(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, int damage)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, damage) VALUES ('%s', '%s', '%s', '%d');", sTFormatAll[iTable], sMapName, sSteamID, sSteamID2, damage);
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnWitchCrown(int survivor, int damage)
{
	if (!g_cvarWitchCrown.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Witch-Crown | Survivor:%N Damage:%d", survivor, damage);

	char
		sSteamID[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryWitchCrown(witchcrown, sMapName, sSteamID, damage);
}


void QueryWitchCrown(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, int damage)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, damage) VALUES ('%s', '%s', '%d');", sTFormatAll[iTable], sMapName, sSteamID, damage);
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnWitchCrownHurt(int survivor, int damage, int chipdamage)
{
	if (!g_cvarWitchCrownHurt.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | Witch-Crown | Survivor:%N Damage:%d Chip:%d", survivor, damage, chipdamage);

	char
		sSteamID[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryWitchCrownHurt(witchcrownhurt, sMapName, sSteamID, damage, chipdamage);
}

void QueryWitchCrownHurt(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, int damage, int chipdamage)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, damage, chip) VALUES ('%s', '%s', '%d', '%d');", sTFormatAll[iTable], sMapName, sSteamID, damage, chipdamage);
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnSmokerSelfClear(int survivor, int smoker, bool withShove)
{
	if (!g_cvarSmokerSelfClear.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | SmokerSelfClear | Survivor:%N Smoker:%N Shove:%d", survivor, smoker, view_as<int>(withShove));

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
	QuerySmokerSelfClear(smokerselfclear, sMapName, sSteamID, sSteamID2, withShove);
}

void QuerySmokerSelfClear(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, bool withShove)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, withShove) VALUES ('%s', '%s', '%s', '%d');", sTFormatAll[iTable], sMapName, sSteamID, sSteamID2, view_as<int>(withShove));
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnJockeyHighPounce(int jockey, int victim, float height, bool reportedHigh)
{
	if (!g_cvarJockeyHighPounce.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | JockeyHighPounce | Survivor:%N Jockey:%N Height:%.1f ReportedHigh:%d", victim, jockey, height, view_as<int>(reportedHigh));

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(victim))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(victim, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	if(IsFakeClient(jockey))
		StrCat(sSteamID2, sizeof(sSteamID2), "jockey");
	else
		GetClientAuthId(jockey, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryJockeyHighPounce(jockeyhighpounce, sMapName, sSteamID, sSteamID2, height, reportedHigh);
}

void QueryJockeyHighPounce(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, float height, bool reportedHigh)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, height, reportedHigh) VALUES ('%s', '%s', '%s', '%.1f', '%d');", sTFormatAll[iTable], sMapName, sSteamID, sSteamID2, height, view_as<int>(reportedHigh));
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnDeathCharge(int charger, int survivor, float height, float distance, bool wasCarried)
{
	if (!g_cvarDeathCharge.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | DeathCharger | Survivor:%N Charger:%N Height:%.1f Distance:%.1f Carried:%d", survivor, charger, height, distance, view_as<int>(wasCarried));

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
	QueryDeathCharge(deathcharge, sMapName, sSteamID, sSteamID2, height,  distance, wasCarried);
}

QueryDeathCharge(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, float height, float distance, bool wasCarried)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, height, distance, wasCarried) VALUES ('%s', '%s', '%s', '%.1f', '%.1f', '%d');", sTFormatAll[iTable], sMapName, sSteamID, sSteamID2, height, distance, view_as<int>(wasCarried));
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnBoomerVomitLanded(int boomer, int amount)
{
	if (!g_cvarBoomerVomitLanded.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | BoomerVomitLanded | Boomer:%N Amount:%d ", boomer, amount);

	char
		sSteamID[64],
		sMapName[32];

	if(IsFakeClient(boomer))
		StrCat(sSteamID, sizeof(sSteamID), "boomer");
	else
		GetClientAuthId(boomer, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryBoomerVomitLanded(boomervomitlanded, sMapName, sSteamID, amount);
}

QueryBoomerVomitLanded(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, int amount)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, infected, amount) VALUES ('%s', '%s', '%d');", sTFormatAll[iTable], sMapName, sSteamID, amount);
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnSpecialShoved(int survivor, int infected, int zombieClass)
{
	if (!g_cvarSpecialShoved.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | SpecialShoved | Survivor:%N Infected:%N ZombieClass:%s", survivor, infected, L4D2ZombieClassname[zombieClass])

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	if(IsFakeClient(infected))
		StrCat(sSteamID2, sizeof(sSteamID2), "infected");
	else
		GetClientAuthId(infected, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QuerySpecialShoved(specialshoved, sMapName, sSteamID, sSteamID2, zombieClass);
}

QuerySpecialShoved(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, int zombieClass)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, infected, amount) VALUES ('%s', '%s', '%s', '%s');", sTFormatAll[iTable], sMapName, sSteamID, sSteamID2, L4D2ZombieClassname[zombieClass]);
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnBunnyHopStreak(int survivor, int streak, float maxVelocity)
{
	if (!g_cvarBunnyHopStreak.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | BunnyHopStreak | Survivor:%N Streak:%d MaxVelocity:%.1f", survivor, streak, maxVelocity)

	char
		sSteamID[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryBunnyHopStreak(bunnyhopstreak, sMapName, sSteamID, streak, maxVelocity);
}

QueryBunnyHopStreak(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, int streak, float maxVelocity)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, streak, maxvelocity) VALUES ('%s', '%s', '%d', '%.1f');", sTFormatAll[iTable], sMapName, sSteamID, streak, maxVelocity);
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnCarAlarmTriggered(int survivor, int infected, CarAlarmTriggerReason reason)
{
	if (!g_cvarCarAlarmTriggered.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | CarAlarmTriggered | Survivor:%N Infected:%N CarAlarmTriggerReason:%s", survivor, infected, reason)

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	if(IsFakeClient(infected))
		StrCat(sSteamID2, sizeof(sSteamID2), "infected");
	else
		GetClientAuthId(infected, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryCarAlarmTriggered(caralarmtriggered, sMapName, sSteamID, sSteamID2, reason);
}

QueryCarAlarmTriggered(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, CarAlarmTriggerReason reason)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, CarAlarmTriggerReason) VALUES ('%s', '%s', '%s', '%s');", sTFormatAll[iTable], sMapName, sSteamID, sSteamID2, sCarAlarmTriggerReason[reason]);
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnBoomerPop(int survivor, int boomer, int shoveCount, float timeAlive)
{
	if (!g_cvarBoomerPop.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | BoomerPop | Survivor:%N Boomer:%N ShoveCount:%d TimeAlive:%.1f", survivor, boomer, shoveCount, timeAlive)

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	if(IsFakeClient(boomer))
		StrCat(sSteamID2, sizeof(sSteamID2), "boomer");
	else
		GetClientAuthId(boomer, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryBoomerPop(boomerpop, sMapName, sSteamID, sSteamID2, shoveCount, timeAlive);
}

QueryBoomerPop(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, int shoveCount, float timeAlive)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, shoveCount, timeAlive) VALUES ('%s', '%s', '%s', '%d', '%.1f');", sTFormatAll[iTable], sMapName, sSteamID, sSteamID2, shoveCount, timeAlive);
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnSpecialClear(int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove)
{
	if (!g_cvarSpecialClear.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | SpecialClear | Clearer:%N Pinner:%N PinVictim:%N ZombieClass:%s TimeA:%.1f TimeB:%.1f WithShove:%s", clearer, pinner, pinvictim, L4D2ZombieClassname[zombieClass], timeA, timeB, withShove, view_as<char>(withShove))

	char
		sSteamID[64],
		sSteamID2[64],
		sSteamID3[64],
		sMapName[32];

	if(IsFakeClient(clearer))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(clearer, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	if(IsFakeClient(pinner))
		StrCat(sSteamID2, sizeof(sSteamID2), "Infected");
	else
		GetClientAuthId(pinner, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	if(IsFakeClient(pinvictim))
		StrCat(sSteamID3, sizeof(sSteamID3), "survivor");
	else
		GetClientAuthId(pinvictim, AuthId_SteamID64, sSteamID3, sizeof(sSteamID3))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QuerySpecialClear(specialclear, sMapName, sSteamID, sSteamID2, sSteamID3, zombieClass, timeA, timeB, withShove);
}

QuerySpecialClear(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, const char[] sSteamID3, int zombieClass, float timeA, float timeB, bool withShove)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, clearer, pinner, pinvictim, zombieclass, timeA, timeB, withShove) VALUES ('%s', '%s', '%s', '%s', '%s', '%.1f', '%.1f', '%d');", sTFormatAll[iTable], sMapName, sSteamID, sSteamID2, sSteamID3, L4D2ZombieClassname[zombieClass], timeA, timeB, view_as<int>(withShove));
	g_Database.Query(OnUpdateTable, sQuery);
}

public void OnHunterHighPounce(int hunter, int survivor, int actualDamage, float calculatedDamage, float height, bool reportedHigh)
{
	if (!g_cvarHunterHighPounce.BoolValue)
		return;

	if (g_cvarDebug.BoolValue)
		Forsaken_log("Skill detected | HunterHighPounce | Survivor:%N Hunter:%N ActualDamage:%d ZombieClass:%s CalculatedDamage:%.1f Height:%.1f ReportedHigh:%d", survivor, hunter, actualDamage, calculatedDamage, height, view_as<int>(reportedHigh))

	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	if(IsFakeClient(survivor))
		StrCat(sSteamID, sizeof(sSteamID), "survivor");
	else
		GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID))

	if(IsFakeClient(hunter))
		StrCat(sSteamID2, sizeof(sSteamID2), "Infected");
	else
		GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2))

	GetCurrentMap(sMapName, sizeof(sMapName));
	QueryHunterHighPounce(hunterhighpounce, sMapName, sSteamID, sSteamID2, actualDamage, calculatedDamage, height, reportedHigh);
}

QueryHunterHighPounce(TFormatAll iTable, const char[] sMapName, const char[] sSteamID, const char[] sSteamID2, int actualDamage, float calculatedDamage, float height, bool reportedHigh)
{
	char sQuery[300];
	g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, actualDamage, calculatedDamage, height, reportedHigh) VALUES ('%s', '%s', '%s', '%d', '%.1f', '%.1f', '%d');", sTFormatAll[iTable], sMapName, sSteamID, sSteamID2, actualDamage, calculatedDamage, height, view_as<int>(reportedHigh));
	g_Database.Query(OnUpdateTable, sQuery);
}