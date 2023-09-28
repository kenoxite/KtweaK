// Disable voice mods for non humans
private _isUnitDisabled = false;

// Stalker voices
private _stalkerArray = missionNamespace getVariable ["FGSVunits",[]];
private _stalkerInstalled = !isNil {_stalkerArray};
{
    [_x] call KTWK_fnc_disableVoice;
    _isUnitDisabled = true;
    // Disable Stalker Voices
    if (_stalkerInstalled) then {
        _isUnitDisabled = false;
        private _idx = _stalkerArray find _x;
        if (_idx >= 0) then {
            _stalkerArray deleteAt _idx;
            missionNamespace setVariable ["FGSVunits",_stalkerArray];
            _isUnitDisabled = true;
        };
    };
    if (_isUnitDisabled) then {
         _x setVariable ["KTWK_disabledVoice", true];
    };
} forEach (KTWK_allCreatures select {!(_x getVariable ["KTWK_disabledVoice", false])});
