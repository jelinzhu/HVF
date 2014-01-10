library UnitManager initializer init/* v0.0.1 Xandria
*/  uses    TimeManager     /*
********************************************************************************
*     HVF Unit management : For use of managing HuntersVsFarmers Neutral units
********************************************************************************
CreateNeutralPassiveBuildings
call SetPlayerMaxHeroesAllowed(1,GetLocalPlayer())
GetOwningPlayer
*******************************************************************************/

    
    /***************************************************************************
    * Prerequisite Functions
    ***************************************************************************/
    
    /***************************************************************************
    * Modules
    ***************************************************************************/
    
    /***************************************************************************
    * Structs
    ***************************************************************************/
    
    /***************************************************************************
    * Common Use Functions
    ***************************************************************************/
    public function IsUnitHunterHero takes unit u returns boolean
        // Hunter Heros' raw codes lays between 'U002' - 'U00D',If we find the 
        // raw code of a unit is in this range, we can consider this unit as a Hunter Hero
        return (GetUnitTypeId(u) < CST_UTI_HunterHeroLastcode) and (GetUnitTypeId(u) > CST_UTI_HunterHeroFirstcode)
    endfunction
    
    public function IsUnitFarmerHero takes unit u returns boolean
        return GetUnitTypeId(u) == CST_UTI_FarmerHero
    endfunction
    
    // Generate a randome hunter hero for player
    function GenRandomHunterHeroForPlayer takes player p, location loc returns unit
        local integer iRandom = GetRandomInt(1, CST_INT_MaxHunterHeroType)
        // Notice, 'location' would leak
        local location rctLoc = GetRectCenter(CST_RGN_SkeletonRevive)
        local integer iUnitTypeId
        
        if loc !=null then
            set rctLoc = loc
        endif
        /*
        if iRandom == 1 then
            set iUnitTypeId = 'U003'
        elseif iRandom == 2 then
            set iUnitTypeId = 'U004'
        elseif iRandom == 3 then
            set iUnitTypeId = 'U005'
        elseif iRandom == 4 then
            set iUnitTypeId = 'U006'
        elseif iRandom == 5 then
            set iUnitTypeId = 'U007'
        elseif iRandom == 6 then
            set iUnitTypeId = 'U008'
        elseif iRandom == 7 then
            set iUnitTypeId = 'U009'
        elseif iRandom == 8 then
            set iUnitTypeId = 'U00A'
        elseif iRandom == 9 then
            set iUnitTypeId = 'U00B'
        endif
        */
        return CreateUnitAtLoc(p, CST_UTI_HunterHeroFirstcode+iRandom, rctLoc, 0)
    endfunction
    
    struct UnitManager
        // Create neutral aggresive units randomly every 30s
        private static method createRandomNeutralAggrUnits takes nothing returns boolean
            local integer i = 0
            local unit u
            
            debug call BJDebugMsg("Create random units")
            
            if GetPlayerState(Player(PLAYER_NEUTRAL_AGGRESSIVE), PLAYER_STATE_RESOURCE_FOOD_USED) <= 100 then
                debug call BJDebugMsg("Create random units")
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Rabbit, MapLocation.randomX, MapLocation.randomY, CST_Facing_Unit)
                call UnitAddItem(u, CreateItem(CST_ITI_RabbitMeat, GetUnitX(u), GetUnitY(u)))
                
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Deer, MapLocation.randomX, MapLocation.randomY, CST_Facing_Unit)
                call UnitAddItem(u, CreateItem(CST_ITI_Venision, GetUnitX(u), GetUnitY(u)))
                
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Dog, MapLocation.randomX, MapLocation.randomY, CST_Facing_Unit)
                call UnitAddItem(u, CreateItem(CST_ITI_DogMeat, GetUnitX(u), GetUnitY(u)))
                
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Vulture, MapLocation.randomX, MapLocation.randomY, CST_Facing_Unit)
                call UnitAddItem(u, CreateItem(CST_ITI_VultureMeat, GetUnitX(u), GetUnitY(u)))
            endif
            
            set u = null
            return false
        endmethod
        
        // Create neutral aggresive units at beginning
        // This function can't be condition or filter
        static method createBeiginNeutralAggrUnits takes nothing returns boolean
            //GetRandomReal(GetRectMinX(whichRect), GetRectMaxX(whichRect)), GetRandomReal(GetRectMinY(whichRect), GetRectMaxY(whichRect))
            local rect playableRect = GetPlayableMapRect()
            local location rndLoc = GetRandomLocInRect(playableRect)
            local integer i = 0
            local unit u
            
            loop
                exitwhen i >= 10
                /*
                call BJDebugMsg("X:" + R2S(GetLocationX(rndLoc))+ ", Y:"+ R2S(GetLocationY(rndLoc)) )
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Rabbit, GetLocationX(rndLoc), GetLocationY(rndLoc), bj_UNIT_FACING)
                call UnitAddItem(u, CreateItem(CST_ITI_RabbitMeat, GetUnitX(u), GetUnitY(u)))
                call RemoveLocation(rndLoc)
                //call TriggerSleepAction(0.01)
                set rndLoc = GetRandomLocInRect(playableRect)
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Deer, GetLocationX(rndLoc), GetLocationY(rndLoc), bj_UNIT_FACING)
                call UnitAddItem(u, CreateItem(CST_ITI_Venision, GetUnitX(u), GetUnitY(u)))
                call RemoveLocation(rndLoc)
                //call TriggerSleepAction(0.01)
                set rndLoc = GetRandomLocInRect(playableRect)
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Dog, GetLocationX(rndLoc), GetLocationY(rndLoc), bj_UNIT_FACING)
                call UnitAddItem(u, CreateItem(CST_ITI_DogMeat, GetUnitX(u), GetUnitY(u)))
                call RemoveLocation(rndLoc)
                //call TriggerSleepAction(0.01)
                set rndLoc = GetRandomLocInRect(playableRect)
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Vulture, GetLocationX(rndLoc), GetLocationY(rndLoc), bj_UNIT_FACING)
                call UnitAddItem(u, CreateItem(CST_ITI_VultureMeat, GetUnitX(u), GetUnitY(u)))
                call RemoveLocation(rndLoc)
                //call TriggerSleepAction(0.01)
                set rndLoc = GetRandomLocInRect(playableRect)
                */
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Rabbit, MapLocation.randomX, MapLocation.randomY, CST_Facing_Unit)
                call UnitAddItem(u, CreateItem(CST_ITI_RabbitMeat, GetUnitX(u), GetUnitY(u)))
                
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Deer, MapLocation.randomX, MapLocation.randomY, CST_Facing_Unit)
                call UnitAddItem(u, CreateItem(CST_ITI_Venision, GetUnitX(u), GetUnitY(u)))
                
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Dog, MapLocation.randomX, MapLocation.randomY, CST_Facing_Unit)
                call UnitAddItem(u, CreateItem(CST_ITI_DogMeat, GetUnitX(u), GetUnitY(u)))
                
                set u = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), CST_UTI_Vulture, MapLocation.randomX, MapLocation.randomY, CST_Facing_Unit)
                call UnitAddItem(u, CreateItem(CST_ITI_VultureMeat, GetUnitX(u), GetUnitY(u)))
                
                set i = i + 1
            endloop
            call RemoveLocation(rndLoc)
            call RemoveRect(playableRect)
            set playableRect = null
            set u = null
            return false
        endmethod
        
        private static method onInit takes nothing returns nothing
            // call TimerManager.otGameStart.register(Filter(function thistype.createBeiginNeutralAggrUnits))
            call TimerManager.pt30s.register(Filter(function thistype.createRandomNeutralAggrUnits))
        endmethod
    endstruct
             
    
    /***************************************************************************
    * Library Initiation
    ***************************************************************************/
    private function init takes nothing returns nothing
    endfunction
endlibrary
