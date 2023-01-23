/*
sTFormatAll
- void OnChargerLevelHurt(int survivor, int charger, int damage)
- void OnWitchCrown(int survivor, int damage)
- void OnWitchCrownHurt(int survivor, int damage, int chipdamage)
- void OnSmokerSelfClear(int survivor, int smoker, bool withShove)
- void OnJockeyHighPounce(int survivor, int jockey, float height, bool reportedHigh)
- void OnDeathCharge(int charger, int survivor, float height, float distance, bool wasCarried)
- void OnBoomerVomitLanded(int boomer, int amount)
- void OnSpecialShoved(int survivor, int infected, int zombieClass)
- void OnBunnyHopStreak(int survivor, int streak, float maxVelocity)
- void OnCarAlarmTriggered(int survivor, int infected, CarAlarmTriggerReason reason)
- void OnBoomerPop(int survivor, int boomer, int shoveCount, float timeAlive)
- void OnSpecialClear(int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove)
- void OnHunterHighPounce(int hunter, int survivor, int actualDamage, float calculatedDamage, float height, bool reportedHigh)
*/
#if defined _Skill_TablesFormatAll_included
	#endinput
#endif
#define _Skill_TablesFormatAll_included

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
			case 0: // OnChargerLevelHurt(int survivor, int charger, int damage)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`infected` VARCHAR(64) NOT NULL, \
						`damage` INT NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;",
					sTFormatAll[i]);
			case 1: // OnWitchCrown(int survivor, int damage)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`damage` INT NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
			case 2: // OnWitchCrownHurt(int survivor, int damage, int chipdamage)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`damage` INT NOT NULL, \
						`chip` INT NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
			case 3: // OnSmokerSelfClear(int survivor, int smoker, bool withShove)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`infected` VARCHAR(64) NOT NULL, \
						`withShove` BOOLEAN NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
			case 4: // OnJockeyHighPounce(int survivor, int jockey, float height, bool reportedHigh)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`infected` VARCHAR(64) NOT NULL, \
						`height` FLOAT NOT NULL, \
						`reportedHigh` BOOLEAN NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
			case 5: // OnDeathCharge(int charger, int survivor, float height, float distance, bool wasCarried)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`infected` VARCHAR(64) NOT NULL, \
						`height` FLOAT NOT NULL, \
						`distance` FLOAT NOT NULL, \
						`wasCarried` BOOLEAN NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
			case 6: // OnBoomerVomitLanded(int boomer, int amount)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`infected` VARCHAR(64) NOT NULL, \
						`amount` INT NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
			case 7: // OnSpecialShoved(int survivor, int infected, int zombieClass)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`infected` VARCHAR(64) NOT NULL, \
						`zombieclass` VARCHAR(64) NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
			case 8: // OnBunnyHopStreak(int survivor, int streak, float maxVelocity)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`streak` INT NOT NULL, \
						`maxvelocity` FLOAT NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
			case 9: // OnCarAlarmTriggered(int survivor, int infected, CarAlarmTriggerReason reason)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`infected` VARCHAR(64) NOT NULL, \
						`CarAlarmTriggerReason` VARCHAR(64) NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
				sTFormatAll[i]);
			case 10: // OnBoomerPop(int survivor, int boomer, int shoveCount, float timeAlive)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`infected` VARCHAR(64) NOT NULL, \
						`shoveCount` INT NOT NULL, \
						`timeAlive` FLOAT NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
				sTFormatAll[i]);
			case 11: // OnSpecialClear(int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`clearer` VARCHAR(64) NOT NULL, \
						`pinner` VARCHAR(64) NOT NULL, \
						`pinvictim` VARCHAR(64) NOT NULL, \
						`zombieclass` VARCHAR(64) NOT NULL, \
						`timeA` FLOAT NOT NULL, \
						`timeB` FLOAT NOT NULL, \
						`withShove` BOOLEAN NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
			case 12: // OnHunterHighPounce(int hunter, int survivor, int actualDamage, float calculatedDamage, float height, bool reportedHigh)
				g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
					"CREATE TABLE IF NOT EXISTS `%s`( \
						`id` INT NOT NULL AUTO_INCREMENT, \
						`map` VARCHAR(32) NOT NULL, \
						`survivor` VARCHAR(64) NOT NULL, \
						`infected` VARCHAR(64) NOT NULL, \
						`actualDamage` INT NOT NULL, \
						`calculatedDamage` FLOAT NOT NULL, \
						`height` FLOAT NOT NULL, \
						`reportedHigh` BOOLEAN NOT NULL, \
						PRIMARY KEY(`id`)) \
					ENGINE = InnoDB;", 
					sTFormatAll[i]);
		}
		g_ForsakenDB.Query(OnCreateTable, sQuery);
	}
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

