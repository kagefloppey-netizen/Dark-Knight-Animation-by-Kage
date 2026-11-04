--[[// Dark Knight - Ultimate Power Remastered (Chaos Lightning Enhanced)
Script by MrGluckingBall/Joe/R_MP6/Kage
Credits: Animation made by KageFloppey
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local anims = {
	idle = "rbxassetid://140073674074104",      
	walk = "rbxassetid://118959209918644",      
	run  = "rbxassetid://90220723448748",       
	taunt = "rbxassetid://74430100028293",
	ninja_idle = "rbxassetid://140073674074104", 
	ninja_walk = "rbxassetid://118959209918644", 
	ninja_run  = "rbxassetid://90220723448748"   
}

local scriptActivated = false 
local isRunMode = false      
local isTaunting = false     
local isTeleporting = false 
local isTimeFrozen = false   
local isCloaked = false -- Biến trạng thái Shadow Cloak bổ sung

local idleTrack, walkTrack, runTrack, tauntTrack
local runningConnection, speedEnforcer, vfxHeartbeat, deathConnection
local inputConnection = nil
local refreshAnimsConnection = nil

local dragonHeadPart = nil
local dragonHeadAura = nil
local darkSmokeTrail = nil
local eyeGlowL, eyeGlowR = nil, nil
local colorCorrection = nil
local timeStopInvert = nil
local lightningFloorAura = nil 
local lastCraterTime = 0
local frozenPlayersStates = {}
local originalTransparencies = {} -- Lưu độ trong suốt gốc khi tàng hình

local function cleanupVFX()
	if dragonHeadPart then dragonHeadPart:Destroy(); dragonHeadPart = nil end
	if dragonHeadAura then dragonHeadAura:Destroy(); dragonHeadAura = nil end
	if darkSmokeTrail then darkSmokeTrail:Destroy(); darkSmokeTrail = nil end
	if eyeGlowL then eyeGlowL:Destroy(); eyeGlowL = nil end
	if eyeGlowR then eyeGlowR:Destroy(); eyeGlowR = nil end
	if colorCorrection then colorCorrection:Destroy(); colorCorrection = nil end
	if timeStopInvert then timeStopInvert:Destroy(); timeStopInvert = nil end
	if lightningFloorAura then lightningFloorAura:Destroy(); lightningFloorAura = nil end
end

local function cleanupTracks()
	cleanupVFX()
	if idleTrack then idleTrack:Stop(); idleTrack:Destroy(); idleTrack = nil end
	if walkTrack then walkTrack:Stop(); walkTrack:Destroy(); walkTrack = nil end
	if runTrack then runTrack:Stop(); runTrack:Destroy(); runTrack = nil end
	if tauntTrack then tauntTrack:Stop(); tauntTrack:Destroy(); tauntTrack = nil end
	if runningConnection then runningConnection:Disconnect(); runningConnection = nil end
	if speedEnforcer then speedEnforcer:Disconnect(); speedEnforcer = nil end
	if vfxHeartbeat then vfxHeartbeat:Disconnect(); vfxHeartbeat = nil end
	if refreshAnimsConnection then refreshAnimsConnection:Disconnect(); refreshAnimsConnection = nil end
end

local function playSoundEffect(id, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(id)
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = player.Character or workspace
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

local function createLightningWave(position, color)
	local wave = Instance.new("Part")
	wave.Shape = Enum.PartType.Ball
	wave.Material = Enum.Material.Neon
	wave.Color = color
	wave.Size = Vector3.new(2, 2, 2)
	wave.CFrame = position
	wave.Anchored = true
	wave.CanCollide = false
	wave.Parent = workspace
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxassetid://281983280" 
	pe.Color = ColorSequence.new(color, Color3.fromRGB(0,0,0))
	pe.Size = NumberSequence.new(5, 0)
	pe.Lifetime = NumberRange.new(0.2, 0.4)
	pe.Rate = 150
	pe.Speed = NumberRange.new(15, 40)
	pe.Parent = wave
	TweenService:Create(wave, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(35, 35, 35), Transparency = 1}):Play()
	task.delay(0.2, function() pe.Enabled = false end)
	task.delay(0.5, function() wave:Destroy() end)
end

local function createAfterimage(character, duration, customColor)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
			local clone = child:Clone()
			clone.Anchored = true
			clone.CanCollide = false
			clone.Material = Enum.Material.ForceField 
			clone.Color = customColor or Color3.fromRGB(15, 15, 15) 
			clone.CFrame = child.CFrame
			clone.Parent = workspace
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxassetid://281983280"
			pe.Color = ColorSequence.new(clone.Color) 
			pe.Size = NumberSequence.new(2, 0)
			pe.Lifetime = NumberRange.new(0.2)
			pe.Rate = 20
			pe.Parent = clone
			local tween = TweenService:Create(clone, TweenInfo.new(duration or 0.4), {Transparency = 1})
			tween:Play()
			tween.Completed:Connect(function() clone:Destroy() end)
		end
	end
end

local function strikeEnvironmentLightning(position)
	for i = 1, 5 do
		local startPos = position + Vector3.new(math.random(-20, 20), math.random(30, 50), math.random(-20, 20))
		local endPos = position + Vector3.new(math.random(-8, 8), -2, math.random(-8, 8))
		local bolt = Instance.new("Part")
		bolt.Material = Enum.Material.Neon
		bolt.Color = (math.random(1, 2) == 1) and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(230, 0, 0)
		bolt.Transparency = 0.1
		bolt.CanCollide = false
		bolt.Anchored = true
		local distance = (startPos - endPos).Magnitude
		bolt.Size = Vector3.new(0.6, 0.6, distance)
		bolt.CFrame = CFrame.new(startPos:Lerp(endPos, 0.5), endPos)
		bolt.Parent = workspace
		TweenService:Create(bolt, TweenInfo.new(0.2), {Size = Vector3.new(0, 0, distance), Transparency = 1}):Play()
		task.delay(0.2, function() bolt:Destroy() end)
	end
end

local function createGroundFracture(position)
	task.spawn(function()
		local partsCount = math.random(3, 5)
		for i = 1, partsCount do
			local p = Instance.new("Part")
			p.Size = Vector3.new(math.random(2, 4), 0.3, math.random(2, 4))
			p.Material = Enum.Material.Neon
			p.Color = (math.random(1, 2) == 1) and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(180, 0, 0)
			p.CFrame = CFrame.new(position + Vector3.new(math.random(-3, 3), -2.4, math.random(-3, 3))) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
			p.Anchored = true
			p.CanCollide = false
			p.Parent = workspace
			TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = p.Position + Vector3.new(0, 0.2, 0)}):Play()
			task.delay(0.6, function()
				local t = TweenService:Create(p, TweenInfo.new(0.4), {Position = p.Position - Vector3.new(0, 3, 0), Transparency = 1})
				t:Play()
				t.Completed:Connect(function() p:Destroy() end)
			end)
		end
	end)
