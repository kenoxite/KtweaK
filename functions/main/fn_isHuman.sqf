
params ["_unit"];
if (_unit in agents) then {_unit = agent _unit};
if (typeName _unit != "OBJECT") exitWith {false};
if (isNull _unit) exitWith {false};

private _type = typeOf _unit;
(_type isKindOf "CAManBase" && {!(_type isKindOf "UAV_AI_base_F") && !([_unit] call KTWK_fnc_isAnimal) && {!([_unit] call KTWK_fnc_isZombie)}})
