// -----------------------------------------------
// KtweaK - Init
// by kenoxite
// -----------------------------------------------

// Wait for player init
waitUntil {!isNull player && time > 1};

KTWK_allInfantry = [];
KTWK_allCreatures = [];
KTWK_allAnimals = [];
KTWK_allPredators = [];

// SOG ambient voices
if (!isNil {vn_sam_masteraudioarray}) then {
    call KTWK_fnc_toggleSOGvoices;
};

// Init - Humidity Effects
KTWK_scr_HFX = [] execVM "KtweaK\scripts\humidityFX.sqf";

// Global system loop
KTWK_scr_update = [{
    private _allUnits = allUnits;
    private _agents = agents;

    // Update all creatures array
    KTWK_allCreatures = _allUnits select { !([_x] call KTWK_fnc_isHuman) };
    (_agents select { alive agent _x && {!([_x] call KTWK_fnc_isHuman)}}) apply { KTWK_allCreatures pushBack (agent _x); };

    // Update all animals array
    KTWK_allAnimals = KTWK_allCreatures select {[_x] call KTWK_fnc_isAnimal};
    (_agents select { alive agent _x && {[_x] call KTWK_fnc_isAnimal}}) apply { KTWK_allAnimals pushBack (agent _x); };

    // Update all infantry units array
    KTWK_allInfantry = _allUnits select {!(_x in KTWK_allCreatures)};

    // Disable voice mods for non humans
    if (KTWK_disableVoices_opt_creatures) then {
        call KTWK_fnc_disableVoiceCheck;
    };

    // Fatal Wounds
    if (KTWK_FW_opt_enabled && time > 10) then { [] call KTWK_fnc_FW_checkUnits };

    // BettIR - auto enable NVG illuminator for all units
    if (!isNil "BettIR_fnc_nvgIlluminatorOn") then {
        if ((KTWK_BIR_NVG_illum_opt_enabled > 0 || KTWK_BIR_wpn_illum_opt_enabled > 0)) then { [] call KTWK_fnc_BIR_checkUnits };
    };

    // AI will defend from predators
    KTWK_allPredators = KTWK_allAnimals select {_x isKindOf "Edaly_Crocodile_Base"};
    if (KTWK_opt_AIPredDefense_enable) then {
        {
            if !(_x getVariable ["KTWK_predatorInit", false]) then {
                _x setVariable ["KTWK_predatorInit", true];
                
                // Exclude already captives, suppossedly done on purpose in the editor or script to exclude this particular predator from all this
                if (captive _x) then { continue };

                // Set predator as renegade but switch to CIV side for the time being
                _x addRating -10000;
                _x setCaptive true;

                // Give rating back to killer, to not become renegade after successive kills
                _x addEventHandler ["Killed", {
                    params ["_unit", "_killer", "_instigator", "_useEffects"];
                    if (!isNull _instigator) then { _instigator addRating 1000 };
                }];

                // Set to aggressive if predator gets damaged by someone, so other units can join in and further attackers won't get flagged as renegades if they kill it
                _x addEventHandler ["HandleDamage", {
                    params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint", "_directHit"];
                    if (!isNull _instigator) then { _unit setCaptive false };
                }];

                // Allow AI units to defend if predator gets too close to another infantry AI or player
                _x spawn {
                    params ["_pred"];
                    while {alive _pred} do {
                        if (KTWK_opt_AIPredDefense_enable && {captive _pred}) then {
                            private _target = ((_pred targets [true, KTWK_opt_AIPredDefense_dist]) select {typeOf _x != typeOf _pred})#0;
                            // Predator approaching and dangerous
                            if (!isNil {_target}) then {
                                _pred setCaptive false;
                                // // Set all the close predators as aggressive. Otherwise a stray bullet killing one of the "non dangerous" ones will mark the killer as renegade
                                // private _closePredators = KTWK_allPredators select {_x != _pred && {_x distance2D _pred <= 200}};
                                // { _x setCaptive false; } forEach _closePredators;
                            };
                        };
                        sleep 1;
                    };
                };
            };
        } foreach KTWK_allPredators;
    };

}, 3, []] call CBA_fnc_addPerFrameHandler;