public void OnChargerLevelHurt(int survivor, int charger, int damage)
{
	if (!g_cvarEnable.BoolValue || !g_cvarChargerLevelHurt.BoolValue)
		return;

	if (IsFakeClient(survivor) || IsFakeClient(charger))
		return;

	fkn_log(true, "Skill detected | Charger-Level Hurt | Survivor:%N Charger:%N Damage:%d", survivor, charger, damage);
	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetClientAuthId(charger, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, damage) VALUES ('%s', '%s', '%s', '%d');", sTFormatAll[chargerlevelhurt], sMapName, sSteamID, sSteamID2, damage);
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, chargerlevelhurt);
}

public void OnWitchCrown(int survivor, int damage)
{
	if (!g_cvarEnable.BoolValue || !g_cvarWitchCrown.BoolValue)
		return;

	if (IsFakeClient(survivor))
		return;

	fkn_log(true, "Skill detected | Witch-Crown | Survivor:%N Damage:%d", survivor, damage);
	char
		sSteamID[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, damage) VALUES ('%s', '%s', '%d');", sTFormatAll[witchcrown], sMapName, sSteamID, damage);
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, witchcrown);
}

public void OnWitchCrownHurt(int survivor, int damage, int chipdamage)
{
	if (!g_cvarEnable.BoolValue || !g_cvarWitchCrownHurt.BoolValue)
		return;

	if (IsFakeClient(survivor))
		return;

	fkn_log(true, "Skill detected | Witch-Crown | Survivor:%N Damage:%d Chip:%d", survivor, damage, chipdamage);
	char
		sSteamID[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, damage, chip) VALUES ('%s', '%s', '%d', '%d');", sTFormatAll[witchcrownhurt], sMapName, sSteamID, damage, chipdamage);
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, witchcrownhurt);
}

public void OnSmokerSelfClear(int survivor, int smoker, bool withShove)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSmokerSelfClear.BoolValue)
		return;

	if (IsFakeClient(survivor) || IsFakeClient(smoker))
		return;

	fkn_log(true, "Skill detected | SmokerSelfClear | Survivor:%N Smoker:%N Shove:%d", survivor, smoker, view_as<int>(withShove));
	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetClientAuthId(smoker, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, withShove) VALUES ('%s', '%s', '%s', '%d');", sTFormatAll[smokerselfclear], sMapName, sSteamID, sSteamID2, view_as<int>(withShove));
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, smokerselfclear);
}

public void OnJockeyHighPounce(int survivor, int jockey, float height, bool reportedHigh)
{
	if (!g_cvarEnable.BoolValue || !g_cvarJockeyHighPounce.BoolValue)
		return;

	if (IsFakeClient(survivor) || IsFakeClient(jockey))
		return;

	fkn_log(true, "Skill detected | JockeyHighPounce | Survivor:%N Jockey:%N Height:%.1f ReportedHigh:%d", survivor, jockey, height, view_as<int>(reportedHigh));
	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetClientAuthId(jockey, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, height, reportedHigh) VALUES ('%s', '%s', '%s', '%.1f', '%d');", sTFormatAll[jockeyhighpounce], sMapName, sSteamID, sSteamID2, height, view_as<int>(reportedHigh));
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, jockeyhighpounce);
}

