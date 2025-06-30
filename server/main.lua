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
        TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'Player not found.'})
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
        TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'You do not have permission to execute this command.'})
        return
    end

    if not args[1] then
        TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'You did not enter a valid ID.'})
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'You did not enter a valid ID number.'})
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'Player with this ID was not found.'})
        return
    end

    local identifier = targetPlayer.identifier

    MySQL.Async.execute('DELETE FROM owned_vehicles WHERE owner = @identifier', {
        ['@identifier'] = identifier
    }, function(rowsChanged)
        MySQL.Async.execute('DELETE FROM user_licenses WHERE owner = @identifier', {
            ['@identifier'] = identifier
        }, function(rowsChanged)
            MySQL.Async.execute('DELETE FROM users WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    TriggerClientEvent('ox_lib:notify', source, {type = 'success', description = 'A CK has been granted to the character with ID ' .. targetId .. '.'})
                    DropPlayer(targetId, 'You got a CK on a character.')
                else
                    TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'An error occurred during CK execution.'})
                end
            end)
        end)
    end)
end, false)