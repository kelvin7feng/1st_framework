local function create_class()
    local class = {}
    class.__index = class
    class.new = function(self, ...)
    self = setmetatable({}, self)
    self:_init(...)
        return self
    end

    class.on_destroy = function(self)
    end

    return class
end

local M = create_class();

-- 0.1s一帧
local SECOND_PER_FRAME = 0.1 
local FRAME_RATE = 1 / SECOND_PER_FRAME 

-- 20s之内的timer
local WHEEL_SIZE_1 = 200 
-- 20分钟
local WHEEL_SIZE_2 = 60 
-- 20小时
local WHEEL_SIZE_3 = 60 
-- 50天
local WHEEL_SIZE_4 = 60

local WHEEL_SIZE_MUL12 = WHEEL_SIZE_1*WHEEL_SIZE_2
local WHEEL_SIZE_MUL123 = WHEEL_SIZE_1*WHEEL_SIZE_2*WHEEL_SIZE_3
local WHEEL_SIZE_MUL1234 = WHEEL_SIZE_1*WHEEL_SIZE_2*WHEEL_SIZE_3*WHEEL_SIZE_4

local TIMER_COUNTER = 1

local INNER_BARRIER = false 

local function _create_wheel(scale)
    local wheel = {} 
    for i=1,scale do
        wheel[i-1] = {}
    end
    wheel.index = 0 
    wheel.bound = scale

    return wheel
end

function M:_init()
    self.v_elapse_time = 0
    -- 帧数
    self.v_current_frame_idx = 0 

    self.v_wheels = {
        _create_wheel(WHEEL_SIZE_1), 
        _create_wheel(WHEEL_SIZE_2), 
        _create_wheel(WHEEL_SIZE_3), 
        _create_wheel(WHEEL_SIZE_4)
    }

    self.v_index_slot_map = {}
end

function M:_internal_add_timer(timer)
    local expires = timer.expires
    local idx = expires - self.v_current_frame_idx
    local slot
    if idx <= 0 then
        -- 在下一次update 调用
        local wheel_idx = self.v_wheels[1].index 
        if INNER_BARRIER then 
            wheel_idx = (wheel_idx + 1) % WHEEL_SIZE_1
        end
        slot = self.v_wheels[1][wheel_idx]

    elseif idx < WHEEL_SIZE_1 then   
        slot = self.v_wheels[1][ expires % WHEEL_SIZE_1 ]
    elseif idx < WHEEL_SIZE_MUL12 then
        slot = self.v_wheels[2][ (math.floor(expires/WHEEL_SIZE_1)-1) % WHEEL_SIZE_2 ]
    elseif idx < WHEEL_SIZE_MUL123 then
        slot = self.v_wheels[3][ (math.floor(expires/WHEEL_SIZE_MUL12)-1) % WHEEL_SIZE_3 ]
    elseif idx < WHEEL_SIZE_MUL1234 then 
        slot = self.v_wheels[4][ (math.floor(expires/WHEEL_SIZE_MUL123)-1) % WHEEL_SIZE_4 ]
    else
        LOG_ERROR("too long timer", timer)
        return
    end

    slot[timer.id] = timer
    self.v_index_slot_map[timer.id] = slot
end

-- 注释，
-- callback
-- 参数
-- expires 秒， 精确到0.1
-- desc 格式: model:function 比如mark_quest:add_wait_mark_timer
function M:add_timer(desc, expires, cb, arg1, arg2, cycle)
    TIMER_COUNTER = TIMER_COUNTER + 1

    cycle = cycle or 0

    local info = {
        id = TIMER_COUNTER,
        expires = math.floor((expires+ self.v_elapse_time)*FRAME_RATE) + self.v_current_frame_idx,
        arg1 = arg1,
        arg2 = arg2,
        callback = cb,
        cycle = cycle*FRAME_RATE,
        desc = desc,
    }

    self:_internal_add_timer(info)

    return TIMER_COUNTER
end

function M:remove_timer(index)
    assert(index, "nil index found")

    local slot = self.v_index_slot_map[index]  
    if slot then
        -- remove timer
        slot[index] = nil
        self.v_index_slot_map[index] = nil
    else
        return false
    end
end

function M:cascade_timers(wheel)
    local slot = wheel[wheel.index]
    
    for _, timer in pairs(slot) do
        self:_internal_add_timer(timer)
    end
    wheel[wheel.index] = {}
    wheel.index = wheel.index + 1
end

function M:update(elapse)
    self.v_elapse_time = self.v_elapse_time + elapse

    while self.v_elapse_time > SECOND_PER_FRAME do 
        -- 0.1s一帧
        self.v_elapse_time = self.v_elapse_time - SECOND_PER_FRAME 

        local wheel = self.v_wheels[1]
        local wheel_idx = 1 
        while wheel.index >= wheel.bound do 

            wheel.index = 0 

            wheel_idx = wheel_idx + 1
            wheel = self.v_wheels[wheel_idx] 
            self:cascade_timers(wheel) 
        end
        wheel = self.v_wheels[1]

        local slot = wheel[ wheel.index ] 

        for idx, timer in pairs(slot) do

            INNER_BARRIER = true
            local result = timer.callback(timer.arg1, timer.arg2, timer.id)
            INNER_BARRIER = false

            self:remove_timer(idx)

            if timer.cycle > 0 and result then
                timer.expires = timer.expires + timer.cycle 
                self:_internal_add_timer(timer)
            end
        end
        self.v_current_frame_idx = self.v_current_frame_idx + 1
        wheel.index = wheel.index + 1
    end
end

function M:clear()
    self:_init()
end

return M
