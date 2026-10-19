shader_type canvas_item;
render_mode unshaded;
// Reserved UV bands carry effect parameters through the depth-sorted draw stream.
// Ordinary sprites and floor geometry retain their original texture and color.
varying float effect_kind;
varying vec2 effect_uv;
varying vec4 effect_params;
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
float flow(vec2 p) { return noise(p)*0.65+noise(p*2.03+7.1)*0.35; }
vec3 flame_color(float heat) {
	vec3 c=mix(vec3(0.68,0.055,0.006),vec3(1,0.36,0.015),smoothstep(0.08,0.42,heat));
	c=mix(c,vec3(1,0.84,0.22),smoothstep(0.40,0.75,heat));
	return mix(c,vec3(1,0.99,0.80),smoothstep(0.73,0.96,heat));
}
void vertex() {
	effect_kind=UV.x>=64.0 ? floor(UV.x/64.0) : 0.0;
	effect_uv=vec2(UV.x-effect_kind*64.0,UV.y);
	effect_params=COLOR;
}
void fragment() {
	if(effect_kind<0.5) {
		COLOR=texture(TEXTURE,UV)*effect_params;
	} else {
		float age=effect_params.r, seed=effect_params.g, opacity=effect_params.b;
		vec2 p=effect_uv*2.0-1.0;
		if(effect_kind<1.5) {
			float r=length(p), z=sqrt(max(0.0,1.0-dot(p,p)));
			float swirl=atan(p.y,p.x)+age*5.0+z*3.2;
			vec2 q=vec2(cos(swirl),sin(swirl))*(1.4+r*2.4);
			float n=flow(q+vec2(-age*3.0,seed*9.0));
			float folds=sin(swirl*3.0+r*13.0-age*8.0+n*5.0);
			float heat=clamp(0.34+z*0.38+folds*0.28+n*0.20,0.0,1.0);
			COLOR=vec4(flame_color(heat),(1.0-smoothstep(0.86,1.0,r))*opacity);
		} else if(effect_kind<2.5) {
			float t=effect_uv.x, edge=abs(p.y);
			float n=flow(vec2(t*6.0-age*11.0,p.y*2.2+seed*7.0));
			float width=0.54+n*0.46;
			float alpha=(1.0-smoothstep(width*0.52,width,edge))*smoothstep(0.0,0.14,t)*opacity;
			float heat=clamp(0.22+(1.0-edge)*0.40+n*0.27+t*0.15,0.0,1.0);
			COLOR=vec4(flame_color(heat),alpha);
		} else if(effect_kind<3.5) {
			float r=length(p), n=flow(p*2.5+vec2(seed*11.0,-age*1.6));
			float alpha=(1.0-smoothstep(0.55,0.99,r+(n-0.5)*0.23))*opacity;
			vec3 smoke=mix(vec3(0.10,0.095,0.13),vec3(0.40,0.36,0.34),n-p.y*0.1);
			smoke+=vec3(0.32,0.075,0.008)*max(0.0,1.0-age*2.5)*(1.0-r);
			COLOR=vec4(smoke,alpha);
		} else if(effect_kind<4.5) {
			float r=abs(p.x)+abs(p.y);
			COLOR=vec4(mix(vec3(1,0.30,0.02),vec3(1,0.95,0.55),1.0-clamp(r,0.0,1.0)),(1.0-smoothstep(0.15,1.0,r))*opacity);
		} else if(effect_kind<5.5) {
			float r=length(p), z=sqrt(max(0.0,1.0-dot(p,p)));
			float n=flow(p*3.0+vec2(age*2.0,seed));
			float hot=clamp(z*0.7+n*0.5,0.0,1.0);
			vec3 c=mix(vec3(0.19,0.10,0.62),vec3(0.25,0.72,1.0),hot);
			c=mix(c,vec3(0.88,0.99,1.0),smoothstep(0.65,0.95,hot));
			COLOR=vec4(c,(1.0-smoothstep(0.77,1.0,r))*opacity);
		} else if(effect_kind<6.5) {
			float n=flow(vec2(effect_uv.x*5.0-age*5.0,p.y*2.0+seed));
			float alpha=(1.0-smoothstep(0.1,0.9,abs(p.y)))*smoothstep(0.0,0.2,effect_uv.x)*opacity;
			COLOR=vec4(mix(vec3(0.35,0.17,0.85),vec3(0.70,0.95,1.0),n),alpha);
		} else if(effect_kind<7.5) {
			float r=length(p), theta=atan(p.y,p.x);
			float branches=pow(max(0.0,sin(theta*13.0+sin(r*19.0)*0.40)),28.0);
			float front=exp(-pow((r-clamp(age*2.7,0.05,0.98))*26.0,2.0));
			float mist=flow(p*6.0+age)*0.12;
			float alpha=(branches*0.5+front*0.8+mist)*(1.0-smoothstep(0.91,1.0,r))*opacity;
			COLOR=vec4(mix(vec3(0.12,0.45,0.95),vec3(0.78,0.97,1.0),max(branches,front)),alpha);
		} else if(effect_kind<8.5) {
			float r=length(p), theta=atan(p.y,p.x);
			float n=flow(p*3.0-age);
			float spiral=pow(max(0.0,sin(theta*4.0+r*15.0+age*6.0+n)),8.0);
			float alpha=(spiral*0.45+0.12)*(1.0-smoothstep(0.82,1.0,r))*smoothstep(0.0,0.12,r)*opacity;
			COLOR=vec4(mix(vec3(0.23,0.06,0.46),vec3(0.76,0.59,1.0),spiral),alpha);
		} else if(effect_kind<9.5) {
			float r=length(p), theta=atan(p.y,p.x);
			float band=exp(-pow((r-0.83)*65.0,2.0))+exp(-pow((r-0.66)*70.0,2.0))*0.6;
			float marks=step(0.74,r)*step(r,0.89)*pow(max(0.0,cos(theta*12.0+age*0.4)),28.0);
			float rays=pow(max(0.0,cos(theta*6.0+age*0.25)),60.0)*step(r,0.67)*smoothstep(0.2,0.5,r);
			COLOR=vec4(mix(vec3(0.27,0.40,0.94),vec3(0.88,0.78,0.50),marks),(band*0.48+marks*0.8+rays*0.3)*opacity);
		} else if(effect_kind<11.5) {
			// Facet colors are vertex-lit; procedural striations give the solid meshes
			// material detail without an atlas or changing the object between frames.
			float grain=flow(effect_uv*vec2(18.0,6.0));
			float streak=pow(max(0.0,sin(effect_uv.x*36.0+effect_uv.y*7.0+grain*3.0)),16.0);
			vec3 base=effect_params.rgb;
			if(effect_kind<10.5) {
				base=mix(base*0.72,base*1.12,grain);
				base=mix(base,vec3(0.94,0.99,1.0),streak*0.55);
			} else {
				base*=0.68+grain*0.52;
				base+=vec3(0.13,0.10,0.20)*streak;
			}
			COLOR=vec4(base,effect_params.a);
		} else if(effect_kind<12.5) {
			float r=length(p), z=sqrt(max(0.0,1.0-dot(p,p)));
			float n=flow(p*3.0+vec2(age*3.0,seed));
			float veins=pow(max(0.0,sin(p.x*10.0+p.y*7.0+n*5.0-age*4.0)),6.0);
			vec3 c=mix(vec3(0.20,0.025,0.12),vec3(1.0,0.23,0.08),veins);
			c=mix(c,vec3(1.0,0.83,0.49),pow(z,9.0)*0.75);
			COLOR=vec4(c,(1.0-smoothstep(0.82,1.0,r))*opacity);
		} else {
			float r=length(p);
			float edge=exp(-pow((r-0.91)*25.0,2.0));
			vec2 grid=p*7.0;
			float lines=min(abs(sin(grid.x*1.7+age*0.3)),min(abs(sin(grid.y*1.5+grid.x*0.85)),abs(sin(grid.y*1.5-grid.x*0.85))));
			float pattern=(1.0-smoothstep(0.02,0.09,lines))*0.23;
			COLOR=vec4(vec3(0.47,0.77,1.0),(edge*0.7+pattern+0.05)*(1.0-smoothstep(0.95,1.0,r))*opacity);
		}
	}
}
