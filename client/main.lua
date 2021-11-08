local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}


ESX = nil
local PlayerData = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
end)

local blips = {
}

local enableField = false
local nearPump = false

function open(vehicle)
    SetNuiFocus(true, true)
	enableField = true

	SendNUIMessage({
	
		action = "open",
		fuel = GetVehicleFuelLevel(vehicle)

    })
end
  
function close()
	SetNuiFocus(false, false)
	enableField = false
	
	SendNUIMessage({
		action = "close"
	})
end

RegisterNUICallback('escape', function(data, cb)
	close()
end)

local allowedPumps = 
{
    [-2007231801] = true,
	[1339433404] = true,
	[1694452750] = true,
	[1933174915] = true,
	[-462817101] = true,
	[-469694731] = true,
	[-164877493] = true
}

function FindNearestFuelPump()
	local coords = GetEntityCoords(PlayerPedId())
	local fuelPumps = {}
	local handle, object = FindFirstObject()
	local success

	repeat
		if allowedPumps[GetEntityModel(object)] then
			table.insert(fuelPumps, object)
		end

		success, object = FindNextObject(handle, object)
	until not success

	EndFindObject(handle)

	local pumpObject = 0
	local pumpDistance = 1000

	for _, fuelPumpObject in pairs(fuelPumps) do
		local dstcheck = GetDistanceBetweenCoords(coords, GetEntityCoords(fuelPumpObject))

		if dstcheck < pumpDistance then
			pumpDistance = dstcheck
			pumpObject = fuelPumpObject
		end
	end

	return pumpObject, pumpDistance
end

CreateThread(function()
    while true do
        local pumpObject, pumpDistance = FindNearestFuelPump()

		if pumpDistance < 3.5 then
            nearPump = pumpObject
        else
            nearPump = false 
        end

        Wait(500)
    end
end)

CreateThread(function()
    while true do
        Wait(0)

		if nearPump then
			local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)

			if GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), GetEntityCoords(veh)) <= 5000.0 then
				if IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
					ESX.ShowHelpNotification("Drücke ~INPUT_CONTEXT~ um zu tanken")

					if IsControlJustReleased(0, 38) then
						open(vehicle)
					end
				end
			end
			
        end
    end
end)

Citizen.CreateThread(function()
    for _, coords in pairs(blips) do
        local blip = AddBlipForCoord(coords)

        SetBlipSprite(blip, 361)
        SetBlipScale(blip, 0.9)
        SetBlipColour(blip, 1)
        SetBlipDisplay(blip, 4)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Tankstelle")
        EndTextCommandSetBlipName(blip)
    end
end)

AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() ~= name then
        return
    end

    close()
end)

RegisterNUICallback('escape', function(data, cb)
    close()
    cb('ok')
end)

RegisterNUICallback('pay', function(data, cb)
	
	local new_perc = tonumber(data.new_perc)
	local change = new_perc - Round(GetVehicleFuelLevel(GetVehiclePedIsIn(GetPlayerPed(-1), false)))

	ESX.TriggerServerCallback('ps_tankstelle:buy', function(bought)
		if bought then
			ESX.ShowNotification(('Du hast $%s bezahlt!'):format(Round(change * 1.15)))

			local veh = GetVehiclePedIsIn(GetPlayerPed(-1), true)

			if GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), GetEntityCoords(veh)) <= 5.0 then
				SetVehicleFuelLevel(veh, (GetVehicleFuelLevel(veh) + change))
			end
		else
			ESX.ShowNotification(('Du kannst %s Liter Kraftstoff nicht bezahlen'):format(change))
		end
	end, change)

    cb('ok')
end)