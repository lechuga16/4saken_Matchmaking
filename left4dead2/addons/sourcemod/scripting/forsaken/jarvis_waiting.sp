#if defined _jarvis_waiting_included
	#endinput
#endif
#define _jarvis_waiting_included

public void WaitingPlayers()
{
	if (!g_cvarEnable.BoolValue || !LGO_IsMatchModeLoaded())
		return;

	g_hTimerWait = CreateTimer(30.0, Timer_PrintMessageFiveTimes, _, TIMER_REPEAT);
}

public void OnRoundIsLive()
{
	if(g_hTimerWait != null)
		KillTimer(g_hTimerWait);
	
	if(g_cvarDebug.BoolValue)
		CPrintToChatAll("KillTimer(g_hTimerWait)");
}

public Action Timer_PrintMessageFiveTimes(Handle timer)
{
	static int iCycles = 0;

	switch (iCycles)
	{
		case 0:
		{
			CPrintToChatAll("[J.A.R.V.I.S] Quedan 3 minutos de espera");
		}
		case 2:
		{
			CPrintToChatAll("[J.A.R.V.I.S] Quedan 2 minutos de espera");
		}
		case 4:
		{
			CPrintToChatAll("[J.A.R.V.I.S] Quedan 1 minutos de espera");
		}
		case 5:
		{
			CPrintToChatAll("[J.A.R.V.I.S] Quedan 30 segundos de espera");
		}
		case 6:
		{
			CPrintToChatAll("[J.A.R.V.I.S] Quedan 0 segunos de espera");
			iCycles = 0;
			return Plugin_Stop;
		}
	}

	iCycles++;
	return Plugin_Continue;
}