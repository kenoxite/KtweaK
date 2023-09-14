//
private _allInfantry = KTWK_allInfantry - [player];

// Check all infantry units
{
    private _stealth = KTWK_BIR_stealth_opt_enabled;
    private _nvg = KTWK_BIR_NVG_illum_opt_enabled;
    private _wpn = KTWK_BIR_wpn_illum_opt_enabled;
    // Reset illuminators status
    [_x] call BettIR_fnc_nvgIlluminatorOff;
    [_x] call BettIR_fnc_weaponIlluminatorOff;
    private _behaviour = behaviour _x;
    private _inStealth = _behaviour == "STEALTH";
    if (_stealth == 0 && _inStealth) then {continue};   // Disable if in stealth mode
    // Darkness check for moonlight, overcast and wether the unit is inside a building or not
    private _posASL = getPosASL _x;
    private _tooDark = overcast > 0.6 || moonIntensity < 0.1 || insideBuilding _x > 0.9;
    // Enable NVG Illuminator
    [_x] call BettIR_fnc_nvgIlluminatorOff;
    if (_nvg > 0
        && (
            _stealth == 0 && !_inStealth
            || _stealth == 1   // Enable always regardless of stealth mode
            || (_stealth == 2 && !_inStealth)   // Enable if not in stealth mode
            || _stealth == 3    // Enable if only weapon illuminators are disabled
            )
        ) then {
        if (_nvg == 1
            || (_nvg > 1 && _tooDark)
            ) then {
            if (alive _x) then {[_x] call BettIR_fnc_nvgIlluminatorOn};
        };   
    };
    // Enable weapon Illuminator
    [_x] call BettIR_fnc_weaponIlluminatorOff;
    if (_wpn > 0
        && (
            _stealth == 0 && !_inStealth
            || _stealth == 1    // Enable always regardless of stealth mode
            || _stealth == 2   // Enable if only NVGs illuminators are disabled
            || (_stealth == 3 && !_inStealth)  // Enable if not in stealth mode 
            )
        ) then {
        if (_wpn == 1
            || (
                _wpn == 2 && _tooDark
                || (_wpn == 3 && _tooDark && _behaviour == "COMBAT")
                )
            ) then {
            if (alive _x) then {[_x] call BettIR_fnc_weaponIlluminatorOn};
        };
    };
} forEach _allInfantry;


// Disable illuminators from dead infantry
{
    [_x] call BettIR_fnc_nvgIlluminatorOff;
    [_x] call BettIR_fnc_weaponIlluminatorOff;
} forEach allDeadMen;
