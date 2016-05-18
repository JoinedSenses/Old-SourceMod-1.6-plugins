#pragma semicolon 1

#include <sourcemod>

#define MAX_LINE_LENGTH			   192		// maximum length of a single line of text
#define PLUGIN_DEBUG				 1		// debug mode enabled when set

new Handle:g_minAlphaCount = INVALID_HANDLE;		// minimum amount of alphanumeric characters
new Handle:g_maxPercent = INVALID_HANDLE;			// Maximum percent of characters thay may be uppercase
new Handle:g_isEnabled = INVALID_HANDLE;			// Var for storing whether the plugin is enabled


public Plugin:myinfo = 
{
	name = "Don't Shout",
	author = "Brainstorm",
	description = "Changes chat messages to lowercase when they are (almost) fully in uppercase",
	version = "1.0",
	url = "http://"	
};

public OnPluginStart()
{
	// load translation files
	LoadTranslations("common.phrases");

	// create convars
	g_isEnabled = CreateConVar("bd_shout_enabled", "1", "Whether the anti-shout plugin is enabled.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_maxPercent = CreateConVar("bd_shout_percent", "0.7", "Percent of alphanumeric characters that need to be uppercase before the plugin will kick in.", 0, true, 0.01, true, 1.0);
	g_minAlphaCount = CreateConVar("bd_shout_mincharcount", "3", "Minimum amount of alphanumeric characters before the sentence will be altered.");

	// listen for commands
	RegConsoleCmd("say", Command_HandleSay);
	RegConsoleCmd("say2", Command_HandleSay);
	RegConsoleCmd("say_team", Command_HandleSay);
}

public OnPluginEnd()
{
	CloseHandle(g_isEnabled);
	CloseHandle(g_maxPercent);
	CloseHandle(g_minAlphaCount);
}

public Action:Command_HandleSay(client, args)
{
	// do not handle console stuff and do not work when the plugin is disabled
	if (client < 1 || !GetConVarBool(g_isEnabled))
	{
		return Plugin_Continue;
	}
	
	// get argument string
	decl String:argString[MAX_LINE_LENGTH];
	GetCmdArgString(argString, sizeof(argString));
	
	new upperCount = 0;			// total amount of upper text chars
	new totalCount = 0;			// total amount of text chars (no numeric or other chars)
	for (new i = 0; i < strlen(argString); i++)
	{
		if (IsCharAlpha(argString[i]))
		{
			totalCount++;
			if (IsCharUpper(argString[i]))
			{
				upperCount++;
			}
		}
	}
	
	// calculate percentage of characters that is uppercase & get convar values
	new Float:percentageUpper = float(upperCount) / float(totalCount);
	new Float:maxPercent = GetConVarFloat(g_maxPercent);
	new minCharCount = GetConVarInt(g_minAlphaCount);
	
	if (totalCount >= minCharCount && percentageUpper >= maxPercent)
	{
		// remove the surrounding quotes, if they are present
		if (argString[0] == '"' && argString[strlen(argString) - 1] == '"')
		{
			// bit of an ugly call to substring, but it'll always work here.
			SubString(argString, argString, 1, strlen(argString) - 1);
		}
		
		// replace all alphanumeric chars, except the first char
		for (new i=1; i < strlen(argString); i++)
		{
			if (IsCharAlpha(argString[i]))
			{
				argString[i] = CharToLower(argString[i]);
			}
		}
		
		// get the original command
		decl String:command[20];
		GetCmdArg(0, command, sizeof(command));

		// Have the client say the altered text.
		FakeClientCommand(client, "%s \"%s\"", command, argString);
		
		// We've handled it.
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}

public StrToLower(String:arg[])
{
	for (new i = 0; i < strlen(arg); i++)
	{
		arg[i] = CharToLower(arg[i]);
	}
}

public ClientName(client, String:name[MAX_NAME_LENGTH])
{
	if (client == 0)
	{
		name = "[console]";
	}
	else
	{
		GetClientName(client, name, sizeof(name));
	}
}

public SubString(const String:text[], String:result[MAX_LINE_LENGTH], startIndex, endIndex)
{
	// check input
	new length = endIndex - startIndex;
	if (length <= 0 || startIndex >= strlen(text))
	{
		return;
	}
	
	// perform char-by-char copy
	for(new index = 0; index < length; index++)
	{
		result[index] = text[index + startIndex];
	}

	// add termination character	
	result[length] = '\0';
}