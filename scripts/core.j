library_once Core initializer init/* v0.0.1 Adrian
*************************************************************************************
* 	HVF Core library which provides some useful functions
*
* 
*
*************************************************************************************
*	I'd like to put name convention here
*	function		:	funcion FunctionName
*	struct			:	struct StructName
*	struct.method	:	method methodName
*	struct.initializer: onInit
*	library.initializer: init
************************************************************************************/

	globals
		private boolean bSinglePlayer = ReloadGameCachesFromDisk()
	endglobals

	function IsSinglePlayer takes nothing returns boolean
		return bSinglePlayer
	endfunction
	struct TimeManager
	endstruct
	
	/*
	**************************************************************************************
	* Prevent Save : hiveworkshop.com/forums/jass-resources-412/snippet-preventsave-158048/
	*	@provide by TriggerHappy
	**************************************************************************************
	*/
	globals
        boolean GameAllowSave = false
    endglobals
    
    globals
        private dialog DummyDialog = DialogCreate()
        private timer  Timer  = CreateTimer()
        private player localplayer
    endglobals
    
    function PreventSave takes player p, boolean flag returns nothing
    	if (p == localplayer) then
    		set GameAllowSave = not flag
    	endif
    endfunction
    
    private function Exit takes nothing returns boolean
    	call DialogDisplay(localplayer, DummyDialog, false)
    endfunction
    
    private function StopSave takes nothing returns boolean
    	if not GameAllowSave then
    		call DialogDisplay(localplayer, DummyDialog, true)
    	endif
    	call TimerStart(timer, 0.00, false, function Exit)
    	return false  	
    endfunction
    
    // library initilaizer
    private function init takes nothing returns nothing
    	local trigger t = CreateTrigger()
    	set localplayer = GetLocalPlayer()
    	
    	call TriggerRegisterGameEvent(t, EVENT_GAME_SAVE)
    	call TriggerAddCondition(t, function StopSave)
    endfunction
    
endlibrary
