-- 使用方法
local newProfiler  = import("bos.core.profiler"); --加载profiler
local profiler = newProfiler("call"); --具体分析函数调用
profiler:start();
--[[
    local viewLayout = viewLayout
    local pkgConfig = {
            UILayout = viewLayout,
            UIRES = res,
    }
    local layoutView = LayoutLoader:loadPkg(pkgConfig,self) --加入要监控的代码段，这里是测试布局文件的加载效率       
    ]]
profiler:stop();
profiler:dump_report_to_file( "profile.txt") --输出的文件命名

--注意事项：profiler分time和call类型，time主要记录运行时间，call可以记录方法调用的具体信息
--核心代码

--[[--
启动性能分析，核心是利用debug.sethook 对函数调用进行钩子
每次只能启动一个
@usage
    local new_profiler = import("bos.core.profiler")
    local profiler = new_profiler("call")
    profiler:start();
    -- do something
]]
function Profiler:start()
    if Profiler.running then
        return
    end
    -- Start the profiler. This begins by setting up internal profiler state
    Profiler.running = self

    self.caller_cache = {}
    self.callstack = {}

    self.start_time = clockNow();
    if self.variant == "time" then
    elseif self.variant == "call" then --因为垃圾回收会导致性能分析下降严重,所以先放缓垃圾回收
        self.setpause = collectgarbage("setpause");
        self.setstepmul = collectgarbage("setstepmul");
        collectgarbage("setpause", 300);
        collectgarbage("setstepmul", 5000);
        debug.sethook( profiler_hook_wrapper_by_call, "cr" )
    else
        error("Profiler method must be 'time' or 'call'.")
    end
end
--[[
    钩子函数入口
]]
function profiler_hook_wrapper_by_call(action)
    if Profiler.running == nil then
        debug.sethook( nil )
        return
    end
    Profiler.running:analysis_call_info(action)
end

--[[分析函数调用信息
@string action 函数调用类型 call return tail return
]]
function Profiler:analysis_call_info(action)

    --获取当前的调用信息，注意该函数有一定的损耗
    local caller_info = debug.getinfo(3,"Slfn")

    if caller_info == nil then
        return
    end

    local last_caller = self.callstack[1] --必须用数组维护

    if action == "call" then ---进入函数，标记堆栈
        -- Making a call...
        local this_caller = self:get_func_info_by_cache(caller_info.func,caller_info)
        this_caller.parent = last_caller --获取到上一次的信息
        this_caller.clock_start = clockNow()
        this_caller.count = this_caller.count + 1
        table.insert(self.callstack,1,this_caller) --记录调用堆栈顺序
    else
        local last_caller = table.remove(self.callstack, 1) --移除顶部堆栈，有可能连续触发return a进——>b进——>b出——>a出
        --[[
            local b = function()
            end
            local a = function()
                b()
            end
            a(); a进——>b进——>b出——>a出
        ]]
        local this_caller = self.caller_cache[caller_info.func]
        
        if action == "tail return" then --尾调用 当前栈级别中不存在调用者 使用callstack中的记录
            if last_caller then
                this_caller = self.caller_cache[last_caller.func]
            end
        end
        
        if  this_caller == nil  then
            return
        end

        this_caller.this_time = clockNow() - this_caller.clock_start --计算此次函数调用时长

        this_caller.time  = this_caller.time + this_caller.this_time --累加时长

        -- 更新父类信息
        if this_caller.parent then
            this_caller.parent.children[this_caller.func]        = (this_caller.parent.children[this_caller.func] or 0) + 1
            this_caller.parent.children_time[this_caller.func]   = (this_caller.parent.children_time[this_caller.func] or 0 ) + this_caller.this_time

            if this_caller.name == nil then --如果没有函数名称 无名函数
                this_caller.parent.unknow_child_time = this_caller.parent.unknow_child_time + this_caller.this_time
            else
                this_caller.parent.name_child_time = this_caller.parent.name_child_time + this_caller.this_time --统计有名函数调用时间
            end
        end
    end
end


--[[
    获取缓存里的函数信息
    @tparam     function    func  函数
    @tparam     table   info 函数调用信息 debug.getinfo返回的数据
    @return     table     函数信息
]]
function Profiler.get_func_info_by_cache(self,func,info)
    local ret = self.caller_cache[func]
    if ret == nil then --如果缓存没有,则创建一个入缓存
        ret = {}
        ret.func = func
        ret.count = 0 --调用次数
        ret.time = 0 --时间
        ret.unknow_child_time = 0 --没有名字的字函数调用时间
        ret.name_child_time = 0--没有名字的字函数调用时间
        ret.children = {}
        ret.children_time = {}
        if info.source and string.find(info.source, "\n") then
            info.source = "[string]"
        end
        ret.func_info = info
        self.caller_cache[func] = ret
    end
    return ret
end