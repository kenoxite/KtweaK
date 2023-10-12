// Add Inventory EventHandler
// by kenoxite

// For the next weapon display to work we have to override the opening of the inventory
// Reasons being:
//  - The container holding the displayed weapon is non interactable
//  - But, even then, it will be displayed in the player's inventory when crouching or lying down
//  - That means that in those cases, any droped object will be dropped inside the container of the displayed weapon
//  - But, as the container of the displayed weapon can't be interacted with, the player is unable to drop anything in this case, as the container appears just as Ground
// The solution so far is:
//  - Delete the displayed weapon containers whenever the player opens the inventory, and display them again once its closed
//  - The problem is: this can only be done via InventoryOpened EH but, once you get there, and if you don't ovreride its behavior, it's already too late. It has already built its own array of nearby containers so, if you move or delte any close container now, the inventory screen will be closed, as the closest container is now not present (same issue as trying to open a backpack of a unit that is moving away; it auto-closes)
//  - So, the main Open Inventory action is now overriden, disabling the default behavior. It now first deletes the display containers and THEN (after 0.01, to wait for the deleteVehicle commands to take effect) it opens the inventory via Action ["Gear"]

params ["_unit"];
KTWK_EH_invOpened_ENW = _unit addEventHandler ["InventoryOpened", { 
    params ["_unit", "_container", "_container2"]; 
    _unit removeEventHandler [_thisEvent, _thisEventHandler];
    _unit setVariable ["KTWK_swappingWeapon", true]; 
    // Hide rifle holster 
    [_unit, 1, 2] call KTWK_fnc_displayHolster; 
    // Hide launcher holster 
    [_unit, 3, 2] call KTWK_fnc_displayHolster; 
    _this spawn KTWK_fnc_openInv;
    true 
}];
KTWK_EH_invClosed_ENW = player addEventHandler ["InventoryClosed", { 
    params ["_unit", "_container"]; 
    _unit removeEventHandler [_thisEvent, _thisEventHandler];
    _unit setVariable ["KTWK_swappingWeapon", false]; 
    // Display holsters 
    [_unit] call KTWK_fnc_toggleHolsterDisplay; 
}];
