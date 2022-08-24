Scriptname UD_CustomDevices_NPCSlotsManager extends Quest  

import UnforgivingDevicesMain

UDCustomDeviceMain Property UDCDmain auto
UnforgivingDevicesMain Property UDmain hidden
    UnforgivingDevicesMain Function get()
        return UDCDmain.UDmain
    EndFunction    
EndProperty
Quest Property UDCD_NPCF auto ;finder
zadlibs Property libs auto
Bool Property Ready = False auto
UD_OrgasmManager Property UDOM auto
Message Property UD_FixMenu_MSG auto
Int Property UD_Slots = 10 auto
Float Property UD_SlotUpdateTime = 10.0 auto
Bool _PlayerSlotReady = false

Event OnInit()
    UD_Slots = GetNumAliases()
    int index = UD_Slots
    while index
        index -= 1
        while !(GetNthAlias(index) as UD_CustomDevice_NPCSlot).ready
            Utility.waitMenuMode(0.1)
        endwhile
        if UDmain.TraceAllowed()        
            UDCDMain.Log("NPCslot["+ index +"] ready!")
        endif
    endwhile
    registerForSingleUpdate(10.0)
    Ready = True
EndEvent

Function GameUpdate()
    CheckOrgasmLoops()
    RegisterForSingleUpdate(UDCDmain.UD_UpdateTime*2.0)
    registerForSingleUpdateGameTime(1.0)
EndFunction

Function CheckOrgasmLoops()
    int index = UD_Slots ;all aliases
    while index
        index -= 1
        UD_CustomDevice_NPCSlot loc_slot = (GetNthAlias(index) as UD_CustomDevice_NPCSlot)
        if loc_slot
            if loc_slot.isUsed() && !loc_slot.isDead()
                UDOM.CheckArousalCheck(loc_slot.getActor())
                UDOM.CheckOrgasmCheck(loc_slot.getActor())
            endif
        endif
    endwhile
EndFunction

Float   _LastUpdateTime     = 0.0
Float   _UpdateTimePassed   = 0.0
Event OnUpdate()
    ;init player slot
    if !_PlayerSlotReady
        _PlayerSlotReady = True
        initPlayerSlot()
    endif
    
    if UDmain.UDReady()
        if !UDmain.UD_DisableUpdate
            float loc_timePassed = Utility.GetCurrentGameTime() - _LastUpdateTime
            UpdateDevices(loc_timePassed)
            _LastUpdateTime = Utility.GetCurrentGameTime()
            
            if UDmain.AllowNPCSupport
                scanSlots()
            endif
        endif
        removeDeadNPCs()
        _UpdateTimePassed += UDCDmain.UD_UpdateTime
        if _UpdateTimePassed >= 120.0
            CheckOrgasmLoops()
            UpdateSlots() ;update slots, this only update variables, not devices
            _UpdateTimePassed = 0.0
        endif
    endif
    RegisterForSingleUpdate(UDCDmain.UD_UpdateTime)
EndEvent

float LastUpdateTime_Hour = 0.0 ;last time the update happened in days
Event OnUpdateGameTime()
    if UDmain.UDReady()
        if !UDmain.UD_DisableUpdate
            Utility.waitMenuMode(Utility.randomFloat(2.0,4.0))
            float currentgametime = Utility.GetCurrentGameTime()
            float mult = 24.0*(currentgametime - LastUpdateTime_Hour) ;multiplier for how much more then 1 hour have passed, ex: for 2.5 hours passed without update, the mult will be 2.5
            UpdateDevicesHour(mult)
            LastUpdateTime_Hour = Utility.GetCurrentGameTime()
        endif
    endif
    registerForSingleUpdateGameTime(1.0)
endEvent

Function UpdateSlots()
    int index = UD_Slots ;all aliases
    while index
        index -= 1
        UD_CustomDevice_NPCSlot loc_slot = (GetNthAlias(index) as UD_CustomDevice_NPCSlot)
        if loc_slot.isUsed()
            if !loc_slot.isDead()
                loc_slot.UpdateSlot()
            endif
        endif
    endwhile
EndFunction

;bool _updating = false
bool Function scanSlots(bool debugMsg = False)
    ;if !_updating
    ;    _updating = True
        ;getPlayerSlot().regainDevices()
        UDCD_NPCF.Stop()
        UDCD_NPCF.Start()
        ;removeDeadNPCs()
        ;resetNPCFSlots()
        updateSlotedActors(debugMsg)
        return true
    ;    _updating = False
    ;    return true
    ;else
    ;    return false
    ;endif
EndFunction

Function CheckSlots()
    int index = UD_Slots - 1 ;all aliases, excluding player
    while index
        index -= 1
        UD_CustomDevice_NPCSlot loc_slot = (UDCD_NPCF.GetNthAlias(index) as UD_CustomDevice_NPCSlot)
        if loc_slot
            if loc_slot.isUsed()
                loc_slot.QuickFix()
            endif
        endif
    endwhile
