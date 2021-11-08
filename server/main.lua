ESX = nil

TriggerEvent('esx:getSharedObject', function(obj)
	ESX = obj
end)

ESX.RegisterServerCallback('ps_tankstelle:buy', function(source, cb, change)
	
	local s = source
	local x = ESX.GetPlayerFromId(s)
	local p = change * 1.15

	if x.getMoney() >= p then
		x.removeMoney(round(change * 1.15, 0))
		cb(true)
	else
		cb(false)
	end

end)

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
  end