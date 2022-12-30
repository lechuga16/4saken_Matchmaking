// API Glicko2 para SourcePawn

// Código baseado no artigo: http://www.glicko.net/glicko/glicko2.pdf
public void Glicko2_Init(int maxRanking)
{
	g_maxRanking = maxRanking;
	
	g_players = new array<PlayerGlickoInfo>;
	g_players.resize(maxRanking);
	
	for (int i = 0; i < maxRanking; i++)
	{
		g_players[i].rating = 1500;
		g_players[i].rd = 350;
		g_players[i].volatility = 0.06;
	}
}

public PlayerGlickoInfo Glicko2_GetPlayerInfo(int ranking)
{
	return g_players[ranking];
}

public void Glicko2_SetPlayerInfo(int ranking, PlayerGlickoInfo info)
{
	g_players[ranking] = info;
}

public void Glicko2_Update(int winnerRanking, int loserRanking)
{
	PlayerGlickoInfo winnerInfo = g_players[winnerRanking];
	PlayerGlickoInfo loserInfo = g_players[loserRanking];
	
	// Calculate the expected score
	float expectedScore = Glicko2_CalculateExpectedScore(winnerInfo, loserInfo);
	
	// Calculate the actual score
	float actualScore = Glicko2_CalculateActualScore(winnerInfo, loserInfo);
	
	// Update the ratings
	Glicko2_UpdateRatings(winnerInfo, loserInfo, expectedScore, actualScore);
}

public float Glicko2_CalculateExpectedScore(PlayerGlickoInfo winnerInfo, PlayerGlickoInfo loserInfo)
{
	float divisor = 1.0f + pow(10.0f, (loserInfo.rating - winnerInfo.rating) / 400.0f);
	return 1.0f / divisor;
}

public float Glicko2_CalculateActualScore(PlayerGlickoInfo winnerInfo, PlayerGlickoInfo loserInfo)
{
	// Assume winner won
	return 1.0f;
}

public void Glicko2_UpdateRatings(PlayerGlickoInfo winnerInfo, PlayerGlickoInfo loserInfo, float expectedScore, float actualScore)
{
	float Q = log(10.0f) / 400.0f;
	float delta = (actualScore - expectedScore);
	
	// Calculate the new ratings
	float newWinnerRating = winnerInfo.rating + (Q / (1.0f / pow(winnerInfo.rd, 2.0f) + 1.0f / (winnerInfo.volatility * winnerInfo.volatility))) * delta;
	float newLoserRating = loserInfo.rating - (Q / (1.0f / pow(loserInfo.rd, 2.0f) + 1.0f / (loserInfo.volatility * loserInfo.volatility))) * delta;
	
	// Calculate the new rating deviations
	float newWinnerRd = sqrt(1.0f / (1.0f / pow(winnerInfo.rd, 2.0f) + 1.0f / (winnerInfo.volatility * winnerInfo.volatility)));
	float newLoserRd = sqrt(1.0f / (1.0f / pow(loserInfo.rd, 2.0f) + 1.0f / (loserInfo.volatility * loserInfo.volatility)));
	
	// Calculate the new volatility
	float newWinnerVolatility = Glicko2_CalculateVolatility(winnerInfo, newWinnerRating, newWinnerRd);
	float newLoserVolatility = Glicko2_CalculateVolatility(loserInfo, newLoserRating, newLoserRd);
	
	// Update the players
	winnerInfo.rating = newWinnerRating;
	winnerInfo.rd = newWinnerRd;
	winnerInfo.volatility = newWinnerVolatility;
	
	loserInfo.rating = newLoserRating;
	loserInfo.rd = newLoserRd;
	loserInfo.volatility = newLoserVolatility;
}

public float Glicko2_CalculateVolatility(PlayerGlickoInfo playerInfo, float newRating, float newRd)
{
	float a = log(playerInfo.volatility * playerInfo.volatility);
	float d2 = pow(newRating - playerInfo.rating, 2.0f) / (pow(playerInfo.rd, 2.0f) + pow(newRd, 2.0f));
	float b = a;
	
	if (d2 > 1.0f)
		b = log(d2);
	
	b = (b - a) / 0.005f;
	
	float c = a - (b * 0.005f);
	
	return exp(c);
}