EndFunction

Function resetNPCFSlots()
    int index = UD_Slots - 1 ;all aliases, excluding player
    while index
        index -= 1
        ReferenceAlias loc_refAl = (UDCD_NPCF.GetNthAlias(index) as ReferenceAlias)
        if loc_refAl.getActorReference()
            Actor loc_akActor = loc_refAl.getActorReference()
            if !isInPlayerCell(loc_akActor) && !StorageUtil.GetIntValue(loc_akActor, "UD_GlobalUpdate" , 0)
                loc_refAl.clear()
            endif
        endif
    endwhile
EndFunction

bool Function isInPlayerCell(Actor akActor)
    if UDmain.Player.getParentCell() == akActor.getParentCell()
        return true
    else
        return false
    endif
EndFunction

Function initPlayerSlot()
    getPlayerSlot().ForceRefTo(UDmain.Player)
    UDOM.CheckOrgasmCheck(UDmain.Player)
    UDOM.CheckArousalCheck(UDmain.Player)
    if UDmain.TraceAllowed()    
        UDCDMain.Log("PlayerSlot ready!")
    endif
EndFunction

Function removeDeadNPCs()
    int index = UD_Slots - 1 ;all aliases, excluding player
    while index
        index -= 1
        UD_CustomDevice_NPCSlot loc_slot = (GetNthAlias(index) as UD_CustomDevice_NPCSlot)
        if loc_slot.isUsed()
            if loc_slot.isDead()
                unregisterNPC(loc_slot.getActor(),true)
            endif
        endif
    endwhile
EndFunction

Function updateSlotedActors(bool debugMsg = False)
    int index = UDCD_NPCF.GetNumAliases() - 1;all slots excluding player
    int mover = 0
    while index
        index -= 1
        Actor currentSelectedActor = (UDCD_NPCF.GetNthAlias(index + mover) as ReferenceAlias).getActorReference()
        if currentSelectedActor
            if !StorageUtil.GetIntValue(currentSelectedActor, "UD_blockSlotUpdate", 0)
                UD_CustomDevice_NPCSlot slot = GetNthAlias(index) as UD_CustomDevice_NPCSlot
                Actor currentSlotActor = slot.getActor()
                if StorageUtil.GetIntValue(currentSlotActor, "UD_ManualRegister", 0)
                    mover -= 1
                else
                    if currentSlotActor
                        if currentSelectedActor != currentSlotActor                        
                            currentSlotActor.RemoveFromFaction(UDCDmain.RegisteredNPCFaction)
                            slot.unregisterSlot()
                            
                            slot.SetSlotTo(currentSelectedActor)        
                            if debugMsg || UDmain.DebugMod
                                debug.notification("[UD]: NPC /" + slot.getSlotedNPCName() + "/ registered!")
                            endif
                            UDmain.Info("Registered NPC " + getActorName(currentSelectedActor))
                        endif
                    else
                        slot.unregisterSlot()
                        slot.SetSlotTo(currentSelectedActor)
                        
                        if debugMsg || UDmain.DebugMod
                            debug.notification("[UD]: NPC /" + slot.getSlotedNPCName() + "/ registered!")
                        endif
                        UDmain.Info("Registered NPC " + getActorName(currentSelectedActor))
                    endif
                    
                    ;if slot.isUsed()
                    ;    slot.regainDevices()
                    ;endif
                endif
            endif
        else
            UD_CustomDevice_NPCSlot slot = GetNthAlias(index) as UD_CustomDevice_NPCSlot
            if slot.isUsed() && !StorageUtil.GetIntValue(slot.getActor(), "UD_ManualRegister", 0)
                slot.unregisterSlot()
            endif
        endif
    endwhile
EndFunction

bool Function RegisterNPC(Actor akActor,bool debugMsg = false)
    int mover = 0
    Actor currentSelectedActor = akActor
    if !currentSelectedActor
        UDmain.Error("RegisterNPC - none actor passed!")
        return false
    endif
    
    if isRegistered(akActor)
        UDmain.Error("RegisterNPC - " + GetActorName(akActor) + " is already registered!")
        return false
    endif
    
    int index = 0
    while index < UD_Slots - 1
        if !StorageUtil.GetIntValue(currentSelectedActor, "UD_blockSlotUpdate", 0)
            UD_CustomDevice_NPCSlot slot = GetNthAlias(index) as UD_CustomDevice_NPCSlot
            Actor currentSlotActor = slot.getActor()
            if !currentSlotActor
                slot.unregisterSlot()
                slot.SetSlotTo(currentSelectedActor)
                StorageUtil.SetIntValue(currentSelectedActor, "UD_ManualRegister", 1)
                if debugMsg || UDCDmain.UDmain.DebugMod
                    debug.notification("[UD]: NPC slot ["+ index +"] => " + slot.getSlotedNPCName() + " registered!")
                endif
                UDmain.Info(GetActorName(akActor) + " registered!")
                return true
            endif
        endif
        index += 1
    endwhile
    UDmain.Error("RegisterNPC - Can't find free slot for " + GetActorName(akActor) + " !")
    return false
