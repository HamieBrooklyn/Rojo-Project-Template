--!nocheck

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LoaderDiagnostics = {}

type PredicateFn = (moduleScript: ModuleScript) -> boolean

type Failure = {
	name: string,
	fullName: string,
	error: any,
	trace: string,
}

type PhaseResult = {
	ok: { string },
	failed: { Failure },
	skipped: { string },
}

type LoadResult = {
	loaded: { [string]: any },
	duplicates: { [string]: { string } },
	requiredOk: { string },
	requiredFailed: { Failure },
}

type SpawnOptions = {
	sequential: boolean?,
	timeoutSeconds: number?,
	logMissingMethod: boolean?,
}

local function isVerbose(): boolean
	local v = ReplicatedStorage:GetAttribute("LoaderDiagnosticsVerbose")
	return v == true
end

local function failureFrom(moduleScript: ModuleScript, err: any): Failure
	return {
		name = moduleScript.Name,
		fullName = moduleScript:GetFullName(),
		error = err,
		trace = debug.traceback(tostring(err), 2),
	}
end

local function safeCall(label: string, fn: () -> (), onTimeoutSeconds: number?): (boolean, any)
	local finished = false
	local ok, result

	if onTimeoutSeconds and onTimeoutSeconds > 0 then
		task.delay(onTimeoutSeconds, function()
			if not finished then
				warn(
					("[LoaderDiagnostics] %s is still running after %.2fs (possible yield/hang)"):format(
						label,
						onTimeoutSeconds
					)
				)
			end
		end)
	end

	ok, result = xpcall(fn, function(err)
		return debug.traceback(tostring(err), 2)
	end)

	finished = true
	return ok, result
end

local function sortedKeys(map: { [string]: any }): { string }
	local keys = {}
	for k in pairs(map) do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end

function LoaderDiagnostics.LoadDescendantsSafe(
	parent: Instance,
	predicate: PredicateFn?,
	options: SpawnOptions?
): LoadResult
	local loaded: { [string]: any } = {}
	local requiredOk = {}
	local requiredFailed = {}
	local duplicates: { [string]: { string } } = {}
	local timeoutSeconds = options and options.timeoutSeconds or 10
	local verbose = isVerbose()

	for _, descendant in parent:GetDescendants() do
		if descendant:IsA("ModuleScript") then
			local moduleScript = descendant :: ModuleScript
			if predicate and not predicate(moduleScript) then
				continue
			end

			if loaded[moduleScript.Name] ~= nil then
				duplicates[moduleScript.Name] = duplicates[moduleScript.Name] or {}
				table.insert(duplicates[moduleScript.Name], moduleScript:GetFullName())
			end

			if verbose then
				-- print("[LoaderDiagnostics] requiring", moduleScript:GetFullName())
			end

			local ok, result = safeCall(("require(%s)"):format(moduleScript:GetFullName()), function()
				return require(moduleScript :: any)
			end, timeoutSeconds)

			if ok then
				loaded[moduleScript.Name] = result
				table.insert(requiredOk, moduleScript:GetFullName())
			else
				table.insert(requiredFailed, failureFrom(moduleScript, result))
			end
		end
	end

	return {
		loaded = loaded,
		duplicates = duplicates,
		requiredOk = requiredOk,
		requiredFailed = requiredFailed,
	}
end

function LoaderDiagnostics.SpawnAllSafe(
	loadedModules: { [string]: any },
	methodName: string,
	options: SpawnOptions?
): PhaseResult
	local sequential = options and options.sequential or false
	local timeoutSeconds = options and options.timeoutSeconds or nil
	local logMissingMethod = options and options.logMissingMethod or false

	local phase: PhaseResult = {
		ok = {},
		failed = {},
		skipped = {},
	}

	for _, name in ipairs(sortedKeys(loadedModules)) do
		local mod = loadedModules[name]
		local method = mod[methodName]

		if type(method) ~= "function" then
			if logMissingMethod then
				table.insert(phase.skipped, name)
			end
			continue
		end

		local function invoke()
			debug.setmemorycategory(name)
			method(mod)
		end

		if sequential then
			local ok, errOrTrace = safeCall(("%s.%s()"):format(name, methodName), invoke, timeoutSeconds)
			if ok then
				table.insert(phase.ok, name)
			else
				table.insert(phase.failed, {
					name = name,
					fullName = name,
					error = errOrTrace,
					trace = tostring(errOrTrace),
				})
			end
		else
			task.spawn(function()
				local ok, errOrTrace = safeCall(("%s.%s()"):format(name, methodName), invoke, timeoutSeconds)
				if ok then
					table.insert(phase.ok, name)
				else
					table.insert(phase.failed, {
						name = name,
						fullName = name,
						error = errOrTrace,
						trace = tostring(errOrTrace),
					})
					warn(("[LoaderDiagnostics] %s.%s failed\n%s"):format(name, methodName, tostring(errOrTrace)))
				end
			end)
		end
	end

	return phase
end

function LoaderDiagnostics.LoadAndStart(
	parent: Instance,
	predicate: PredicateFn?,
	options: SpawnOptions?
): LoadResult & { init: PhaseResult, start: PhaseResult }
	local load = LoaderDiagnostics.LoadDescendantsSafe(parent, predicate, options)

	if next(load.duplicates) ~= nil then
		for moduleName, fullNames in pairs(load.duplicates) do
			warn(
				("[LoaderDiagnostics] Duplicate ModuleScript name '%s' found. Loader will clobber by name: %s"):format(
					moduleName,
					table.concat(fullNames, ", ")
				)
			)
		end
	end

	for _, failure in ipairs(load.requiredFailed) do
		warn(("[LoaderDiagnostics] require failed: %s\n%s"):format(failure.fullName, failure.trace))
	end

	local init = LoaderDiagnostics.SpawnAllSafe(load.loaded, "Init", options)
	local start = LoaderDiagnostics.SpawnAllSafe(load.loaded, "Start", options)

	return {
		loaded = load.loaded,
		duplicates = load.duplicates,
		requiredOk = load.requiredOk,
		requiredFailed = load.requiredFailed,
		init = init,
		start = start,
	}
end

function LoaderDiagnostics.IsDiagnosticsEnabled(): boolean
	-- Studio-only by default. Can be toggled with ReplicatedStorage attribute "LoaderDiagnostics".
	local RS = game:GetService("ReplicatedStorage")
	local attr = RS:GetAttribute("LoaderDiagnostics")
	if attr == nil then
		return RunService:IsStudio()
	end
	return attr == true
end

return LoaderDiagnostics
