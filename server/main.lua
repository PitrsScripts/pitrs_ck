
ESX = nil
QBCore = nil

Config.useESX = Config.Framework == 'ESX'
Config.useQBCore = Config.Framework == 'QBCore'


if Config.useESX then
    ESX = exports["es_extended"]:getSharedObject()
    if not ESX then
        print("DEBUG: ESX is not initialized. Please check if es_extended is running.")
    else
        print("DEBUG: ESX has been successfully initialized.")
    end
elseif Config.useQBCore then
    QBCore = exports['qb-core']:GetCoreObject()
    if not QBCore then
        print("DEBUG: QBCore is not initialized. Please check if qb-core is running.")
    else
        print("DEBUG: QBCore has been successfully initialized.")
    end
else
    print("DEBUG: No framework is set in the configuration. Please check Config.Framework.")
end


RegisterCommand('ck', function(source, args, rawCommand)
    local xPlayer = nil

    if Config.useESX then
        xPlayer = ESX.GetPlayerFromId(source)
    elseif Config.useQBCore then
        xPlayer = QBCore.Functions.GetPlayer(source)
    end

    local hasPermission = false
    for _, group in ipairs(Config.allowedGroups) do
        if (Config.useESX and xPlayer.getGroup() == group) or (Config.useQBCore and xPlayer.PlayerData.job.name == group) then
            hasPermission = true
            break
        end
    end

    if not hasPermission then
        if Config.useESX then
            TriggerClientEvent('esx:showNotification', source, 'Nemáš oprávnění k provedení tohoto příkazu.')
        elseif Config.useQBCore then
            TriggerClientEvent('QBCore:Notify', source, 'Nemáš oprávnění k provedení tohoto příkazu.', 'error')
        end
        return
    end

    if not args[1] then
        if Config.useESX then
            TriggerClientEvent('esx:showNotification', source, 'Nezadal jsi platné ID.')
        elseif Config.useQBCore then
            TriggerClientEvent('QBCore:Notify', source, 'Nezadal jsi platné ID.', 'error')
        end
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        if Config.useESX then
            TriggerClientEvent('esx:showNotification', source, 'Nezadal jsi platné číslo ID.')
        elseif Config.useQBCore then
            TriggerClientEvent('QBCore:Notify', source, 'Nezadal jsi platné číslo ID.', 'error')
        end
        return
    end

    local targetPlayer = nil
    if Config.useESX then
        targetPlayer = ESX.GetPlayerFromId(targetId)
    elseif Config.useQBCore then
        targetPlayer = QBCore.Functions.GetPlayer(targetId)
    end

    if not targetPlayer then
        if Config.useESX then
            TriggerClientEvent('esx:showNotification', source, 'Hráč s tímto ID nebyl nalezen.')
        elseif Config.useQBCore then
            TriggerClientEvent('QBCore:Notify', source, 'Hráč s tímto ID nebyl nalezen.', 'error')
        end
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
                    if Config.useESX then
                        TriggerClientEvent('esx:showNotification', source, 'Na postavu s ID ' .. targetId .. ' bylo uděleno CK.')
                    elseif Config.useQBCore then
                        TriggerClientEvent('QBCore:Notify', source, 'Na postavu s ID ' .. targetId .. ' bylo uděleno CK.', 'success')
                    end
                    DropPlayer(targetId, 'Dostal jsi CK na postavu.')
                else
                    if Config.useESX then
                        TriggerClientEvent('esx:showNotification', source, 'Nastala chyba při provád ění CK.')
                    elseif Config.useQBCore then
                        TriggerClientEvent('QBCore:Notify', source, 'Nastala chyba při provádění CK.', 'error')
                    end
                end
            end)
        end)
    end)
end, false)