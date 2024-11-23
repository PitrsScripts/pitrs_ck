ESX = nil
Config = Config or {} 

ESX = exports["es_extended"]:getSharedObject()

RegisterCommand('ck', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

 
    local hasPermission = false
    for _, group in ipairs(Config.allowedGroups) do
        if xPlayer.getGroup() == group then
            hasPermission = true
            break
        end
    end


    if not hasPermission then
        TriggerClientEvent('esx:showNotification', source, 'Nemáš oprávnění k provedení tohoto příkazu.')
        return  
    end

    if xPlayer then
        local identifier = xPlayer.identifier

        
        MySQL.Async.execute('DELETE FROM owned_vehicles WHERE owner = @identifier', {
            ['@identifier'] = identifier
        }, function(rowsChanged)
            MySQL.Async.execute('DELETE FROM users WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    TriggerClientEvent('esx:showNotification', source, 'Na tvou postavu bylo uděleno CK.')
                    DropPlayer(source, 'Byl jsi vyhozen ze hry. Na tvou postavu bylo uděleno CK.')

                else
                    TriggerClientEvent('esx:showNotification', source, 'Chyba: Uživatel nebyl nalezen.')
                end
            end)
        end)
    end
end, false)

