ESX = exports["es_extended"]:getSharedObject() -- NEW UPDATE ESX Tutoriel = https://documentation.esx-framework.org/tutorials/tutorials-esx/sharedevent

local BusyList = {
	['PlayersSearched'] = {
		serverId = true,
		identifiers = {}
	}
}

RegisterServerEvent('GangsBuilder:confiscatePlayerItem')
AddEventHandler('GangsBuilder:confiscatePlayerItem', function(target, itemType, itemName, amount)
	local _source = source
	local sourceXPlayer = ESX.GetPlayerFromId(_source)
	local targetXPlayer = ESX.GetPlayerFromId(target)
	local sourceCoords = GetEntityCoords(GetPlayerPed(_source))
	local targetCoords = GetEntityCoords(GetPlayerPed(target))
	local distance = #(sourceCoords - targetCoords)

	if distance ~= -1 and distance <= 3.0 then
		if targetXPlayer then
			if itemType == 'item_standard' then
				local targetItem = targetXPlayer.getInventoryItem(itemName)
		
				if targetItem.count >= amount and targetItem.count > 0 then
					if sourceXPlayer.canCarryItem(itemName, amount) then
						targetXPlayer.removeInventoryItem(itemName, amount)
						sourceXPlayer.addInventoryItem(itemName, amount)
						targetXPlayer.showNotification(_U('got_confiscated', amount, ESX.GetItem(itemName).label, sourceXPlayer.name))
						sourceXPlayer.showNotification(_U('you_confiscated', amount, ESX.GetItem(itemName).label, targetXPlayer.name))
					else
						sourceXPlayer.showNotification(_source, _U('quantity_invalid'))
					end
				else
					sourceXPlayer.showNotification(_U('quantity_invalid'))
				end
			elseif itemType == 'item_account' then
				local targetAccountMoney = targetXPlayer.getAccount(itemName).money

				if targetAccountMoney >= amount and amount > 0 then
					targetXPlayer.removeAccountMoney(itemName, amount)
					sourceXPlayer.addAccountMoney(itemName, amount)
					targetXPlayer.showNotification(_U('got_confiscated_account', amount, ESX.GetAccountLabel(itemName), sourceXPlayer.name))
					sourceXPlayer.showNotification(_U('you_confiscated_account', amount, ESX.GetAccountLabel(itemName), targetXPlayer.name))
				else
					sourceXPlayer.showNotification(_U('quantity_invalid'))
				end
			elseif itemType == 'item_weapon' then
				if targetXPlayer.hasWeapon(itemName) then
					if Config.VIPWeapons[itemName] == nil then
						targetXPlayer.removeWeapon(itemName)
						sourceXPlayer.addWeapon(itemName, amount)
						targetXPlayer.showNotification(_U('got_confiscated_weapon', ESX.GetWeaponLabel(itemName), amount, sourceXPlayer.name))
						sourceXPlayer.showNotification(_U('you_confiscated_weapon', ESX.GetWeaponLabel(itemName), targetXPlayer.name, amount))
					else
						TriggerClientEvent('esx:showNotification', xPlayer.source, '~r~Action Impossible~s~ : Vous ne pouvez pas prendre cette arme')
					end
				else
					sourceXPlayer.showNotification(_U('quantity_invalid'))
				end
			end
		end
	else
		sourceXPlayer.showNotification('La personne est trop loin')
	end
end)

RegisterServerEvent('GangsBuilder:putInVehicle')
AddEventHandler('GangsBuilder:putInVehicle', function(target)
	local xPlayerTarget = ESX.GetPlayerFromId(target)

	if xPlayerTarget ~= nil then
		local cuffState = xPlayerTarget.get('cuffState')

		if cuffState.isCuffed then
			TriggerClientEvent('GangsBuilder:putInVehicle', target)
		end
	end
end)

RegisterServerEvent('GangsBuilder:OutVehicle')
AddEventHandler('GangsBuilder:OutVehicle', function(target)
	local xPlayerTarget = ESX.GetPlayerFromId(target)

	if xPlayerTarget ~= nil then
		local cuffState = xPlayerTarget.get('cuffState')

		if cuffState.isCuffed then
			TriggerClientEvent('GangsBuilder:OutVehicle', target)
		end
	end
end)

RegisterServerEvent('GangsBuilder:getStockItem')
AddEventHandler('GangsBuilder:getStockItem', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_' .. xPlayer.job2.name, function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		if inventoryItem.count >= count and inventoryItem.count > 0 then
			if xPlayer.canCarryItem(itemName, count) then
				inventory.removeItem(itemName, count)
				xPlayer.addInventoryItem(itemName, count)
				xPlayer.showNotification(_U('have_withdrawn', count, inventoryItem.label))
			else
				xPlayer.showNotification(_U('quantity_invalid'))
			end
		else
			xPlayer.showNotification(_U('quantity_invalid'))
		end
	end)
end)

ESX.RegisterServerCallback('GangsBuilder:getStockItems', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_' .. xPlayer.job2.name, function(inventory)
		cb(inventory.items)
	end)
end)

RegisterServerEvent('GangsBuilder:putStockItems')
AddEventHandler('GangsBuilder:putStockItems', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_' .. xPlayer.job2.name, function(inventory)
                
    local item = inventory.getItem(itemName)

    if item.count >= 0 then
      xPlayer.removeInventoryItem(itemName, count)
      inventory.addItem(itemName, count)
    else
      TriggerClientEvent('esx:showNotification', xPlayer.source, _U('quantity_invalid'))
    end

    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('added') .. count .. ' ' .. item.label)
		
	end)
