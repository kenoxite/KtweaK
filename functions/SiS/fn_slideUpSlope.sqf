// Plays the slidindg upslope action
// by kenoxite

params [["_unit", objNull]];

// Early exit conditions
if (isNull _unit || {!local _unit} || {!alive _unit}) exitWith {false};
if (!canSuspend) exitWith {_this spawn KTWK_fnc_slideUpSlope};

// Initialize variables
private _noWpnInHand = "snonwnon" in (animationState _unit);
private _lowered = weaponLowered _unit && !_noWpnInHand;
private _stance = stance _unit;
private _animSpeed = 3;

// Set sliding state and apply velocity
_unit setVariable ["KTWK_isSlopeSliding", true, true];
_unit setVelocityModelSpace [0, -5, 0];

// Set animation speed
[_unit, _animSpeed] remoteExecCall ["setAnimSpeedCoef", 0];

// Determine initial animation
private _wep = currentWeapon _unit;
private _initialAnim = call {
    if (_wep == primaryWeapon _unit) exitWith {"amovpercmstpsraswrfldnon_amovppnemstpsraswrfldnon"};
    if (_wep == secondaryWeapon _unit) exitWith {"amovpercmstpsraswlnrdnon_amovppnemstpsnonwnondnon"};
    if (_wep == handgunWeapon _unit) exitWith {"amovpercmstpsraswpstdnon_amovppnemstpsraswpstdnon"};
    "amovpercmstpsnonwnondnon_amovppnemstpsnonwnondnon"
};

// Apply initial animation and play sound
[_unit, _initialAnim] remoteExec ["playMoveNow", 0];
playSound3D ["KtweaK\sounds\slidingUpSlope.wss", _unit];

sleep 1;

// Exit if unit died during slide
if (!alive _unit) exitWith {
    _unit setVariable ["KTWK_isSlopeSliding", false, true];
    false
};

// Reset animation speed
[_unit, 1] remoteExecCall ["setAnimSpeedCoef", 0];

// Determine final animation
private _finalAnim = call {
    if (_stance == "STAND") exitWith {
        if (_noWpnInHand) exitWith {"amovpercmstpsnonwnondnon"};
        if (_wep == primaryWeapon _unit) exitWith {
            if (_lowered) then {"AmovPercMstpSlowWrflDnon"} else {"AmovPercMstpsrasWrflDnon"}
        };
        if (_wep == handgunWeapon _unit) exitWith {
            if (_lowered) then {"AmovPercMstpSlowWpstDnon"} else {"AmovPercMstpsrasWpstDnon"}
        };
        ""
    };
    if (_stance == "CROUCH") exitWith {
        if (_noWpnInHand) exitWith {"amovpknlmstpsnonwnondnon"};
        if (_wep == primaryWeapon _unit) exitWith {
            if (_lowered) then {"AmovPknlMstpSlowWrflDnon"} else {"AmovPknlMstpsrasWrflDnon"}
        };
        if (_wep == handgunWeapon _unit) exitWith {
            if (_lowered) then {"AmovPknlMstpSlowWpstDnon"} else {"AmovPknlMstpsrasWpstDnon"}
        };
        ""
    };
    ""
};

// Apply final animation if determined
if (_finalAnim != "") then {
    sleep 0.2;
    [_unit, _finalAnim] remoteExec ["playMoveNow", 0];
};

// Reset sliding state
_unit setVariable ["KTWK_isSlopeSliding", false, true];

true