public void OnDeathCharge(int charger, int survivor, float height, float distance, bool wasCarried)
{
	if (!g_cvarEnable.BoolValue || !g_cvarDeathCharge.BoolValue)
		return;

	if (IsFakeClient(survivor) || IsFakeClient(charger))
		return;

	fkn_log(true, "Skill detected | DeathCharger | Survivor:%N Charger:%N Height:%.1f Distance:%.1f Carried:%d", survivor, charger, height, distance, view_as<int>(wasCarried));
	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetClientAuthId(charger, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, height, distance, wasCarried) VALUES ('%s', '%s', '%s', '%.1f', '%.1f', '%d');", sTFormatAll[deathcharge], sMapName, sSteamID, sSteamID2, height, distance, view_as<int>(wasCarried));
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, deathcharge);
}

public void OnBoomerVomitLanded(int boomer, int amount)
{
	if (!g_cvarEnable.BoolValue || !g_cvarBoomerVomitLanded.BoolValue)
		return;

	if (IsFakeClient(boomer))
		return;


	fkn_log(true, "Skill detected | BoomerVomitLanded | Boomer:%N Amount:%d ", boomer, amount);
	char
		sSteamID[64],
		sMapName[32];

	GetClientAuthId(boomer, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, infected, amount) VALUES ('%s', '%s', '%d');", sTFormatAll[boomervomitlanded], sMapName, sSteamID, amount);
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, boomervomitlanded);
}

public void OnSpecialShoved(int survivor, int infected, int zombieClass)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSpecialShoved.BoolValue)
		return;

	if (IsFakeClient(survivor) || IsFakeClient(infected))
		return;

	fkn_log(true, "Skill detected | SpecialShoved | Survivor:%N Infected:%N ZombieClass:%s", survivor, infected, L4D2ZombieClassname[zombieClass]);
	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetClientAuthId(infected, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, zombieclass) VALUES ('%s', '%s', '%s', '%s');", sTFormatAll[specialshoved], sMapName, sSteamID, sSteamID2, L4D2ZombieClassname[zombieClass]);
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, specialshoved);
}

public void OnBunnyHopStreak(int survivor, int streak, float maxVelocity)
{
	if (!g_cvarEnable.BoolValue || !g_cvarBunnyHopStreak.BoolValue)
		return;

	if (IsFakeClient(survivor))
		return;

	fkn_log(true, "Skill detected | BunnyHopStreak | Survivor:%N Streak:%d MaxVelocity:%.1f", survivor, streak, maxVelocity);
	char
		sSteamID[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, streak, maxvelocity) VALUES ('%s', '%s', '%d', '%.1f');", sTFormatAll[bunnyhopstreak], sMapName, sSteamID, streak, maxVelocity);
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, bunnyhopstreak);
}

public void OnCarAlarmTriggered(int survivor, int infected, CarAlarmTriggerReason reason)
{
	if (!g_cvarEnable.BoolValue || !g_cvarCarAlarmTriggered.BoolValue)
		return;

	if (infected == CONSOLE || infected == -1)
		return;

	if (IsFakeClient(survivor) || IsFakeClient(infected))
		return;

	fkn_log(true, "Skill detected | CarAlarmTriggered | Survivor:%N Infected:%N CarAlarmTriggerReason:%s", survivor, infected, sCarAlarmTriggerReason[reason]);
	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetClientAuthId(infected, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, CarAlarmTriggerReason) VALUES ('%s', '%s', '%s', '%s');", sTFormatAll[caralarmtriggered], sMapName, sSteamID, sSteamID2, sCarAlarmTriggerReason[reason]);
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, caralarmtriggered);
}

