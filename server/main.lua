
ESX = nil

ESX = exports["es_extended"]:getSharedObject()
if not ESX then
    print("DEBUG: ESX is not initialized. Please check if es_extended is running.")
else
    print("DEBUG: ESX has been successfully initialized.")
end

RegisterCommand('ck', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        TriggerClientEvent('esx:showNotification', source, 'Hráč nebyl nalezen.')
        return
    end

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

    if not args[1] then
        TriggerClientEvent('esx:showNotification', source, 'Nezadal jsi platné ID.')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('esx:showNotification', source, 'Nezadal jsi platné číslo ID.')
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', source, 'Hráč s tímto ID nebyl nalezen.')
        return
    end

    local identifier = targetPlayer.identifier

    MySQL.Async.execute('DELETE FROM owned_vehicles WHERE owner = @identifier', {
        ['@identifier'] = identifier
    }, function(rowsChanged)
        MySQL.Async.execute('DELETE FROM user_licenses WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(rowsChanged)
            MySQL.Async.execute('DELETE FROM users WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    TriggerClientEvent('esx:showNotification', source, 'Na postavu s ID ' .. targetId .. ' bylo uděleno CK.')
                    DropPlayer(targetId, 'Dostal jsi CK na postavu.')
                else
                    TriggerClientEvent('esx:showNotification', source, 'Nastala chyba při provádění CK.')
                end
            end)
        end)
    end)
end, false)
