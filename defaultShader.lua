--vs
#ifdef GL_ES
precision highp float;
#endif
uniform     mat4    projection;
uniform     mat4    modelview;
attribute   vec3    position;
attribute   vec2    texcoord0;
varying     vec2    varyTexCoord;
void main (void)
{
    gl_Position = projection * (modelview * vec4(position,1.0));\
    varyTexCoord = texcoord0;
}

--fs
#ifdef GL_ES
precision highp float;
#endif
uniform     sampler2D   texture0;
uniform     vec4        color;
varying     vec2        varyTexCoord;
void main (void)
{
    gl_FragColor = texture2D(texture0, varyTexCoord.xy) * color;
}

--uniforms
{
	1 = {
		1 = "projection"
		2 = 35676
		3 = 1
		4 = {
			1 = "\000\000?\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000?\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000?\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000?"
			2 = 35676
		}
	}
	2 = {
		1 = "modelview"
		2 = 35676
		3 = 1
		4 = {
			1 = "\000\000?\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000?\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000?\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000?"
			2 = 35676
		}
	}
	3 = {
		1 = "texture0"
		2 = 5124
		3 = 1
		4 = {
			1 = "\000\000\000\000"
			2 = 5124
		}
	}
	4 = {
		1 = "color"
		2 = 35666
		3 = 1
		4 = {
			1 = "\000\000?\000\000?\000\000?\000\000?"
			2 = 35666
		}
	}
}


http://266-resources.oa.com/upload/netview/1032//netview1/1032/activitySign/activitySign.nvp?t=1581905530&category=-- self.object.MachingDetailDialog:updateView(data)
                    -- self.object.MachingDetailDialog.left = 0
					
					
					-- self.object.MachingDetailDialog:updateView(data)
                    -- self.object.MachingDetailDialog.left = 0
					
					
					
					import_path: D:\266-app-tools\idl
output: D:\266_app_proj_new\assets\app\services