end

local function spawnAmbientLightning(corePart)
	if not corePart then return end
	local startOffset = Vector3.new(math.random(-4, 4), math.random(-2, 5), math.random(-4, 4))
	local endOffset = Vector3.new(math.random(-4, 4), math.random(-3, 4), math.random(-4, 4))
	local startPos = corePart.Position + startOffset
	local endPos = corePart.Position + endOffset
	local distance = (startPos - endPos).Magnitude
	if distance < 1 then return end
	local lightningBolt = Instance.new("Part")
	lightningBolt.Material = Enum.Material.Neon
	lightningBolt.Color = (math.random(1, 2) == 1) and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(220, 0, 0)
	lightningBolt.Transparency = 0.2
	lightningBolt.CanCollide = false
	lightningBolt.Anchored = true
	local thickness = isTimeFrozen and (math.random(2, 5) / 10) or (math.random(1, 3) / 10)
	lightningBolt.Size = Vector3.new(thickness, thickness, distance)
	lightningBolt.CFrame = CFrame.new(startPos:Lerp(endPos, 0.5), endPos)
	lightningBolt.Parent = workspace
	local tween = TweenService:Create(lightningBolt, TweenInfo.new(0.1), {Size = Vector3.new(0, 0, distance), Transparency = 1})
	tween:Play()
	tween.Completed:Connect(function() lightningBolt:Destroy() end)
end

