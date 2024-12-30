--!strict

local NAME = "ReplicationRemote"

type Callback = (UnreliableRemoteEvent) -> ()

local function getReplicationRemote(isServer: boolean, clientCallback: Callback, serverCallback: Callback)	
	if isServer then
		local remote = Instance.new("UnreliableRemoteEvent")
		remote.Name = NAME
		remote.Parent = script
		serverCallback(remote)
	else
		local remote = script:FindFirstChildOfClass("UnreliableRemoteEvent")
		
		if remote then
			clientCallback(remote)
		else
			script.ChildAdded:Once(function(child)
                local remote = child :: UnreliableRemoteEvent
                clientCallback(remote)
			end)
		end
	end
end

return getReplicationRemote