// AI auto enable IR laser
["CAManBase", "fired", {
    if (!KTWK_laser_opt_enabled || {currentVisionMode (_this#0) != 1}) exitwith {};
    // Enable IR laser
    (_this#0) enableIRLasers true;
    _this spawn {
        sleep 2;
        // Disable IR laser
        (_this#0) enableIRLasers false;
    };
}, true, [], true] call CBA_fnc_addClassEventHandler;

// AI stop when healed
["CAManBase", "HandleHeal", {
    if (!KTWK_SFH_opt_enabled) exitwith {};
    params ["_injured", "_healer"];
    // Only apply when healer is a player or a player controlled unit and also if injured unit is local to the player
    private _players = allPlayers - entities "HeadlessClient_F";
    if (!local _injured || (!(_healer in _players) && !(remoteControlled _healer in _players))) exitwith {};
    _this spawn {
        params ["_injured", "_healer"];
        private _damage = damage _injured;
        private _startTime = time;
        _injured disableAI "MOVE";
        waitUntil {damage _injured != _damage || !alive _injured || !alive _healer || (time - _startTime) > 30};
        _injured enableAI "MOVE";
        // Add some mission rating to the player to reward being an active healer, based on amount healed
        if (damage _injured != _damage) then {
            _healer addRating (round (200 * _damage));
        };
    };
}, true, [], true] call CBA_fnc_addClassEventHandler;

// ACE Map Flashlights
["CAManBase", "init", {
    if (!KTWK_ACEfl_opt_enabled || !isClass (configfile >> "CfgVehicles" >> "ACE_Flashlight_KSF1Item")) exitwith {};
    params ["_unit"];
    if (!alive _unit) exitwith {};
    private _fl = [
        "ACE_Flashlight_MX991",
        "ACE_Flashlight_XL50",
        "ACE_Flashlight_KSF1"
        ];
    // Exit if unit already has one
    private _hasFl = false;
    private _unitItems = itemsWithMagazines _unit;
    {if (_x in _unitItems) then { _hasFl = true }} forEach _fl;
    if (_hasFl) exitwith {};
    // Give appropriate flashlight based on settings
    private _side = side _unit;
    private _item = "";
    call {
        if (_side == west && {KTWK_ACEfl_opt_BLUFOR > 0}) exitWith {
            if (KTWK_ACEfl_opt_BLUFOR < 4) then {
                _item = _fl#(KTWK_ACEfl_opt_BLUFOR-1);
            } else {
                _item = selectRandom _fl;
            };
        };
        if (_side == east && {KTWK_ACEfl_opt_OPFOR > 0}) exitWith {
            if (KTWK_ACEfl_opt_OPFOR < 4) then {
                _item = _fl#(KTWK_ACEfl_opt_OPFOR-1);
            } else {
                _item = selectRandom _fl;
            };
        };
        if (_side == resistance && {KTWK_ACEfl_opt_INDEP > 0}) exitWith {
            if (KTWK_ACEfl_opt_INDEP < 4) then {
                _item = _fl#(KTWK_ACEfl_opt_INDEP-1);
            } else {
                _item = selectRandom _fl;
            };
        };
        if (_side == civilian && {KTWK_ACEfl_opt_CIV > 0}) exitWith {
            if (KTWK_ACEfl_opt_CIV < 4) then {
                _item = _fl#(KTWK_ACEfl_opt_CIV-1);
            } else {
                _item = selectRandom _fl;
            };
        };
    }; 
    if (_item != "") then { _unit addItem _item };
}, true, [], true] call CBA_fnc_addClassEventHandler;

// Init - Health HUD
KTWK_scr_HUD_health = [] execVM "KtweaK\scripts\HUD_health.sqf";

// Init - Ghost Recon Drone
KTWK_scr_GRdrone = [] execVM "KtweaK\scripts\reconDrone.sqf";

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

addMissionEventHandler ["TeamSwitch", {
    params ["_previousUnit", "_newUnit"];

    // GR Drone
    private _actionId = _previousUnit getVariable ["KTWK_GRdrone_actionId", -1];
    if (_actionId >= 0) then {
        _previousUnit removeAction _actionId;
        _previousUnit setVariable ["KTWK_GRdrone_actionId", nil];
    };
    terminate KTWK_scr_GRdrone;
    _this spawn {
        waitUntil {scriptDone KTWK_scr_GRdrone};
        KTWK_scr_GRdrone = [] execVM "KtweaK\scripts\reconDrone.sqf";
        player remoteControl (_this#1); // Make double sure control is restored to the player
    };
}];