-- HÀM BỔ SUNG: Kích hoạt/Hủy kích hoạt kĩ năng Shadow Cloak
local function toggleShadowCloak()
	if not scriptActivated then return end
	local character = player.Character if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	isCloaked = not isCloaked
	
	if isCloaked then
		playSoundEffect(9114223124, 2, 0.85) -- Âm thanh kích hoạt bóng tối mờ ảo
		createLightningWave(character:GetPivot(), Color3.fromRGB(5, 5, 5))
		
		-- Ẩn nhân vật (Lưu lại độ trong suốt cũ để hồi phục sau)
		table.clear(originalTransparencies)
		for _, child in ipairs(character:GetDescendants()) do
			if child:IsA("BasePart") or child:IsA("Decal") then
				originalTransparencies[child] = child.Transparency
				TweenService:Create(child, TweenInfo.new(0.3), {Transparency = 1}):Play()
			end
		end
		
		if humanoid then humanoid.WalkSpeed = 50 end -- Ép tốc độ 50 khi tàng hình
		
		-- Tự động hủy sau 5 giây nếu không chủ động hành động trước
		task.delay(5, function()
			if isCloaked and player.Character == character then
				toggleShadowCloak()
			end
		end)
	else
		playSoundEffect(9114223124, 1.5, 1.2)
		-- Hiện lại nhân vật về trạng thái ban đầu
		for child, trans in pairs(originalTransparencies) do
			if child and child.Parent then
				TweenService:Create(child, TweenInfo.new(0.3), {Transparency = trans}):Play()
			end
		end
		table.clear(originalTransparencies)
		
		if humanoid then 
			if isTimeFrozen then humanoid.WalkSpeed = 35 
			else humanoid.WalkSpeed = isRunMode and 28 or 14 end
		end
	end
end

