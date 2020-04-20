---ObserverBehavior
---观察者组件
--[[
    self:脚本实例
    object:被观察者
    observerObj:观察者
    使用要求：
    ObserverBehavior继承BehaviorBase
    object扩展BehaviorExtend，以便调用bind_method()和bind_behavior()
    在引擎中，像view这样的对象已经默认扩展了BehaviorExtend，而对于自己定义的class，则需要自己扩展
]]

local BehaviorBase = import('bos.foundation.component').BehaviorBase
local ObserverBehavior = class(BehaviorBase)
local Lib = import("bos.utils")
local TableLib = Lib.TableLib;
clone = TableLib.clone

local nilValue = "__nil__"

ObserverBehavior.className_ = "ObserverBehavior"

function ObserverBehavior:ctor() 
    self.m_observerMap = {}
    self.m_propertyMap = {}
    self.m_notifyFunc = {}
    self.m_notifyCnt = 0
    self.m_lockWrite = false
    self.m_objectMeta = nil
end

function ObserverBehavior:dtor()

end

function ObserverBehavior:initDataProxy(object) 
    local oldMt = getmetatable(object)
    local newMt = clone(oldMt)
    newMt.__index = function(t,k)
        local v = self.m_propertyMap[k]
        if v ~= nil then
            if v == nilValue then
                return nil
            else
                return v
            end
        end
        if oldMt and oldMt.__index then
            if type(oldMt.__index) == "function" then
                return oldMt.__index(t, k)
            else
                return oldMt.__index[k]
            end
        end
    end
    newMt.__newindex = function(t,k,v)
        local oldVal = self.m_propertyMap[k]
        if self.m_lockWrite == true and oldVal == nil then
            error("lock 以后不允许写入新数据"..tostring(k))
            return
        end
        self.m_propertyMap[k] = v == nil and nilValue or v
        self:__notifyDataChanged(object, k, v, oldVal)
    end

    object.dtor = object.dtor -- 修改了_index元表,需要将dtor的引用挂在object上,否则执行不进原有的dtor
    setmetatable(object, newMt)

    self.m_objectMeta = oldMt
end

function ObserverBehavior:setLockFlag(object, isLock)
    self.m_lockWrite = isLock
end

function ObserverBehavior:addObserver( object, observerObj, priorityLevel )
    if not observerObj then
        return;
    end
    if self:__getObserverItemByObj(observerObj) == nil then
        local item = { obj = observerObj; level = priorityLevel or 1; }
        local index = #self.m_observerMap + 1
        for i,v in ipairs(self.m_observerMap) do
            if v.level < item.level then
                index = i
                break
            end
        end
        table.insert(self.m_observerMap, index, item)
    end
end
--被观察者通知观察者调用func方法，...可以传递数据
function ObserverBehavior:notify( object, func, ... )
    self.m_notifyCnt = self.m_notifyCnt + 1
    for _, observer in ipairs(self.m_observerMap) do
        if not observer.isRemove then
            local obj = observer.obj;
            if obj and obj[func] then
                local isBreak = obj[func](obj, ...);
                if isBreak then
                    Log.v("ObserverBehavior.notify execute break!!!");
                    break;
                end
            end
        end
    end
    self.m_notifyCnt = self.m_notifyCnt - 1
    self:__cleanObserver()
end
--数据改变，主动触发观察者的onNotifyDataChange方法
function ObserverBehavior:__notifyDataChanged(object, k, v, oldVal)
    self.m_notifyCnt = self.m_notifyCnt + 1
    local func = self:__getDataNotifyFunc(k)
    for _, observer in ipairs(self.m_observerMap) do
        if not observer.isRemove then
            local obj = observer.obj;
            local f = obj[func] 
            local f1 = obj["onNotifyDataChange"]
            local isBreak = false
            if f then
                isBreak = f(obj, v, oldVal, object);
            elseif f1 then 
                isBreak = f1(obj, k, v, oldVal, object)
            end
            if isBreak then
                Log.v("ObserverBehavior.notify execute break!!!");
                break;
            end
        end
    end    
    self.m_notifyCnt = self.m_notifyCnt - 1
    self:__cleanObserver()
end

function ObserverBehavior:__getDataNotifyFunc(k)
    if not self.m_notifyFunc[k] then
        self.m_notifyFunc[k] = "on"..string.upper_first(k).."Change"
    end
    return self.m_notifyFunc[k]    
end

function ObserverBehavior:removeObserver( object, observerObj )
    if not observerObj then
        return;
    end
    
    local item = self:__getObserverItemByObj(observerObj);
    if item ~= nil then
        item.isRemove = true
    end

    self:__cleanObserver()
end

function ObserverBehavior:__getObserverItemByObj(observerObj)
    for _, v in ipairs(self.m_observerMap) do
        if v.obj == observerObj then
            return v;
        end
    end
end

function ObserverBehavior:__cleanObserver( ... )
    if self.m_notifyCnt == 0 then
        local i = #self.m_observerMap
        while i > 0 do
            if self.m_observerMap[i].isRemove then
                table.remove(self.m_observerMap, i)
            end
            i = i - 1
        end
    end
end

ObserverBehavior.exportInterface = {
    "addObserver",
    "notify",
    "removeObserver",
    "initDataProxy",
    "setLockFlag",
}

function ObserverBehavior:bind(object)
    for i,v in ipairs(self.exportInterface) do
        object:bind_method(self, v, function ( ... )
            self[v](self, ...);
        end);
    end
   
end

function ObserverBehavior:unbind(object)
    for i,v in ipairs(self.exportInterface) do
        object:unbind_method(self, v);
    end
    setmetatable(object, self.m_objectMeta)
end

return ObserverBehavior;