ESX = exports["es_extended"]:getSharedObject() -- NEW UPDATE ESX 1.10.7 Tutoriel = https://documentation.esx-framework.org/tutorials/tutorials-esx/sharedevent

GangsData = {}

Citizen.CreateThread(function()
	GangsData = GetGangs()

	for i = 1, #GangsData, 1 do
		TriggerEvent('esx_society:registerSociety', GangsData[i].Name, GangsData[i].Label, 'society_' .. GangsData[i].Name, 'society_' .. GangsData[i].Name, 'society_' .. GangsData[i].Name, {type = 'public'})
	end
end)

function GetGangs()
	local data = LoadResourceFile('GangsBuilder', 'data/gangData.json')
	return data and json.decode(data) or {}
end

function GetGang(job2)
	for i = 1, #GangsData, 1 do
		if job2.name == GangsData[i].Name then
			return GangsData[i]
		end
	end

	return false
end

RegisterServerEvent('GangsBuilder:addGang')
AddEventHandler('GangsBuilder:addGang', function(data)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == '_dev' then
		if not GetGang(data.Name) then
			MySQL.Async.execute([[
INSERT INTO `addon_account` (name, label, shared) VALUES (@gangSociety, @gangLabel, 1);
INSERT INTO `datastore` (name, label, shared) VALUES (@gangSociety, @gangLabel, 1);
INSERT INTO `addon_inventory` (name, label, shared) VALUES (@gangSociety, @gangLabel, 1);
INSERT INTO `jobs` (`name`, `label`, `whitelisted`) VALUES (@gangName, @gangLabel, 1);
INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
	(@gangName, 0, 'rookie', 'Associé', 0, '{}', '{}'),
	(@gangName, 1, 'member', 'Soldat', 0, '{}', '{}'),
	(@gangName, 2, 'elite', 'Elite', 0, '{}', '{}'),
	(@gangName, 3, 'lieutenant', 'Lieutenant', 0, '{}', '{}'),
	(@gangName, 4, 'viceboss', 'Bras Droit', 0, '{}', '{}'),
	(@gangName, 5, 'boss', 'Patron', 0, '{}', '{}')
;
			]], {
				['@gangName'] = data.Name,
				['@gangLabel'] = data.Label,
				['@gangSociety'] = 'society_' .. data.Name
			}, function(rowsChanged)
				table.insert(GangsData, data)
				SaveResourceFile('GangsBuilder', 'data/gangData.json', json.encode(GangsData))
				TriggerClientEvent('esx:showNotification', xPlayer.source, 'Gang créé ! (Disponible au prochain reboot)')
			end)
		else
			TriggerClientEvent('esx:showNotification', xPlayer.source, 'Le Job existe déjà sombre fdp')
		end
	end
end)

RegisterServerEvent('GangsBuilder:requestSync')
AddEventHandler('GangsBuilder:requestSync', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGang = GetGang(xPlayer.job2)
	TriggerClientEvent('GangsBuilder:SyncGang', xPlayer.source, plyGang)
end)

AddEventHandler('esx:playerLoaded', function(source, xPlayer)
	local plyGang = GetGang(xPlayer.job2)
	TriggerClientEvent('GangsBuilder:SyncGang', source, plyGang)
end)

AddEventHandler('esx:setJob2', function(source, job2)
	local plyGang = GetGang(job2)
	TriggerClientEvent('GangsBuilder:SyncGang', source, plyGang)
end)

TriggerEvent('es:addGroupCommand', 'gangsbuilder', 'superadmin', function(source)
	TriggerClientEvent('GangsBuilder:OpenMenu', source)
end, {help = ''})