local function applySystem(character)
	if not scriptActivated then return end 
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")
	local hrp = character:WaitForChild("HumanoidRootPart")
	local head = character:WaitForChild("Head")

	cleanupTracks()
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0.1) end

	local function loadAnims()
		if idleTrack then idleTrack:Stop(); idleTrack:Destroy() end
		if walkTrack then walkTrack:Stop(); walkTrack:Destroy() end
		if runTrack then runTrack:Stop(); runTrack:Destroy() end
		if tauntTrack then tauntTrack:Stop(); tauntTrack:Destroy() end

		local id_idle = isTimeFrozen and anims.ninja_idle or anims.idle
		local id_walk = isTimeFrozen and anims.ninja_walk or anims.walk
		local id_run  = isTimeFrozen and anims.ninja_run or anims.run

		local idleAnim = Instance.new("Animation") idleAnim.AnimationId = id_idle
		idleTrack = animator:LoadAnimation(idleAnim); idleTrack.Looped = true; idleTrack.Priority = Enum.AnimationPriority.Idle
		local walkAnim = Instance.new("Animation") walkAnim.AnimationId = id_walk
		walkTrack = animator:LoadAnimation(walkAnim); walkTrack.Looped = true; walkTrack.Priority = Enum.AnimationPriority.Movement
		local runAnim = Instance.new("Animation") runAnim.AnimationId = id_run
		runTrack = animator:LoadAnimation(runAnim); runTrack.Looped = true; runTrack.Priority = Enum.AnimationPriority.Movement
		local tauntAnim = Instance.new("Animation") tauntAnim.AnimationId = anims.taunt
		tauntTrack = animator:LoadAnimation(tauntAnim); tauntTrack.Looped = true; tauntTrack.Priority = Enum.AnimationPriority.Action
		
		walkTrack:Stop(0); runTrack:Stop(0); idleTrack:Stop(0)
		if humanoid.MoveDirection.Magnitude > 0 then
			if isRunMode or isTimeFrozen then runTrack:Play(0.1) else walkTrack:Play(0.1) end
		else
			if not isTaunting then idleTrack:Play(0.1) else tauntTrack:Play(0.1) end
		end
	end

	loadAnims()

	dragonHeadPart = Instance.new("Part")
	dragonHeadPart.Size = Vector3.new(0.5, 0.5, 0.8)
	dragonHeadPart.Material = Enum.Material.ForceField
	dragonHeadPart.Color = Color3.fromRGB(5, 5, 5)
	dragonHeadPart.CanCollide = false
	dragonHeadPart.Anchored = true
	dragonHeadPart.Parent = workspace
	
	dragonHeadAura = Instance.new("ParticleEmitter")
	dragonHeadAura.Texture = "rbxassetid://244221448"
	dragonHeadAura.Color = ColorSequence.new(Color3.fromRGB(10, 10, 10), Color3.fromRGB(30, 0, 0))
	dragonHeadAura.Size = NumberSequence.new(1, 0)
	dragonHeadAura.Lifetime = NumberRange.new(0.3)
	dragonHeadAura.Rate = 45
	dragonHeadAura.Speed = NumberRange.new(0)
	dragonHeadAura.Parent = dragonHeadPart

	darkSmokeTrail = Instance.new("ParticleEmitter")
	darkSmokeTrail.Texture = "rbxassetid://244221448"
	darkSmokeTrail.Color = ColorSequence.new(Color3.fromRGB(15, 15, 15), Color3.fromRGB(40, 0, 0))
	darkSmokeTrail.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3.5), NumberSequenceKeypoint.new(1, 0.5)})
	darkSmokeTrail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	darkSmokeTrail.Lifetime = NumberRange.new(0.6, 0.9)
	darkSmokeTrail.Rate = 0
	darkSmokeTrail.Speed = NumberRange.new(1, 3)
	darkSmokeTrail.VelocityInheritance = -0.5 
	darkSmokeTrail.LockedToPart = false
	darkSmokeTrail.Parent = hrp

	local attachmentFloor = Instance.new("Attachment")
	attachmentFloor.Position = Vector3.new(0, -2.5, 0)
	attachmentFloor.Parent = hrp
	lightningFloorAura = Instance.new("ParticleEmitter")
	lightningFloorAura.Texture = "rbxassetid://281983280" 
	lightningFloorAura.Color = ColorSequence.new(Color3.fromRGB(20, 0, 0), Color3.fromRGB(0, 0, 0))
	lightningFloorAura.Size = NumberSequence.new(3, 1)
	lightningFloorAura.Lifetime = NumberRange.new(0.3, 0.5)
	lightningFloorAura.Rate = 30
	lightningFloorAura.Speed = NumberRange.new(0)
	lightningFloorAura.Parent = attachmentFloor

	local function createEye(offset)
		local a = Instance.new("Attachment") a.Position = offset a.Parent = head
		local pe = Instance.new("ParticleEmitter") pe.Texture = "rbxassetid://244221448" pe.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0)) pe.Size = NumberSequence.new(0.4, 0) pe.Lifetime = NumberRange.new(0.2) pe.Rate = 0 pe.LightEmission = 1 pe.Parent = a
		return pe
	end
	eyeGlowL = createEye(Vector3.new(-0.25, 0.2, -0.55))
	eyeGlowR = createEye(Vector3.new(0.25, 0.2, -0.55))

	local function getTargetSpeed() 
		if isTimeFrozen then return 35 end
		if isCloaked then return 50 end 
		return isRunMode and 28 or 14 
	end
	
	humanoid.WalkSpeed = getTargetSpeed()
	speedEnforcer = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		local target = getTargetSpeed()
		if humanoid.WalkSpeed ~= target then humanoid.WalkSpeed = target end
	end)

	runningConnection = humanoid.Running:Connect(function(currentSpeed)
		if currentSpeed > 0.5 then
			if isTaunting then isTaunting = false; if tauntTrack then tauntTrack:Stop(0.2) end end
			if idleTrack.IsPlaying then idleTrack:Stop(0.1) end
			if isRunMode or isTimeFrozen then
				if walkTrack.IsPlaying then walkTrack:Stop(0.1) end; if not runTrack.IsPlaying then runTrack:Play(0.1) end
			else
				if runTrack.IsPlaying then runTrack:Stop(0.1) end; if not walkTrack.IsPlaying then walkTrack:Play(0.1) end
			end
		else
			if walkTrack.IsPlaying then walkTrack:Stop(0.1) end; if runTrack.IsPlaying then runTrack:Stop(0.1) end
			if not isTaunting and not idleTrack.IsPlaying then idleTrack:Play(0.1) end
		end
	end)

	local angle = 0
	local lightningTick = 0
	vfxHeartbeat = RunService.Heartbeat:Connect(function()
		if not hrp or not hrp.Parent then return end
		local isMoving = humanoid.MoveDirection.Magnitude > 0
		lightningTick = lightningTick + 1
		local spawnRate = (isTimeFrozen and 1) or (isRunMode and 2) or 4
		if lightningTick % spawnRate == 0 then spawnAmbientLightning(hrp) end
		if isTimeFrozen and isMoving then
			local currentTime = os.clock()
			if currentTime - lastCraterTime > 0.12 then lastCraterTime = currentTime; createGroundFracture(hrp.Position) end
		end
		if not isMoving then
			angle = angle + 0.09
			local radius = 2.5
			local height = math.sin(angle * 2) * 0.4
			local headPos = head.Position
			local dragonOffset = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
			dragonHeadPart.Transparency = (isTimeFrozen or isCloaked) and 1 or 0.3 
			dragonHeadAura.Enabled = not isTimeFrozen and not isCloaked
			if not isTimeFrozen and not isCloaked then dragonHeadPart.CFrame = CFrame.new(headPos + dragonOffset, headPos) end
			darkSmokeTrail.Rate = isTimeFrozen and 90 or (isCloaked and 150 or 12) 
			lightningFloorAura.Rate = isTimeFrozen and 70 or 25
			eyeGlowL.Rate = isTimeFrozen and 30 or 0; eyeGlowR.Rate = isTimeFrozen and 30 or 0
		else
			dragonHeadPart.Transparency = 1; dragonHeadAura.Enabled = false
			if isTimeFrozen then
				darkSmokeTrail.Rate = 220; lightningFloorAura.Rate = 140; eyeGlowL.Rate = 45; eyeGlowR.Rate = 45
			elseif isRunMode then
				darkSmokeTrail.Rate = isCloaked and 250 or 130; lightningFloorAura.Rate = 85; eyeGlowL.Rate = isCloaked and 10 or 25; eyeGlowR.Rate = isCloaked and 10 or 25 
			else
				darkSmokeTrail.Rate = isCloaked and 180 or 45; lightningFloorAura.Rate = 40; eyeGlowL.Rate = 0; eyeGlowR.Rate = 0
			end
		end
	end)

	script:SetAttribute("RefreshAnimsSignal", false)
	refreshAnimsConnection = script:GetAttributeChangedSignal("RefreshAnimsSignal"):Connect(function()
		loadAnims()
	end)

	deathConnection = humanoid.Died:Connect(function()
		scriptActivated = false; isTimeFrozen = false; isRunMode = false; isTaunting = false; isCloaked = false
		cleanupTracks()
		if deathConnection then deathConnection:Disconnect(); deathConnection = nil end
		if inputConnection then inputConnection:Disconnect(); inputConnection = nil end
		if refreshAnimsConnection then refreshAnimsConnection:Disconnect(); refreshAnimsConnection = nil end
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui and playerGui:FindFirstChild("JesterSkillGui") then playerGui.JesterSkillGui:Destroy() end
		if playerGui and playerGui:FindFirstChild("JesterIntroGui") then playerGui.JesterIntroGui:Destroy() end
	end)
