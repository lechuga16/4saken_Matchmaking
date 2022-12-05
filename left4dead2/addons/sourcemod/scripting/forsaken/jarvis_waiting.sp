#if defined _jarvis_waiting_included
	#endinput
#endif
#define _jarvis_waiting_included

public void WaitingPlayers()
{
    if(!LGO_IsMatchModeLoaded())
        return;
    
    CreateTimer(30.0, Timer_PrintMessageFiveTimes, _, TIMER_REPEAT);

}

public Action Timer_PrintMessageFiveTimes(Handle timer)
{
    static int iCycles = 0;
 
    switch(iCycles)
    {
        case 0:
        {
            CPrintToChatAll("Quedan 3 minutos de espera");
        }
        case 2:
        {
            CPrintToChatAll("Quedan 2:00 minutos de espera");
        }
        case 4:
        {
            CPrintToChatAll("Quedan 1:00 minutos de espera");
        }
        case 5:
        {
            CPrintToChatAll("Quedan 30 segundos de espera");
        }
        case 6:
        {
            CPrintToChatAll("Quedan 0 segunos de espera");
            iCycles = 0;
            return Plugin_Stop;
        }
    }

    iCycles++;
    return Plugin_Continue;
}