public void OnBoomerPop(int survivor, int boomer, int shoveCount, float timeAlive)
{
	if (!g_cvarEnable.BoolValue || !g_cvarBoomerPop.BoolValue)
		return;

	if (IsFakeClient(survivor) || IsFakeClient(boomer))
		return;

	fkn_log(true, "Skill detected | BoomerPop | Survivor:%N Boomer:%N ShoveCount:%d TimeAlive:%.1f", survivor, boomer, shoveCount, timeAlive);
	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetClientAuthId(boomer, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (map, survivor, infected, shoveCount, timeAlive) VALUES ('%s', '%s', '%s', '%d', '%.1f');", sTFormatAll[boomerpop], sMapName, sSteamID, sSteamID2, shoveCount, timeAlive);
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, boomerpop);
}

public void OnSpecialClear(int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove)
{
	if (!g_cvarEnable.BoolValue || !g_cvarSpecialClear.BoolValue)
		return;

	if (IsFakeClient(clearer) || IsFakeClient(pinner) || IsFakeClient(pinvictim))
		return;


	fkn_log(true, "Skill detected | SpecialClear | Clearer:%N Pinner:%N PinVictim:%N ZombieClass:%s TimeA:%.1f TimeB:%.1f WithShove:%d", clearer, pinner, pinvictim, L4D2ZombieClassname[zombieClass], timeA, timeB, withShove, view_as<int>(withShove));
	char
		sSteamID[64],
		sSteamID2[64],
		sSteamID3[64],
		sMapName[32];

	GetClientAuthId(clearer, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetClientAuthId(pinner, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));
	GetClientAuthId(pinvictim, AuthId_SteamID64, sSteamID3, sizeof(sSteamID3));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
		"INSERT INTO `%s`( \
			map, \
			clearer, \
			pinner, \
			pinvictim, \
			zombieclass, \
			timeA, \
			timeB, \
			withShove) \
		VALUES('%s','%s','%s','%s','%s','%.1f','%.1f','%d');",
		sTFormatAll[specialclear], sMapName, sSteamID, sSteamID2, sSteamID3, L4D2ZombieClassname[zombieClass], timeA, timeB, view_as<int>(withShove));
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, specialclear);
}

public void OnHunterHighPounce(int hunter, int survivor, int actualDamage, float calculatedDamage, float height, bool reportedHigh)
{
	if (!g_cvarEnable.BoolValue || !g_cvarHunterHighPounce.BoolValue)
		return;

	if (IsFakeClient(survivor) || IsFakeClient(hunter))
		return;

	fkn_log(true, "Skill detected | HunterHighPounce | Survivor:%N Hunter:%N ActualDamage:%d CalculatedDamage:%.1f Height:%.1f ReportedHigh:%d", survivor, hunter, actualDamage, calculatedDamage, height, view_as<int>(reportedHigh));
	char
		sSteamID[64],
		sSteamID2[64],
		sMapName[32];

	GetClientAuthId(survivor, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	GetClientAuthId(hunter, AuthId_SteamID64, sSteamID2, sizeof(sSteamID2));
	GetCurrentMap(sMapName, sizeof(sMapName));

	char sQuery[300];
	g_ForsakenDB.Format(sQuery, sizeof(sQuery), 
		"INSERT INTO `%s`( \
			map, \
			survivor, \
			infected, \
			actualDamage, \
			calculatedDamage, \
			height, \
			reportedHigh) \
		VALUES('%s', '%s', '%s', '%d', '%.1f', '%.1f', '%d');",
		sTFormatAll[hunterhighpounce], sMapName, sSteamID, sSteamID2, actualDamage, calculatedDamage, height, view_as<int>(reportedHigh));
	g_ForsakenDB.Query(UpdateTFormatALL, sQuery, hunterhighpounce);
}

public void UpdateTFormatALL(Database db, DBResultSet results, const char[] error, any iTable)
{
	if (results == null)
		ThrowError("Error UpdateTFormat2 %s: %s", sTFormatAll[iTable], error);
}