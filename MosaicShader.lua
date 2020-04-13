--[[--ldoc desc
@fileType 马赛克Shader
]]
--注：=====================================================================
--texture0   默认内置变量，纹理采样器
--color      默认内置变量，默认值为vec4(1.0,1.0,1.0,1.0)
--projection 默认内置变量，投影
--modelview  默认内置变量，视图
--objectSize 默认内置变量，控件的宽高

-- 这块是最重要的 默认内置变量

-- 在fs --> main函数内可以直接获取 uniforms 内设置的字段
-- 无需重新声明 且初始值为 uniforms 内所设置的值
-- 注：=====================================================================
local Shader1 = {
	__file_identify = "Shader",
    precision = "highp",      --精度mediump,highp
    uniforms = {
        --默认内置变量
        texture0 = {"sampler2D"},    --纹理采样器
        color = {"vec4"},            --默认值为vec4(1.0,1.0,1.0,1.0)
        projection = {"mat4"},       --投影
        modelview = {"mat4"},        --视图
        objectSize = {"vec2"},       --控件的宽高
        --自定义
        mosaicSize = {"float", {type = "slider", value = 10,    range = {1,20},  tips = "mosaicSize,色块大小"},},
        startX = {"float", {type = "slider", value = 0.0,   range = {0,1},   tips = "startX,开始横位置"},},
        startY = {"float", {type = "slider",  value = 0.0,   range = {0,1},   tips = "startY,开始纵位置"},},
        width = {"float", {type = "slider",  value = 1.0,   range = {0,1},   tips = "width,宽度"},},
        height = {"float", {type = "slider", value = 1.0,   range = {0,1},   tips = "height,高度"},},
    },
    --vertex和fragment shader之间做数据传递用的。一般vertex shader修改varying变量的值，然后fragment shader使用该varying变量的值。
    varying = {
        varyTexCoord = {"vec2"}, --顶点着色器传入变量，顶点坐标
        --image = {},
    },
    --只能在vertex shader中使用的变量
    attribute = {
        position = {"vec3"},
        texcoord0 = { "vec2"},
    },
    --precision = "mediump",
    vs = [=[
        void main (void)
        {
            gl_Position = projection * (modelview * vec4(position,1.0));
            varyTexCoord = texcoord0;
        }
    ]=],
    fs = [=[
        void main()
        {
            vec2 uv = varyTexCoord.xy;

            float mul = width*height;
            int isMosaic = 1;
            if(mul == 0.0){
                isMosaic = 0;
            }else{
                float minX = clamp(startX,0.0,1.0);
                float maxX = clamp((startX+width),0.0,0.5);
                float minY = clamp(startY,0.0,1.0);
                float maxY = clamp((startY+height),0.0,0.5);
                if(uv.x < minX || uv.x > maxX || uv.y < minY || uv.y > maxY){
                    isMosaic = 0;
                }else{
                    isMosaic = 1;
                }
            }
            vec4 dcolor;//最终颜色
            if(isMosaic == 0){
                dcolor = texture2D(texture0, uv.xy)*color;
            }else{
                vec2 xy = vec2(uv.x * objectSize.x, uv.y * objectSize.y);//当前像素坐标
                vec2 xyMosaic = vec2(floor(xy.x / mosaicSize) * mosaicSize, //当前像素所在马赛克纹理中的坐标
                     floor(xy.y / mosaicSize) * mosaicSize );
                vec2 uvMosaic = vec2(xyMosaic.x / objectSize.x, xyMosaic.y / objectSize.y);
                dcolor = texture2D( texture0, uvMosaic )*color;
            }
            gl_FragColor = dcolor;

        }

    ]=],
    
}

return Shader1