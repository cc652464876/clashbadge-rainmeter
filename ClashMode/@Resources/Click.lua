-- Rainmeter polls HTTP; accepted clicks invoke Clash Verge mode actions.
local pressX, pressY, pressedAt
local phase, startedAt = 'idle', 0

local function trace(event)
    local path = SKIN:GetVariable('BadgeTestLog', '')
    if path == '' then return end
    local f = io.open(path, 'a')
    if not f then return end
    f:write(event, ' | ', phase, ' | ', SKIN:GetMeasure('MeasureClash'):GetStringValue(),
        ' | ', SKIN:GetMeasure('MeasureText'):GetStringValue(), ' | ',
        tostring(SKIN:GetMeter('MeterBg'):GetW()), 'x', tostring(SKIN:GetMeter('MeterBg'):GetH()), '\n')
    f:close()
end

local function paint()
    SKIN:Bang('!UpdateMeasure', 'MeasureText')
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

local function readNow()
    SKIN:Bang('!EnableMeasure', 'MeasureClash')
    SKIN:Bang('!CommandMeasure', 'MeasureClash', 'Update')
    SKIN:Bang('!UpdateMeasure', 'MeasureClash')
end

local function startPatch(mode)
    phase, startedAt = 'patching', os.time()
    SKIN:Bang('!DisableMeasure', 'MeasureClash')
    SKIN:Bang('!SetVariable', 'NextMode', mode)
    SKIN:Bang('!UpdateMeasure', 'MeasureToggle')
    SKIN:Bang('!CommandMeasure', 'MeasureToggle', 'Run')
    trace('patch-' .. mode)
end

function Initialize()
    SKIN:Bang('!SetOption', 'MeasureClash', 'FinishAction', '[!CommandMeasure MeasureClick "ModeRead()"]')
    SKIN:Bang('!SetOption', 'MeasureClash', 'OnConnectErrorAction', '[!CommandMeasure MeasureClick "ReadFailed()"]')
    SKIN:Bang('!SetOption', 'MeasureClash', 'OnRegExpErrorAction', '[!CommandMeasure MeasureClick "ReadFailed()"]')
end

function Press(x, y)
    pressX, pressY, pressedAt = nil, nil, nil
    if phase ~= 'idle' then return end
    pressX, pressY, pressedAt = tonumber(x), tonumber(y), os.time()
end

function Cancel()
    pressX, pressY, pressedAt = nil, nil, nil
end

function Release(x, y)
    local px, py, at = pressX, pressY, pressedAt
    Cancel()
    x, y = tonumber(x), tonumber(y)
    if phase ~= 'idle' or not px or not py or not x or not y then return end
    -- Allow normal hand jitter, reject a drag or a long press.
    if math.abs(x - px) > 4 or math.abs(y - py) > 4 or os.time() - at > 1 then
        trace('gesture-cancelled')
        return
    end
    phase, startedAt = 'reading', os.time()
    readNow()
    trace('click')
end

function ModeRead()
    SKIN:Bang('!SetOption', 'MeasureText', 'String', '[MeasureClash]')
    paint()
    if phase == 'reading' then
        local alternate = SKIN:GetVariable('AlternateMode', 'direct'):lower()
        if alternate ~= 'direct' and alternate ~= 'rule' and alternate ~= 'global' then alternate = 'direct' end
        local current = SKIN:GetMeasure('MeasureClash'):GetStringValue():lower()
        startPatch(current == alternate and 'global' or alternate)
    elseif phase == 'verifying' then
        phase = 'idle'
    end
    trace('mode-read')
end

function PatchFinished()
    if phase ~= 'patching' then return end
    local status = SKIN:GetMeasure('MeasureToggle'):GetStringValue():match('(OK|%w+)')
    if not status then
        SKIN:Bang('!Log', 'Clash badge: mode request failed; checking actual mode.', 'Warning')
    end
    phase, startedAt = 'verifying', os.time()
    readNow()
    trace('patch-finished-' .. (status or 'error'))
end

function ReadFailed()
    SKIN:Bang('!SetOption', 'MeasureText', 'String', 'Offline')
    paint()
    if phase == 'reading' then
        startPatch(SKIN:GetVariable('AlternateMode', 'direct') == 'rule' and 'rule' or 'direct')
    elseif phase == 'verifying' then
        phase = 'idle'
    end
    trace('read-failed')
end

function Update()
    if phase ~= 'idle' and os.time() - startedAt > 8 then
        phase = 'idle'
        SKIN:Bang('!EnableMeasure', 'MeasureClash')
        trace('request-timeout')
    end
    return 0
end

function Diagnose()
    trace('diagnostic')
end
