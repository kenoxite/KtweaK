// Spawn the drone

if (isNil {KTWK_GRdrone_player}) then { KTWK_GRdrone_player = call KTWK_fnc_playerUnit; };
    
private _playerPos = getPos vehicle KTWK_GRdrone_player;
private _UAV = createVehicle ["B_UAV_01_F", vehicle KTWK_GRdrone_player getRelPos [2, 0], [], 0, "NONE"];
createVehicleCrew _UAV;
private _grp = createGroup playerSide;
{[_x] joinSilent _grp} count crew _UAV;
// Disable misc stuff for the drone
_UAV spawn {
    // Stalker Voices
    private _unitsArray = missionNamespace getVariable ["FGSVunits",[]];
    // Disable voices
    {
        _x setSpeaker "NoVoice";
        // Project SFX
        _x setVariable ["disableUnitSFX", true];
        // Disable Stalker Voices
        if !(isNil {_unitsArray}) then {
            waitUntil {sleep 1; _x in _unitsArray || !alive _x || isNull _x};
            if (alive _x) then {
                private _idx = _unitsArray find _x;
                _unitsArray deleteAt _idx;
                missionNamespace setVariable ["FGSVunits",_unitsArray];
            };
        };
    } forEach crew _this;
};
// Position drone
_UAV setDir getDir vehicle KTWK_GRdrone_player;
private _pos = getPos _UAV;
private _posASL = AGLtoASL _pos;
_UAV allowDamage false;
KTWK_playerAllowDamage = isDamageAllowed KTWK_GRdrone_player;
KTWK_GRdrone_player allowDamage false;
driver _UAV action ["engineOn", _UAV];
_UAV action ["autoHover", _UAV];
// Start on the ground if inside a building and flying otherwise
if (lineIntersects [_posASL, _posASL vectorAdd [0,0,10]]) then {
    _UAV setPosATL [_pos#0, _pos#1, getPosATL vehicle KTWK_GRdrone_player #2 + 1];
    _UAV setVelocity [0, 0, 1];
} else {
    _UAV setPosATL [_pos#0, _pos#1, getPosATL vehicle KTWK_GRdrone_player #2 + 2];
    _UAV setVelocity [0, 0, 15];
};
// Give control to the player
player remoteControl driver _UAV;
_UAV switchCamera "internal";
// Check for manual disconnects and automatic ones caused by the drone being too far away or time running out
[_UAV, _playerPos] spawn {
    params ["_UAV", "_playerPos"];
    private _fnc_UAVdisconnect = {
        // Check if drone should be deleted due to distance or time
        params ["_time", "_UAV", "_UAVpos", "_playerPos"];
        private _disconnect = false;
        // Check for time
        if (_time >= KTWK_GRdrone_opt_maxTime) then {
            _disconnect = true;
            hintSilent parseText "<t color='#FF0000'>Battery drained</t>";
        };
        // Check for distance
        if(_UAVpos distance2D _playerPos > KTWK_GRdrone_opt_maxDist) then {
            _disconnect = true;
            hintSilent parseText "<t color='#FF0000'>Signal lost</t>";
        };
        // // Check for team switch
        // private _playerUnit = call KTWK_fnc_playerUnit;
        // if(KTWK_GRdrone_player != _playerUnit && !call KTWK_fnc_GRdrone_playerInUAV) then {
        //     player remoteControl _playerUnit;
        //     _disconnect = true;
        // };
        // Return control to the player unit proper if there's an automatic disconnect
        if (_disconnect) then {
            objNull remoteControl driver _UAV;
            KTWK_GRdrone_player switchCamera "internal";
        };
    };
    // Keep an eye on the current drone status
    private _timer = 0;
    private _batteryLeft = 100;
    while {alive _UAV && alive KTWK_GRdrone_player && call KTWK_fnc_GRdrone_playerInUAV && KTWK_GRdrone_opt_enabled} do
    {
        // AI won't attack if altitude is over 25m
        // private _pos = getPosATL _UAV;
        // private _h = _pos#2;
        // if (_h > 25) then {
        //     _UAV setCaptive true;
        // } else {
        //     _UAV setCaptive false;
        // };
        // Display current drone status
        private _dist = round ((getPos _UAV) distance2D _playerPos);
        private _timeLeft = (KTWK_GRdrone_opt_maxTime - _timer) max 0;
        _batteryLeft = 100 - round((round (KTWK_GRdrone_opt_maxTime - _timeLeft)/KTWK_GRdrone_opt_maxTime)*100);
        hintSilent parseText format [
                "<t align='left'>Battery: <t color='#%3'>%1%5</t>
                <br/>Signal: <t color='#%4'>%2</t>
                </t>",
                _batteryLeft,
                if (_dist < KTWK_GRdrone_opt_maxDist*0.25) then {"Strong"} else {if (_dist < KTWK_GRdrone_opt_maxDist*0.5) then {"Normal"} else {if (_dist < KTWK_GRdrone_opt_maxDist*0.75) then {"Weak"} else {"Very Weak"}}},
                if (_batteryLeft > 50) then {"00FF00"} else {if (_batteryLeft > 25) then {"FFFF00"} else {"FF0000"}},
                if (_dist < KTWK_GRdrone_opt_maxDist*0.25) then {"00FF00"} else {if (_dist < KTWK_GRdrone_opt_maxDist*0.5) then {"FFFF00"} else {if (_dist < KTWK_GRdrone_opt_maxDist*0.75) then {"f78205"} else {"FF0000"}}},
                "%"
            ];
        // Check for automatic disconnect
        [_timer, _UAV, getPos _UAV, _playerPos] call _fnc_UAVdisconnect;
        // Disable invincibility after 3 s
        if (_timer >= 3) then {
            _UAV allowDamage true;
            KTWK_GRdrone_player allowDamage KTWK_playerAllowDamage;
        };
        // Project SFX
        KTWK_GRdrone_player setVariable ["disableUnitSFX", true];
        // Update timer and wait
        _timer = _timer + 1;
        sleep 1;
    };
    // Delete drone if disconnected
    hintSilent "";
    // Set battery left to 0 if the drone was destroyed
    if (!alive _UAV) then { _batteryLeft = 0 };
    // Return control to player
    objNull remoteControl driver _UAV;
    KTWK_GRdrone_player switchCamera "internal";
    // Project SFX
    KTWK_GRdrone_player setVariable ["disableUnitSFX", false];
    // Delete the drone
    deleteVehicleCrew _UAV;
    deleteVehicle _UAV;
    // Keep track of the remaining battery since last use, so recharge will start at the current battery level
    KTWK_GRdrone_lastUse = time - (KTWK_GRdrone_opt_reuseTime*(_batteryLeft/100));
};
