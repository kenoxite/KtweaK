// -----------------------------------------------
// KtweaK - Client
// by kenoxite
// -----------------------------------------------

// Wait for player init
waitUntil {!isNull player && time > 1};

KTWK_player = player;

// --------------------------------
// Equip Next Weapon
private ["_wpns"];
// - Add rifle holster to player unit
if (KTWK_ENW_opt_displayRifle) then {
    _wpns = [KTWK_player, 1, false] call KTWK_fnc_equipNextWeapon;
    if (count _wpns > 0) then {
        [KTWK_player, 1, 0, KTWK_ENW_opt_riflePos, (_wpns#1)] call KTWK_fnc_displayHolster;
    };
};
// - Add launcher holster to player unit
if (KTWK_ENW_opt_displayLauncher) then {
    _wpns = [KTWK_player, 3, false] call KTWK_fnc_equipNextWeapon;
    if (count _wpns > 0) then {
        [KTWK_player, 3, 0, KTWK_ENW_opt_launcherPos, (_wpns#1)] call KTWK_fnc_displayHolster;
    };
};
// Add inventory EH
KTWK_player call KTWK_fnc_addInvEH;

// Arsenal EH
[missionNamespace, "arsenalPreOpen", {
    params ["_missionDisplay", "_center"];
    // Check for all weapons stored in inventory and save it's attachments to reapply them after arsenal is closed
    KTWK_player setVariable ["KTWK_uniformWeapons", ([KTWK_player, "uniform"] call KTWK_fnc_unitContainerItems)#1];
    KTWK_player setVariable ["KTWK_vestWeapons", ([KTWK_player, "vest"] call KTWK_fnc_unitContainerItems)#1];
    KTWK_player setVariable ["KTWK_backpackWeapons", ([KTWK_player, "backpack"] call KTWK_fnc_unitContainerItems)#1];
}] call BIS_fnc_addScriptedEventHandler;

[missionNamespace, "arsenalOpened", {
    params ["_displayNull", "_toggleSpace"];
    KTWK_player setVariable ["KTWK_arsenalOpened", true, true];
    // Reapply attachments by deleting the base weapons and adding a version with all the attachments
    {
        [uniformContainer KTWK_player, (_x#0)] call CBA_fnc_removeWeaponCargo;
        (uniformContainer KTWK_player) addWeaponWithAttachmentsCargo [_x, 1];
    } forEach (KTWK_player getVariable "KTWK_uniformWeapons");
    KTWK_player setVariable ["KTWK_uniformWeapons", nil];

    {
        [vestContainer KTWK_player, (_x#0)] call CBA_fnc_removeWeaponCargo;
        (vestContainer KTWK_player) addWeaponWithAttachmentsCargo [_x, 1];
    } forEach (KTWK_player getVariable "KTWK_vestWeapons");
    KTWK_player setVariable ["KTWK_vestWeapons", nil];

    {
        [backpackContainer KTWK_player, (_x#0)] call CBA_fnc_removeWeaponCargo;
        (backpackContainer KTWK_player) addWeaponWithAttachmentsCargo [_x, 1];
    } forEach (KTWK_player getVariable "KTWK_backpackWeapons");
    KTWK_player setVariable ["KTWK_backpackWeapons", nil];
}] call BIS_fnc_addScriptedEventHandler;

[missionNamespace, "arsenalClosed", {
    KTWK_player setVariable ["KTWK_arsenalOpened", false, true];
}] call BIS_fnc_addScriptedEventHandler;

// --------------------------------
// Save inventory opened status so it can be retrieved remotely
KTWK_EH_invOpened = KTWK_player addEventHandler ["InventoryOpened", {(_this#0) setVariable ["KTWK_invOpened", true, true]}];
KTWK_EH_invClosed = KTWK_player addEventHandler ["InventoryClosed", {(_this#0) setVariable ["KTWK_invOpened", false, true]}];

// --------------------------------
// - ACE arsenal
[missionNamespace, "ace_arsenal_displayOpened", {
    KTWK_player setVariable ["KTWK_arsenalOpened", true, true];
}] call BIS_fnc_addScriptedEventHandler;
[missionNamespace, "ace_arsenal_displayClosed", {
    KTWK_player setVariable ["KTWK_arsenalOpened", false, true];
}] call BIS_fnc_addScriptedEventHandler;


// --------------------------------
// EH - Game loaded from save
addMissionEventHandler ["Loaded", {
    params ["_saveType"];
    diag_log format[ "KtweaK: Mission loaded from %1", _saveType ];

    // HUD Health
    _this spawn {
        waitUntil {!isNull player};
        sleep 1;
        if (!isNil {KTWK_scr_HUD_health}) then {
            terminate KTWK_scr_HUD_health;
            waitUntil {scriptDone KTWK_scr_HUD_health};
            KTWK_scr_HUD_health = [] execVM "KtweaK\scripts\HUD_health.sqf";
        };
    };
}];

// --------------------------------
// EH - Team Switch
addMissionEventHandler ["TeamSwitch", {
    params ["_previousUnit", "_newUnit"];

    // Recon Drone
    private _actionId = _previousUnit getVariable ["KTWK_GRdrone_actionId", -1];
    if (_actionId >= 0) then {
        // _previousUnit removeAction _actionId;
        [_previousUnit, _actionId] remoteExecCall ["removeAction", 0 , _previousUnit];
        _previousUnit setVariable ["KTWK_GRdrone_actionId", nil, true];
    };
    terminate KTWK_scr_GRdrone;
    _this spawn {
        waitUntil {scriptDone KTWK_scr_GRdrone};
        KTWK_scr_GRdrone = [] execVM "KtweaK\scripts\reconDrone.sqf";
        player remoteControl (_this#1); // Make double sure control is restored to the player
    };

    // Equip Next Weapon
    private ["_wpns"];
    if (KTWK_ENW_opt_displayRifle) then {
        // - Add rifle holster to _newUnit
        _wpns = [_newUnit, 1, false] call KTWK_fnc_equipNextWeapon;
        if (count _wpns > 0) then {
            [_newUnit, 1, 0, KTWK_ENW_opt_riflePos, (_wpns#1)] call KTWK_fnc_displayHolster;
        };
    };
    if (KTWK_ENW_opt_displayLauncher) then {
        // - Add launcher holster to _newUnit
        _wpns = [_newUnit, 3, false] call KTWK_fnc_equipNextWeapon;
        if (count _wpns > 0) then {
            [_newUnit, 3, 0, KTWK_ENW_opt_launcherPos, (_wpns#1)] call KTWK_fnc_displayHolster;
        };
    };
    // Add and remove inventory EH
    _newUnit call KTWK_fnc_addInvEH;
    _previousUnit removeEventHandler ["InventoryOpened", KTWK_EH_invOpened_ENW];
    _previousUnit removeEventHandler ["InventoryClosed", KTWK_EH_invClosed_ENW];

    // --------------------------------
    // Save inventory opened status so it can be retrieved remotely
    _previousUnit removeEventHandler ["InventoryOpened", KTWK_EH_invOpened];
    _previousUnit removeEventHandler ["InventoryClosed", KTWK_EH_invClosed];
    KTWK_EH_invOpened = _newUnit addEventHandler ["InventoryOpened", {(_this#0) setVariable ["KTWK_invOpened", true, true]}];
    KTWK_EH_invClosed = _newUnit addEventHandler ["InventoryClosed", {(_this#0) setVariable ["KTWK_invOpened", false, true]}];
    _previousUnit setVariable ["KTWK_invOpened", false, true];
    _newUnit setVariable ["KTWK_invOpened", false, true];
    
    _previousUnit setVariable ["KTWK_arsenalOpened", false, true];
    _newUnit setVariable ["KTWK_arsenalOpened", false, true];
}];

// --------------------------------
// Init - SOG ambient voices
if (!isNil {vn_sam_masteraudioarray}) then {
    call KTWK_fnc_toggleSOGvoices;
};

// --------------------------------
// Init - Humidity Effects
KTWK_scr_HFX = [] execVM "KtweaK\scripts\humidityFX.sqf";

// --------------------------------
// Init - Health HUD
KTWK_scr_HUD_health = [] execVM "KtweaK\scripts\HUD_health.sqf";

// Init - Ghost Recon Drone
KTWK_scr_GRdrone = [] execVM "KtweaK\scripts\reconDrone.sqf";

// --------------------------------
// Loop
KTWK_scr_updateClient = [{
    KTWK_player = call KTWK_fnc_playerUnit;

    // No map icons if no GPS
    call KTWK_fnc_GPSHideIcons;

    // Slide in slopes
    if (KTWK_slideInSlopes_opt_enabled) then {
        [KTWK_player] call KTWK_fnc_slideInSlopes;
    };

    // Equip Next Weapon
    if !(KTWK_player getVariable ["KTWK_swappingWeapon", false]) then {
        [KTWK_player] call KTWK_fnc_toggleHolsterDisplay;
    };

}, 1, []] call CBA_fnc_addPerFrameHandler;