end

local function toggleRunMode()
	if not scriptActivated or isTimeFrozen then return end
	isRunMode = not isRunMode
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then 
			if isCloaked then humanoid.WalkSpeed = 50
			else humanoid.WalkSpeed = isRunMode and 28 or 14 end
		end
	end
end

local function toggleTaunt()
	if not scriptActivated or not tauntTrack or isTimeFrozen then return end
	if isCloaked then toggleShadowCloak() end 
	isTaunting = not isTaunting
	if isTaunting then
		if walkTrack then walkTrack:Stop(0.1) end; if runTrack then runTrack:Stop(0.1) end; if idleTrack then idleTrack:Stop(0.1) end
		tauntTrack:Play(0.2)
	else
		tauntTrack:Stop(0.2)
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and idleTrack and humanoid.MoveDirection.Magnitude <= 0 then idleTrack:Play(0.2) end
		end
	end
end

local function castLightningTeleport()
	if not scriptActivated or isTeleporting then return end
	if isCloaked then toggleShadowCloak() end 
	local character = player.Character if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	isTeleporting = true
	local moveDirection = humanoid.MoveDirection
	if moveDirection.Magnitude == 0 then moveDirection = hrp.CFrame.LookVector end

	local distance = 35 
	local startPos = hrp.Position
	local targetPos = startPos + (moveDirection * distance)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}
	local raycastResult = workspace:Raycast(startPos, moveDirection * distance, raycastParams)
	if raycastResult then targetPos = raycastResult.Position - (moveDirection * 2) end

	playSoundEffect(2691882879, 3, 0.95) 
	createLightningWave(hrp.CFrame, Color3.fromRGB(10, 10, 10)) 
	strikeEnvironmentLightning(startPos)
	createAfterimage(character, 0.6, Color3.fromRGB(0, 0, 0)) 

	if not colorCorrection then colorCorrection = Instance.new("ColorCorrectionEffect") colorCorrection.Parent = Lighting end
	colorCorrection.Brightness = 0.5; colorCorrection.TintColor = Color3.fromRGB(255, 130, 130)
	TweenService:Create(colorCorrection, TweenInfo.new(0.25), {Brightness = 0, TintColor = Color3.fromRGB(255, 255, 255)}):Play()

	hrp.CFrame = CFrame.new(targetPos, targetPos + moveDirection)

	for i = 1, 4 do
		task.wait(0.015)
		local intermediatePos = startPos:Lerp(targetPos, i / 5)
		local beam = Instance.new("Part")
		beam.Material = Enum.Material.Neon
		beam.Color = (i % 2 == 0) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(180, 0, 0)
		beam.Size = Vector3.new(2, 2, (startPos - targetPos).Magnitude / 2.5)
		beam.CFrame = CFrame.new(intermediatePos, targetPos) * CFrame.Angles(0, 0, math.rad(math.random(-45, 45)))
		beam.CanCollide = false; beam.Anchored = true; beam.Parent = workspace
		TweenService:Create(beam, TweenInfo.new(0.2), {Size = Vector3.new(0, 0, beam.Size.Z), Transparency = 1}):Play()
		task.delay(0.2, function() beam:Destroy() end)
	end

	playSoundEffect(1141703415, 2.5, 1.1)
	createLightningWave(hrp.CFrame, Color3.fromRGB(180, 0, 0)) 
	strikeEnvironmentLightning(hrp.Position) 
	createAfterimage(character, 0.4, Color3.fromRGB(160, 0, 0))
	isTeleporting = false