EndFunction

Function regainDeviceSlots(Form akActor, int slotID,String sSlotedActorName)
    getNPCSlotByIndex(slotID).regainDevices()
EndFunction

UD_CustomDevice_NPCSlot Function getNPCSlotByActor(Actor akActor)
    if akActor == UDmain.Player
        return getPlayerSlot()
    endif
    int index = UD_Slots
    while index
        index -= 1
        if (GetNthAlias(index) as ReferenceAlias).GetActorReference() == akActor
            return GetNthAlias(index) as UD_CustomDevice_NPCSlot
        endif
    endwhile
    return none
EndFunction

int Function getPlayerIndex()
    return UD_Slots - 1
EndFunction

int Function getNumSlots()
    return UD_Slots
EndFunction

bool Function isRegistered(Actor akActor)
    return akActor.isInFaction(UDCDmain.RegisteredNPCFaction)
EndFunction

UD_CustomDevice_NPCSlot Function getNPCSlotByName(string sName)
    return GetAliasByName(sName) as UD_CustomDevice_NPCSlot
EndFunction

UD_CustomDevice_NPCSlot Function getNPCSlotByActorName(string sName)
    if sName == UDmain.Player.getLeveledActorBase().getName()
        return getPlayerSlot()
    endif
    int index = UD_Slots
    while index
        index -= 1
        UD_CustomDevice_NPCSlot slot = (GetNthAlias(index) as UD_CustomDevice_NPCSlot)
        if slot.isUsed()
            if slot.getSlotedNPCName() == sName
                return slot
            endif
        endif
    endwhile
    return none
EndFunction

UD_CustomDevice_NPCSlot Function getNPCSlotByIndex(int iIndex)
    return GetNthAlias(iIndex) as UD_CustomDevice_NPCSlot
EndFunction

UD_CustomDevice_NPCSlot Function getPlayerSlot()
    return GetNthAlias(UD_Slots - 1) as UD_CustomDevice_NPCSlot
EndFunction

Function UpdateDevices(float fTimePassed)
    int index = UD_Slots
    while index
        index -= 1
        UD_CustomDevice_NPCSlot loc_slot = (GetNthAlias(index) as UD_CustomDevice_NPCSlot)
        if loc_slot.isScriptRunning() && loc_slot.isUsed() && loc_slot.canUpdate()
            loc_slot.update(fTimePassed)
        endif
    endwhile
EndFunction

Function UpdateDevicesHour(float fMult)
    int index = UD_Slots
    while index
        index -= 1
        UD_CustomDevice_NPCSlot loc_slot = (GetNthAlias(index) as UD_CustomDevice_NPCSlot)
        if loc_slot.isScriptRunning() && loc_slot.isUsed() && loc_slot.canUpdate()
            loc_slot.updateHour(fMult)
        endif
    endwhile
EndFunction

bool Function NPCAlreadyRegistred(Actor akActor)
    return akActor.isInFaction(UDCDmain.RegisteredNPCFaction)
EndFunction

int Function numberOfFreeSlots()
    int res = 0
    int index = UD_Slots
    while index
        index -= 1
        if !((GetNthAlias(index) as UD_CustomDevice_NPCSlot).GetActorReference()) && !(GetNthAlias(index) as UD_CustomDevice_NPCSlot).isPlayer()
            res += 1
        endif
    endwhile
    return res
EndFunction

bool Function unregisterNPC(Actor akActor,bool bDebugMsg = false)
    if !isRegistered(akActor)
        return false
    endif
    int index = UD_Slots - 1
    while index
        index -= 1
        UD_CustomDevice_NPCSlot slot = (GetNthAlias(index) as UD_CustomDevice_NPCSlot)
        Actor loc_slotedNPC = slot.getActor()
        if loc_slotedNPC == akActor
            slot.unregisterSlot()
            StorageUtil.UnSetIntValue(loc_slotedNPC, "UD_blockSlotUpdate")
            akActor.RemoveFromFaction(UDCDmain.RegisteredNPCFaction)
            if bDebugMsg || UDCDmain.UDmain.DebugMod
                debug.notification("[UD]: NPC slot ["+ index +"] = " + getActorName(loc_slotedNPC) + " =>  unregistered!")
            endif
            return True
        endif
    endwhile
    return False
EndFunction
