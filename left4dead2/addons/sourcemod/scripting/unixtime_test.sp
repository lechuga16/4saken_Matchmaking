#include <sourcemod>
#include <unixtime_sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= "Unixtime Sourcemod Test",
	author		= "Bugsy",
	description = "tests the unixtime_sourcemod library",
	version		= "1.0",
	url			= "https://forums.alliedmods.net/showthread.php?t=300350"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_servertime", Command_ServerTime);
	RegConsoleCmd("sm_subtractdates", Command_SubtractDates);
}

public Action Command_ServerTime(int iClient, int iArgs)
{
	if (iArgs != 0)
	{
		ReplyToCommand(iClient, "Usage: sm_servertime");
		return Plugin_Handled;
	}

	int
		iYear,
		iMonth,
		iDay,
		iHour,
		iMinute,
		iSecond,
		iTime = GetTime();

	char
		szBuffer[524],
		szTmpBuffer[64],
		szTime[64];

	Format(szTmpBuffer, sizeof(szTmpBuffer), "GetTime() = %d\n", iTime);
	StrCat(szBuffer, sizeof(szBuffer), szTmpBuffer);

	UnixToTime(iTime, iYear, iMonth, iDay, iHour, iMinute, iSecond);
	Format(szTime, sizeof(szTime), "%02d/%02d/%d %02d:%02d:%02d", iMonth, iDay, iYear, iHour, iMinute, iSecond);

	Format(szTmpBuffer, sizeof(szTmpBuffer), "GetTime() -> UnixToTime = %s\n", szTime);
	StrCat(szBuffer, sizeof(szBuffer), szTmpBuffer);

	ReplyToCommand(iClient, "%s", szBuffer);

	CreateTimesTamp(iClient, szTime, true);
	CreateTimesTamp(iClient, szTime, false);
	return Plugin_Handled;
}

public void CreateTimesTamp(int iClient, char[] szTime, bool full)
{
	int
		iYear,
		iMonth,
		iDay,
		iHour,
		iMinute,
		iSecond,
		iTimeStamp;

	char
		szBuffer[524],
		szTmpBuffer[64];

	if (full)
		iTimeStamp = ToTimestamp(szTime, true);
	else
		iTimeStamp = ToTimestamp(szTime);

	Format(szTmpBuffer, sizeof(szTmpBuffer), "Date -> Timestamp: %d\n", iTimeStamp);
	StrCat(szBuffer, sizeof(szBuffer), szTmpBuffer);

	UnixToTime(iTimeStamp, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);

	Format(szTmpBuffer, sizeof(szTmpBuffer), "Timestamp -> Date: %02d/%02d/%d %02d:%02d:%02d", iMonth, iDay, iYear, iHour, iMinute, iSecond);
	StrCat(szBuffer, sizeof(szBuffer), szTmpBuffer);

	ReplyToCommand(iClient, "%s\n%s\n", full ? "[Full Time | mm/dd/yyyy HH:MM:SS]" : "[Time | mm/dd/yyyy]", szBuffer);
}

stock int ToTimestamp(const char[] szDate, bool full = false)
{
	char szBuffer[64];
	strcopy(szBuffer, sizeof(szBuffer), szDate);

	ReplaceString(szBuffer, sizeof(szBuffer), "/", " ");
	ReplaceString(szBuffer, sizeof(szBuffer), ".", " ");
	ReplaceString(szBuffer, sizeof(szBuffer), ":", " ");

	char szTime[6][6];
	ExplodeString(szBuffer, " ", szTime, sizeof(szTime), sizeof(szTime[]));

	int
		iYear  = StringToInt(szTime[2]),
		iMonth = StringToInt(szTime[0]),
		iDay   = StringToInt(szTime[1]),

		iHour,
		iMinute,
		iSecond;

	if (full)
	{
		iHour	= StringToInt(szTime[3]),
		iMinute = StringToInt(szTime[4]),
		iSecond = StringToInt(szTime[5]);
	}

	return TimeToUnix(iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
}

public Action Command_SubtractDates(int iClient, int iArgs)
{
	if (iArgs != 2)
	{
		ReplyToCommand(iClient, "Usage: sm_subtractdates <minuend time> <subtrahend time>");
		return Plugin_Handled;
	}

	int
		iYear,
		iMonth,
		iDay,
		iHour,
		iMinute,
		iSecond,
		iMinuend,
		iSubtrahend,
		iDifference;

	char szBuffer[64];

	GetCmdArg(1, szBuffer, sizeof(szBuffer));
	iMinuend = StringToInt(szBuffer);

	GetCmdArg(2, szBuffer, sizeof(szBuffer));
	iSubtrahend = StringToInt(szBuffer);

	iDifference = iMinuend - iSubtrahend;

	UnixToTime(iDifference, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);

	ReplyToCommand(iClient, "UnixTime: %d\nMonth: %d | Day: %d | Year: %d\nHour: %d | Minute: %d | Second: %d", iDifference, iMonth, iDay, iYear, iHour, iMinute, iSecond);

	return Plugin_Handled;
}