end)

ESX.RegisterServerCallback('GangsBuilder:getPlayerInventory', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb({items = xPlayer.inventory})
end)

ESX.RegisterServerCallback('GangsBuilder:getOtherPlayerData', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		cb({
			foundPlayer = true,
			inventory = xPlayer.inventory,
			weapons = xPlayer.loadout,
			accounts = xPlayer.accounts
		})
	else
		cb({foundPlayer = false})
	end
end)

ESX.RegisterServerCallback('GangsBuilder:getVehicleInfos', function(source, cb, plate)
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles', {}, function(result)
		local foundIdentifier = nil

		for i = 1, #result, 1 do
			local vehicleData = json.decode(result[i].vehicle)

			if vehicleData.plate == plate then
				foundIdentifier = result[i].owner
				break
			end
		end

		if foundIdentifier ~= nil then
			MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
				['@identifier'] = foundIdentifier
			}, function(result)
				local infos = {
					plate = plate,
					owner = (result[1].firstname or 'Inconnu') .. ' ' .. (result[1].lastname or 'Inconnu')
				}

				cb(infos)
			end)
		else
			local infos = {
				plate = plate
			}

			cb(infos)
		end
	end)
end)

ESX.RegisterServerCallback('GangsBuilder:getArmoryWeapons', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_' .. xPlayer.job2.name, function(store)
		local weapons = store.get('weapons') or {}
		cb(weapons)
	end)
end)

ESX.RegisterServerCallback('GangsBuilder:addArmoryWeapon', function(source, cb, weaponName, weaponAmmo)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.hasWeapon(weaponName) then
		TriggerEvent('esx_datastore:getSharedDataStore', 'society_' .. xPlayer.job2.name, function(store)
			local weapons = store.get('weapons') or {}
			weaponName = string.upper(weaponName)

			table.insert(weapons, {
				name = weaponName,
				ammo = weaponAmmo
			})

			xPlayer.removeWeapon(weaponName)
			store.set('weapons', weapons)
			cb()
		end)
	else
		xPlayer.showNotification('Vous ne possédez pas cette arme !')
		cb()
	end
end)

ESX.RegisterServerCallback('GangsBuilder:removeArmoryWeapon', function(source, cb, weaponName, weaponAmmo)
	local xPlayer = ESX.GetPlayerFromId(source)

	if not xPlayer.hasWeapon(weaponName) then
		TriggerEvent('esx_datastore:getSharedDataStore', 'society_' .. xPlayer.job2.name, function(store)
			local weapons = store.get('weapons') or {}
			weaponName = string.upper(weaponName)

			for i = 1, #weapons, 1 do
				if weapons[i].name == weaponName and weapons[i].ammo == weaponAmmo then
					table.remove(weapons, i)

					store.set('weapons', weapons)
					xPlayer.addWeapon(weaponName, weaponAmmo)
					break
				end
			end

			cb()
		end)
	else
		xPlayer.showNotification('Vous possédez déjà cette arme !')
		cb()
	end
end)

ESX.RegisterServerCallback('GangsBuilder:buyWeapon', function(source, cb, weaponName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGang = GetGang(xPlayer.job2)
	local weaponPrice = 0

	for i = 1, #plyGang.Weapons, 1 do
		if plyGang.Weapons[i].name == weaponName then
			weaponPrice = plyGang.Weapons[i].price
			break
		end
	end

	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. xPlayer.job2.name, function(account)
		if account.money >= weaponPrice then
			TriggerEvent('esx_datastore:getSharedDataStore', 'society_' .. xPlayer.job2.name, function(store)
				local weapons = store.get('weapons') or {}

				table.insert(weapons, {
					name = weaponName,
					ammo = 500
				})

				account.removeMoney(weaponPrice)
				store.set('weapons', weapons)
				TriggerClientEvent('esx:showNotification', xPlayer.source, 'Arme acheté !')
				cb(true)
			end)
		else
			TriggerClientEvent('esx:showNotification', xPlayer.source, 'Arme acheté !')
			cb(false)
		end
	end)
end)

ESX.RegisterServerCallback('GangsBuilder:isBusy', function(source, cb, type, identifier)
	if BusyList[type].serverId then
		identifier = source
	end

	local found = false

	for i = 1, #BusyList[type].identifiers, 1 do
		if identifier == BusyList[type].identifiers[i] then
			found = true
			break
		end
	end

	cb(found)
end)

ESX.RegisterServerCallback('GangsBuilder:AddBusyList', function(source, cb, type, identifier)
	if BusyList[type].serverId then
		identifier = source
	end

	local found = false

	for i = 1, #BusyList[type].identifiers, 1 do
		if identifier == BusyList[type].identifiers[i] then
			found = true
			break
		end
	end

	if not found then
		table.insert(BusyList[type].identifiers, identifier)
	end

	cb(found)
end)

ESX.RegisterServerCallback('GangsBuilder:RemoveBusyList', function(source, cb, type, identifier)
	if BusyList[type].serverId then
		identifier = source
	end

	local found = false

	for i = 1, #BusyList[type].identifiers, 1 do
		if identifier == BusyList[type].identifiers[i] then
			table.remove(BusyList[type].identifiers, i)
			found = true
			break
		end
	end

	cb(found)
end)