end

local function toggleTimeFreeze()
	if not scriptActivated then return end
	isTimeFrozen = not isTimeFrozen
	local character = player.Character if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if isTimeFrozen then
		if isCloaked then toggleShadowCloak() end 
		playSoundEffect(6165942204, 2.5, 1) 
		if not timeStopInvert then timeStopInvert = Instance.new("ColorCorrectionEffect") timeStopInvert.Parent = Lighting end
		timeStopInvert.Contrast = -2; timeStopInvert.Saturation = -1
		table.clear(frozenPlayersStates)
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character then
				local oHumanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
				if oHumanoid then
					local oAnimator = oHumanoid:FindFirstChildOfClass("Animator")
					if oAnimator then for _, track in ipairs(oAnimator:GetPlayingAnimationTracks()) do track:AdjustSpeed(0) end end
				end
				for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") and not part.Anchored then frozenPlayersStates[part] = true; part.Anchored = true end
				end
			end
		end
		if humanoid then humanoid.WalkSpeed = 35 end
		script:SetAttribute("RefreshAnimsSignal", not script:GetAttribute("RefreshAnimsSignal"))
	else
		playSoundEffect(6165942431, 2.5, 1) 
		if timeStopInvert then timeStopInvert:Destroy(); timeStopInvert = nil end
		for part, _ in pairs(frozenPlayersStates) do if part and part.Parent then part.Anchored = false end end
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character then
				local oHumanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
				if oHumanoid then
					local oAnimator = oHumanoid:FindFirstChildOfClass("Animator")
					if oAnimator then for _, track in ipairs(oAnimator:GetPlayingAnimationTracks()) do track:AdjustSpeed(1) end end
				end
			end
		end
		table.clear(frozenPlayersStates)
		if humanoid then humanoid.WalkSpeed = isRunMode and 28 or 14 end
		script:SetAttribute("RefreshAnimsSignal", not script:GetAttribute("RefreshAnimsSignal"))
	end
end

-- Hàm tạo nút chiêu thức: Đã bóp nhỏ lại (Size Y từ 45 xuống 36)
local function createButton(name, position, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 115, 0, 36)
	button.Position = position
	button.Text = name:upper()
	button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 10
	local uicorner = Instance.new("UICorner") uicorner.CornerRadius = UDim.new(0, 5) uicorner.Parent = button
	local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(80, 80, 80) stroke.Thickness = 1.2 stroke.Parent = button
	button.MouseButton1Click:Connect(callback)
	return button
