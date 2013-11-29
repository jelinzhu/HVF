library Trigger /* v1.0.3.1
************************************************************************************
*
*   */ uses /*
*   
*       */ ErrorMessage         /*          hiveworkshop.com/forums/submissions-414/snippet-error-message-239210/
*       */ BooleanExpression    /*          hiveworkshop.com/forums/jass-resources-412/snippet-booleanexpression-240411/
*       */ NxList               /*          hiveworkshop.com/forums/jass-resources-412/snippet-linked-list-node-233937/
*
************************************************************************************
*
*   struct Trigger extends array
*           
*       Fields
*       -------------------------
*
*           readonly trigger trigger
*               -   use to register events, nothing else
*               -   keep in mind that triggers referencing this trigger won't fire when events fire
*               -   this trigger will fire when triggers referencing this trigger are fired
*
*           boolean enabled
*
*       Methods
*       -------------------------
*
*           static method create takes nothing returns Trigger
*           method destroy takes nothing returns nothing
*
*           method register takes boolexpr expression returns TriggerCondition
*
*           method reference takes Trigger trig returns TriggerReference
*               -   a referenced trigger will run before this trigger
*               -   referenced triggers run in order of reference
*
*           method fire takes nothing returns nothing
*
*           method clear takes nothing returns nothing
*               -   clears expressions
*           method clearReferences takes nothing returns nothing
*               -   clears trigger references
*           method clearBackReferences takes nothing returns nothing
*               -   removes references for all triggers referencing this trigger
*           method clearEvents takes nothing returns nothing
*               -   clears events
*
*           debug static method calculateMemoryUsage takes nothing returns integer
*           debug static method getAllocatedMemoryAsString takes nothing returns string
*
************************************************************************************
*
*   struct TriggerReference extends array
*           
*       Methods
*       -------------------------
*
*           method destroy takes nothing returns nothing
*
*           method replace takes Trigger trigger returns nothing
*
************************************************************************************
*
*   struct TriggerCondition extends array
*
*       Methods
*       -------------------------
*
*           method destroy takes nothing returns nothing
*
*           method replace takes boolexpr expr returns nothing
*
************************************************************************************/
    private struct TriggerMemory extends array
        trigger trig
        triggercondition tc
    
        BooleanExpression expression                //the trigger's expression
        
        BooleanExpression triggerExpression         //the trigger's complete expression (refs)
        BooleanExpression triggerExpressionNode     //the trigger's registration to complete expression
        
        boolean enabled
        
        method updateTrigger takes nothing returns nothing
            if (tc != null) then
                call TriggerRemoveCondition(trig, tc)
            endif
        
            if (enabled and triggerExpression.expression != null) then
                set tc = TriggerAddCondition(trig, triggerExpression.expression)
            else
                set tc = null
            endif
        endmethod
    endstruct

    private struct TriggerAllocator extends array
        implement Alloc
    endstruct
    
    private keyword TriggerReferencedList
    
    private struct TriggerReferenceListData extends array
        TriggerMemory trig              //the referenced trigger
        TriggerReferencedList ref       //the TriggerReferencedList data for that trigger (relationship in 2 places)
        BooleanExpression expr
    
        implement NxList
    endstruct

    /*
    *   List of triggers referencing current trigger
    */
    private struct TriggerReferencedList extends array
        TriggerMemory trig              //the trigger referencing this trigger
        TriggerReferenceListData ref    //the ref
    
        implement NxList
        
        method updateExpression takes nothing returns nothing
            local thistype node
            local boolexpr expr
            
            /*
            *   Retrieve the expression of the referenced trigger
            */
            if (TriggerMemory(this).enabled) then
                set expr = TriggerMemory(this).triggerExpression.expression
            else
                set expr = null
            endif
            
            /*
            *   Iterate over all triggers referencing this trigger
            */
            set node = first
            loop
                exitwhen node == 0
                
                /*
                *   Replace expression and then update the target trigger
                */
                call node.ref.expr.replace(expr)
                call node.trig.updateTrigger()
                call TriggerReferencedList(node.trig).updateExpression()
                
                set node = node.next
            endloop
            
            set expr = null
        endmethod
        
        method purge takes nothing returns nothing
            local thistype node = first
            
            loop
                exitwhen node == 0
                
                /*
                *   Unregister the expression from the referencing trigger
                *   Update that trigger
                */
                call node.ref.expr.unregister()
                call node.trig.updateTrigger()
                call node.ref.remove()
                call TriggerReferencedList(node.trig).updateExpression()
                
                set node = node.next
            endloop
            
            call destroy()
        endmethod
        
        method clearReferences takes nothing returns nothing
            local thistype node = first
            
            loop
                exitwhen node == 0
                
                /*
                *   Unregister the expression from the referencing trigger
                *   Update that trigger
                */
                call node.ref.expr.unregister()
                call node.trig.updateTrigger()
                call node.ref.remove()
                call TriggerReferencedList(node.trig).updateExpression()
                
                set node = node.next
            endloop
            
            call clear()
        endmethod
    endstruct
    
    /*
    *   List of triggers current trigger references
    */
    private struct TriggerReferenceList extends array
        method add takes TriggerReferencedList trig returns thistype
            local TriggerReferenceListData node = TriggerReferenceListData(this).enqueue()
            
            /*
            *   Register the trigger as a reference
            */
            set node.trig = trig
            set node.ref = TriggerReferencedList(trig).enqueue()
            set node.ref.trig = this
            set node.ref.ref = node
            
            /*
            *   Add the reference's expression
            *
            *   Add even if null to ensure correct order
            */
            set node.expr = TriggerMemory(this).triggerExpressionNode
            if (TriggerMemory(this).enabled) then
                set TriggerMemory(this).triggerExpressionNode = TriggerMemory(this).triggerExpression.register(TriggerMemory(this).expression.expression)
            else
                set TriggerMemory(this).triggerExpressionNode = TriggerMemory(this).triggerExpression.register(null)
            endif
            if (TriggerMemory(trig).enabled) then
                call node.expr.replace(TriggerMemory(trig).triggerExpression.expression)
            else
                call node.expr.replace(null)
            endif
            
            call TriggerMemory(this).updateTrigger()
            
            /*
            *   Update the expressions of triggers referencing this trigger
            */
            call TriggerReferencedList(this).updateExpression()
            
            /*
            *   Return the reference
            */
            return node
        endmethod
        
        method erase takes nothing returns nothing
            local TriggerReferenceListData node = this          //the node
            set this = node.ref.trig                            //this trigger        
            
            call node.expr.unregister()
            call TriggerMemory(this).updateTrigger()
            call TriggerReferencedList(this).updateExpression()
            
            call node.ref.remove()
            call node.remove()
        endmethod
        
        method replace takes TriggerMemory trig returns nothing
            local TriggerReferenceListData node = this
            set this = node.list
            
            call node.ref.remove()
            
            set node.trig = trig
            set node.ref = TriggerReferencedList(trig).enqueue()
            set node.ref.trig = this
            set node.ref.ref = node
            
            if (trig.enabled) then
                call node.expr.replace(trig.triggerExpression.expression)
            else
                call node.expr.replace(null)
            endif
            
            call TriggerMemory(this).updateTrigger()
            
            call TriggerReferencedList(this).updateExpression()
        endmethod
        
        /*
        *   Purges all references
        */
        method purge takes nothing returns nothing
            local TriggerReferenceListData node = TriggerReferenceListData(this).first
            
            loop
                exitwhen node == 0
                
                /*
                *   Removes the reference from the referenced list
                *   (triggers no longer referenced by this)
                */
                call node.ref.remove()
                
                set node = node.next
            endloop
            
            /*
            *   Destroy all references by triggers referencing this
            */
            call TriggerReferencedList(this).purge()
            
            call TriggerReferenceListData(this).destroy()
        endmethod
        
        method clearReferences takes nothing returns nothing
            local TriggerReferenceListData node = TriggerReferenceListData(this).first
            
            loop
                exitwhen node == 0
                
                /*
                *   Removes the reference from the referenced list
                *   (triggers no longer referenced by this)
                */
                call node.ref.remove()
                
                set node = node.next
            endloop
            
            call TriggerReferenceListData(this).clear()
        endmethod
    endstruct
    
    private struct TriggerReferenceData extends array
        debug private boolean isTriggerReference
        
        static method create takes TriggerReferenceList origin, TriggerMemory ref returns thistype
            local thistype this = origin.add(ref)
            
            debug set isTriggerReference = true
            
            return this
        endmethod
        
        method destroy takes nothing returns nothing
            debug call ThrowError(this == 0,                "Trigger", "destroy", "TriggerReferenceData", this, "Attempted To Destroy Null TriggerReferenceData.")
            debug call ThrowError(not isTriggerReference,   "Trigger", "destroy", "TriggerReferenceData", this, "Attempted To Destroy Invalid TriggerReferenceData.")
            
            debug set isTriggerReference = false
            
            call TriggerReferenceList(this).erase()
        endmethod
        
        method replace takes Trigger trig returns nothing
            debug call ThrowError(this == 0,                "Trigger", "destroy", "TriggerReferenceData", this, "Attempted To Destroy Null TriggerReferenceData.")
            debug call ThrowError(not isTriggerReference,   "Trigger", "destroy", "TriggerReferenceData", this, "Attempted To Destroy Invalid TriggerReferenceData.")
            
            call TriggerReferenceList(this).replace(trig)
        endmethod
    endstruct
    
    private struct TriggerConditionData extends array
        debug private boolean isCondition
        private TriggerMemory trig
        
        private static method updateTrigger takes TriggerMemory trig returns nothing
            if (trig.enabled) then
                call trig.triggerExpressionNode.replace(trig.expression.expression)
            else
                call trig.triggerExpressionNode.replace(null)
            endif
            call trig.updateTrigger()
            call TriggerReferencedList(trig).updateExpression()
        endmethod
    
        static method create takes TriggerMemory trig, boolexpr expression returns thistype
            local thistype this = trig.expression.register(expression)
            
            set this.trig = trig
            
            debug set isCondition = true
            
            call updateTrigger(trig)
            
            return this
        endmethod
        
        method destroy takes nothing returns nothing
            debug call ThrowError(this == 0,        "Trigger", "destroy", "TriggerConditionData", this, "Attempted To Destroy Null TriggerConditionData.")
            debug call ThrowError(not isCondition,  "Trigger", "destroy", "TriggerConditionData", this, "Attempted To Destroy Invalid TriggerConditionData.")
            
            call BooleanExpression(this).unregister()
            
            debug set isCondition = false
            
            /*
            *   Update the expression
            */
            call updateTrigger(trig)
        endmethod
        
        method replace takes boolexpr expr returns nothing
            debug call ThrowError(this == 0,        "Trigger", "destroy", "TriggerConditionData", this, "Attempted To Destroy Null TriggerConditionData.")
            debug call ThrowError(not isCondition,  "Trigger", "destroy", "TriggerConditionData", this, "Attempted To Destroy Invalid TriggerConditionData.")
            
            call BooleanExpression(this).replace(expr)
            
            call updateTrigger(trig)
        endmethod
    endstruct
    
    struct TriggerReference extends array
        method destroy takes nothing returns nothing
            call TriggerReferenceData(this).destroy()
        endmethod
        method replace takes Trigger trig returns nothing
            call TriggerReferenceData(this).replace(trig)
        endmethod
    endstruct
    
    struct TriggerCondition extends array
        method destroy takes nothing returns nothing
            call TriggerConditionData(this).destroy()
        endmethod
        method replace takes boolexpr expr returns nothing
            call TriggerConditionData(this).replace(expr)
        endmethod
    endstruct
    
    struct Trigger extends array
        debug private boolean isTrigger
    
        static method create takes nothing returns thistype
            local thistype this = TriggerAllocator.allocate()
            
            debug set isTrigger = true
            
            set TriggerMemory(this).enabled = true
            
            call TriggerReferencedList(this).clear()
            call TriggerReferenceListData(this).clear()
            
            set TriggerMemory(this).expression = BooleanExpression.create()
            set TriggerMemory(this).triggerExpression = BooleanExpression.create()
            set TriggerMemory(this).triggerExpressionNode = TriggerMemory(this).triggerExpression.register(null)
            
            set TriggerMemory(this).trig = CreateTrigger()
            
            return this
        endmethod
        method destroy takes nothing returns nothing
            debug call ThrowError(this == 0,        "Trigger", "destroy", "Trigger", this, "Attempted To Destroy Null Trigger.")
            debug call ThrowError(not isTrigger,    "Trigger", "destroy", "Trigger", this, "Attempted To Destroy Invalid Trigger.")
            
            debug set isTrigger = false
        
            call TriggerReferenceList(this).purge()
            
            if (TriggerMemory(this).tc != null) then
                call TriggerRemoveCondition(TriggerMemory(this).trig, TriggerMemory(this).tc)
            endif
            set TriggerMemory(this).tc = null
            call DestroyTrigger(TriggerMemory(this).trig)
            set TriggerMemory(this).trig = null
            
            call TriggerMemory(this).expression.destroy()
            call TriggerMemory(this).triggerExpression.destroy()
            
            call TriggerAllocator(this).deallocate()
        endmethod

        method register takes boolexpr expression returns TriggerCondition
            debug call ThrowError(this == 0,            "Trigger", "register", "Trigger", this, "Attempted To Register To Null Trigger.")
            debug call ThrowError(not isTrigger,        "Trigger", "register", "Trigger", this, "Attempted To Register To Invalid Trigger.")
        
            /*
            *   Register the expression
            */
            return TriggerConditionData.create(this, expression)
        endmethod
        
        method clear takes nothing returns nothing
            debug call ThrowError(this == 0,        "Trigger", "clear", "Trigger", this, "Attempted To Clear Null Trigger.")
            debug call ThrowError(not isTrigger,    "Trigger", "clear", "Trigger", this, "Attempted To Clear Invalid Trigger.")
        
            call TriggerMemory(this).expression.clear()
            call TriggerMemory(this).triggerExpressionNode.replace(null)
            call TriggerMemory(this).updateTrigger()
            call TriggerReferencedList(this).updateExpression()
        endmethod
        
        method clearReferences takes nothing returns nothing
            debug call ThrowError(this == 0,        "Trigger", "clearReferences", "Trigger", this, "Attempted To Clear References Of Null Trigger.")
            debug call ThrowError(not isTrigger,    "Trigger", "clearReferences", "Trigger", this, "Attempted To Clear References Of Invalid Trigger.")
            
            call TriggerReferenceList(this).clearReferences()
            
            call TriggerMemory(this).triggerExpression.clear()
            set TriggerMemory(this).triggerExpressionNode = TriggerMemory(this).triggerExpression.register(TriggerMemory(this).expression.expression)
            call TriggerMemory(this).updateTrigger()
            call TriggerReferencedList(this).updateExpression()
        endmethod
        
        method clearBackReferences takes nothing returns nothing
            debug call ThrowError(this == 0,        "Trigger", "clearReferences", "Trigger", this, "Attempted To Clear Back References Of Null Trigger.")
            debug call ThrowError(not isTrigger,    "Trigger", "clearReferences", "Trigger", this, "Attempted To Clear Back References Of Invalid Trigger.")
            
            call TriggerReferencedList(this).clearReferences()
        endmethod
        
        method reference takes thistype trig returns TriggerReference
            debug call ThrowError(this == 0,            "Trigger", "reference", "Trigger", this, "Attempted To Make Null Trigger Reference Trigger.")
            debug call ThrowError(not isTrigger,        "Trigger", "reference", "Trigger", this, "Attempted To Make Invalid Trigger Reference Trigger.")
            debug call ThrowError(trig == 0,            "Trigger", "reference", "Trigger", this, "Attempted To Reference Null Trigger (" + I2S(trig) + ").")
            debug call ThrowError(not trig.isTrigger,   "Trigger", "reference", "Trigger", this, "Attempted To Reference Invalid Trigger (" + I2S(trig) + ").")
            
            return TriggerReferenceData.create(this, trig)
        endmethod
        
        method clearEvents takes nothing returns nothing
            debug call ThrowError(this == 0,        "Trigger", "clearEvents", "Trigger", this, "Attempted To Clear Events Of Null Trigger.")
            debug call ThrowError(not isTrigger,    "Trigger", "clearEvents", "Trigger", this, "Attempted To Clear Events Of Invalid Trigger.")
        
            if (TriggerMemory(this).tc != null) then
                call TriggerRemoveCondition(TriggerMemory(this).trig, TriggerMemory(this).tc)
            endif
            call DestroyTrigger(TriggerMemory(this).trig)
            
            set TriggerMemory(this).trig = CreateTrigger()
            if (TriggerMemory(this).enabled) then
                set TriggerMemory(this).tc = TriggerAddCondition(TriggerMemory(this).trig, TriggerMemory(this).triggerExpression.expression)
            else
                set TriggerMemory(this).tc = null
            endif
        endmethod
        
        method fire takes nothing returns nothing
            debug call ThrowError(this == 0,        "Trigger", "fire", "Trigger", this, "Attempted To Fire Null Trigger.")
            debug call ThrowError(not isTrigger,    "Trigger", "fire", "Trigger", this, "Attempted To Fire Invalid Trigger.")
        
            call TriggerEvaluate(TriggerMemory(this).trig)
        endmethod
        
        method operator trigger takes nothing returns trigger
            debug call ThrowError(this == 0,        "Trigger", "trigger", "Trigger", this, "Attempted To Read Null Trigger.")
            debug call ThrowError(not isTrigger,    "Trigger", "trigger", "Trigger", this, "Attempted To Read Invalid Trigger.")
        
            return TriggerMemory(this).trig
        endmethod
        
        method operator enabled takes nothing returns boolean
            debug call ThrowError(this == 0,                                "Trigger", "enabled", "Trigger", this, "Attempted To Read Null Trigger.")
            debug call ThrowError(not isTrigger,                            "Trigger", "enabled", "Trigger", this, "Attempted To Read Invalid Trigger.")
            
            return TriggerMemory(this).enabled
        endmethod
        
        method operator enabled= takes boolean enable returns nothing
            debug call ThrowError(this == 0,                                "Trigger", "enabled=", "Trigger", this, "Attempted To Set Null Trigger.")
            debug call ThrowError(not isTrigger,                            "Trigger", "enabled=", "Trigger", this, "Attempted To Set Invalid Trigger.")
            debug call ThrowWarning(TriggerMemory(this).enabled == enable,  "Trigger", "enabled=", "Trigger", this, "Setting Enabled To Its Value.")
        
            set TriggerMemory(this).enabled = enable
            
            call TriggerMemory(this).updateTrigger()
            call TriggerReferencedList(this).updateExpression()
        endmethod
        
        static if DEBUG_MODE then
            static method calculateMemoryUsage takes nothing returns integer
                return TriggerAllocator.calculateMemoryUsage() + TriggerReferenceListData.calculateMemoryUsage() + TriggerReferencedList.calculateMemoryUsage() + BooleanExpression.calculateMemoryUsage()
            endmethod
            
            static method getAllocatedMemoryAsString takes nothing returns string
                return "(Trigger)[" + TriggerAllocator.getAllocatedMemoryAsString() + "], (Trigger Reference)[" + TriggerReferenceListData.getAllocatedMemoryAsString() + "], (Trigger Reference Back)[" + TriggerReferencedList.getAllocatedMemoryAsString() + "], (Boolean Expression (all))[" + BooleanExpression.getAllocatedMemoryAsString() + "]"
            endmethod
        endif
    endstruct
endlibrary