end

-- Hiển thị cụm chiêu thức chính: Đẩy vị trí lên trên (0.2 dịch lên thành 0.12) và thu hẹp khoảng cách
local function showMainSkillGui(playerGui)
	if playerGui:FindFirstChild("JesterSkillGui") then playerGui.JesterSkillGui:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JesterSkillGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	createButton("Run", UDim2.new(1, -135, 0.12, 0), toggleRunMode).Parent = screenGui
	createButton("Taunt (L)", UDim2.new(1, -135, 0.12, 42), toggleTaunt).Parent = screenGui
	createButton("Time Freeze (G)", UDim2.new(1, -135, 0.12, 84), toggleTimeFreeze).Parent = screenGui
	createButton("Shadow Cloak (V)", UDim2.new(1, -135, 0.12, 126), toggleShadowCloak).Parent = screenGui 
	
	if inputConnection then inputConnection:Disconnect() end
	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.L then toggleTaunt()
		elseif input.KeyCode == Enum.KeyCode.F then castLightningTeleport()
		elseif input.KeyCode == Enum.KeyCode.G then toggleTimeFreeze()
		elseif input.KeyCode == Enum.KeyCode.V then toggleShadowCloak() end 
	end)

	if player.Character then applySystem(player.Character) end
end

-- Khởi tạo Intro GUI: Thêm hiệu ứng cầu vồng chuyển động (Rainbow RGB Loop)
local function initializeIntroGUI()
	local playerGui = player:WaitForChild("PlayerGui")
	
	if playerGui:FindFirstChild("JesterIntroGui") then playerGui.JesterIntroGui:Destroy() end
	if playerGui:FindFirstChild("JesterSkillGui") then playerGui.JesterSkillGui:Destroy() end

	local introGui = Instance.new("ScreenGui")
	introGui.Name = "JesterIntroGui"
	introGui.ResetOnSpawn = false
	introGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 340, 0, 160)
	frame.Position = UDim2.new(0.5, -170, 0.5, -80)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	frame.Parent = introGui 

	local frameCorner = Instance.new("UICorner") frameCorner.CornerRadius = UDim.new(0, 8) frameCorner.Parent = frame
	local frameStroke = Instance.new("UIStroke") frameStroke.Thickness = 2.5 frameStroke.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 0.5, 0)
	textLabel.Position = UDim2.new(0, 0, 0.1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "Dark Knight Animation made by KageFloppey"
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 15
	textLabel.TextWrapped = true
	textLabel.Parent = frame

	-- Vòng lặp tạo màu cầu vồng chuyển động thời gian thực cho chữ và viền
	local rainbowConnection
	rainbowConnection = RunService.RenderStepped:Connect(function()
		if not frame or not frame.Parent then 
			rainbowConnection:Disconnect()
			return 
		end
		local hue = (tick() % 4) / 4 -- Chu kỳ đổi màu mượt mỗi 4 giây
		local color = Color3.fromHSV(hue, 0.9, 1)
		frameStroke.Color = color
		textLabel.TextColor3 = color
	end)

	local startBtn = Instance.new("TextButton")
	startBtn.Size = UDim2.new(0, 140, 0, 38)
	startBtn.Position = UDim2.new(0.5, -70, 0.6, 10)
	startBtn.Text = "START"
	startBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	startBtn.Font = Enum.Font.GothamBold
	startBtn.TextSize = 13
	startBtn.Parent = frame

	local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 6) btnCorner.Parent = startBtn
	local btnStroke = Instance.new("UIStroke") btnStroke.Color = Color3.fromRGB(80, 80, 80) btnStroke.Thickness = 1.2 btnStroke.Parent = startBtn

	startBtn.MouseButton1Click:Connect(function()
		scriptActivated = true 
		if rainbowConnection then rainbowConnection:Disconnect() end
		introGui:Destroy()      
		showMainSkillGui(playerGui) 
	end)
end

initializeIntroGUI()

player.CharacterAdded:Connect(function(character)
	if scriptActivated then
		isRunMode = false; isTaunting = false; isTeleporting = false; isTimeFrozen = false; isCloaked = false
		cleanupVFX()
		applySystem(character)
	end
end)
