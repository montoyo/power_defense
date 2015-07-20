-- Since we didn't write some of these shaders, this is not affected by the GPL license
td = td or {}
td.effects = td.effects or {}

-- Flou 9 prises, inspire de https://github.com/mattdesl/lwjgl-basics/wiki/ShaderLesson5
td.effects.blurX = love.graphics.newShader[[
	extern number size;

	vec4 effect(vec4 col, Image tex, vec2 uv, vec2 pos) {
		number blur = 1.0 / size;
		
		vec3 ret = Texel(tex, vec2(uv.x - 4.0 * blur, uv.y)).rgb * 0.0162162162;
		ret     += Texel(tex, vec2(uv.x - 3.0 * blur, uv.y)).rgb * 0.0540540541;
		ret     += Texel(tex, vec2(uv.x - 2.0 * blur, uv.y)).rgb * 0.1216216216;
		ret     += Texel(tex, vec2(uv.x - 1.0 * blur, uv.y)).rgb * 0.1945945946;
		ret     += Texel(tex, uv).rgb * 0.2270270270;
		ret     += Texel(tex, vec2(uv.x + 1.0 * blur, uv.y)).rgb * 0.1945945946;
		ret     += Texel(tex, vec2(uv.x + 2.0 * blur, uv.y)).rgb * 0.1216216216;
		ret     += Texel(tex, vec2(uv.x + 3.0 * blur, uv.y)).rgb * 0.0540540541;
		ret     += Texel(tex, vec2(uv.x + 4.0 * blur, uv.y)).rgb * 0.0162162162;
		
		return vec4(ret, 1.0);
	}
]]

td.effects.blurY = love.graphics.newShader[[
	extern number size;

	vec4 effect(vec4 col, Image tex, vec2 uv, vec2 pos) {
		number blur = 1.0 / size;
		
		vec3 ret = Texel(tex, vec2(uv.x, uv.y - 4.0 * blur)).rgb * 0.0162162162;
		ret     += Texel(tex, vec2(uv.x, uv.y - 3.0 * blur)).rgb * 0.0540540541;
		ret     += Texel(tex, vec2(uv.x, uv.y - 2.0 * blur)).rgb * 0.1216216216;
		ret     += Texel(tex, vec2(uv.x, uv.y - 1.0 * blur)).rgb * 0.1945945946;
		ret     += Texel(tex, uv).rgb * 0.2270270270;
		ret     += Texel(tex, vec2(uv.x, uv.y + 1.0 * blur)).rgb * 0.1945945946;
		ret     += Texel(tex, vec2(uv.x, uv.y + 2.0 * blur)).rgb * 0.1216216216;
		ret     += Texel(tex, vec2(uv.x, uv.y + 3.0 * blur)).rgb * 0.0540540541;
		ret     += Texel(tex, vec2(uv.x, uv.y + 4.0 * blur)).rgb * 0.0162162162;
		
		return vec4(ret, 1.0);
	}
]]

-- Degrade vertical
td.effects.gradientY = love.graphics.newShader[[
	extern vec4 sColor;
	extern vec4 eColor;
	extern number yStart;
	extern number yEnd;
	
	vec4 effect(vec4 col, Image tex, vec2 uv, vec2 pos) {
		number v = clamp((pos.y - yStart) / (yEnd - yStart), 0.0, 1.0);
		return col * mix(sColor, eColor, v);
	}
]]

-- Detection de bord, inspire de http://coding-experiments.blogspot.fr/2010/06/edge-detection.html
td.effects.edgeDetection = love.graphics.newShader[[
	extern vec2 texSize;
	
	number alpha(Image tex, vec2 coord) {
		if(coord.x < 0.0 || coord.x >= 1.0 || coord.y < 0.0 || coord.y >= 1.0)
			return 0.0;
		else
			return Texel(tex, coord).a;
	}

	vec4 effect(vec4 col, Image tex, vec2 uv, vec2 pos) {
		number px = 1.0 / texSize.x;
		number py = 1.0 / texSize.y;
		
		number pix0 = alpha(tex, uv + vec2(-px, -py));
		number pix1 = alpha(tex, uv + vec2(-px, 0.0));
		number pix2 = alpha(tex, uv + vec2(-px,  py));
		number pix3 = alpha(tex, uv + vec2(0.0, -py));
		number pix5 = alpha(tex, uv + vec2(0.0,  py));
		number pix6 = alpha(tex, uv + vec2( px, -py));
		number pix7 = alpha(tex, uv + vec2( px, 0.0));
		number pix8 = alpha(tex, uv + vec2( px,  py));
		
		number val = (abs(pix1 - pix7) + abs(pix5 - pix3) + abs(pix0 - pix8) + abs(pix2 - pix6)) / 4.0;
		
		if(val < 0.25)
			return vec4(0.0);
		else if(val > 0.4)
			return vec4(col.rgb, 1.0);
		else
			return vec4(col.rgb, val);
	}
]]

-- Changement de couleur
td.effects.colorBlend = love.graphics.newShader[[
	vec4 effect(vec4 col, Image tex, vec2 uv, vec2 pos) {
		vec4 p = Texel(tex, uv);
		return vec4(p.rgb * (1.0 - col.a) + col.rgb * col.a, p.a);
	}
]]

-- Effet "tele"; copie de https://www.shadertoy.com/view/ldXGW4 (de ehj1)
-- A REMPLACER PAR UN TRUC HOME MADE!!!
td.effects.scanlines = love.graphics.newShader[[
	extern number iGlobalTime;

	// change these values to 0.0 to turn off individual effects
	number vertJerkOpt = 1.0;
	number vertMovementOpt = 1.0;
	number bottomStaticOpt = 0.25;
	number scalinesOpt = 1.0;
	number rgbOffsetOpt = 0.6;
	number horzFuzzOpt = 1.0;

	// Noise generation functions borrowed from: 
	// https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl

	vec3 mod289(vec3 x) {
	  return x - floor(x * (1.0 / 289.0)) * 289.0;
	}

	vec2 mod289(vec2 x) {
	  return x - floor(x * (1.0 / 289.0)) * 289.0;
	}

	vec3 permute(vec3 x) {
	  return mod289(((x*34.0)+1.0)*x);
	}

	number snoise(vec2 v)
	  {
	  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
						  0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
						 -0.577350269189626,  // -1.0 + 2.0 * C.x
						  0.024390243902439); // 1.0 / 41.0
	// First corner
	  vec2 i  = floor(v + dot(v, C.yy) );
	  vec2 x0 = v -   i + dot(i, C.xx);

	// Other corners
	  vec2 i1;
	  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
	  //i1.y = 1.0 - i1.x;
	  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	  // x0 = x0 - 0.0 + 0.0 * C.xx ;
	  // x1 = x0 - i1 + 1.0 * C.xx ;
	  // x2 = x0 - 1.0 + 2.0 * C.xx ;
	  vec4 x12 = x0.xyxy + C.xxzz;
	  x12.xy -= i1;

	// Permutations
	  i = mod289(i); // Avoid truncation effects in permutation
	  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
			+ i.x + vec3(0.0, i1.x, 1.0 ));

	  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
	  m = m*m ;
	  m = m*m ;

	// Gradients: 41 points uniformly over a line, mapped onto a diamond.
	// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

	  vec3 x = 2.0 * fract(p * C.www) - 1.0;
	  vec3 h = abs(x) - 0.5;
	  vec3 ox = floor(x + 0.5);
	  vec3 a0 = x - ox;

	// Normalise gradients implicitly by scaling m
	// Approximation of: m *= inversesqrt( a0*a0 + h*h );
	  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

	// Compute final noise value at P
	  vec3 g;
	  g.x  = a0.x  * x0.x  + h.x  * x0.y;
	  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	  return 130.0 * dot(m, g);
	}

	number staticV(vec2 uv) {
		number staticHeight = snoise(vec2(9.0,iGlobalTime*1.2+3.0))*0.3+5.0;
		number staticAmount = snoise(vec2(1.0,iGlobalTime*1.2-6.0))*0.1+0.3;
		number staticStrength = snoise(vec2(-9.75,iGlobalTime*0.6-3.0))*2.0+2.0;
		return (1.0-step(snoise(vec2(5.0*pow(iGlobalTime,2.0)+pow(uv.x*7.0,1.2),pow((mod(iGlobalTime,100.0)+100.0)*uv.y*0.3+3.0,staticHeight))),staticAmount))*staticStrength;
	}

	vec4 effect(vec4 fragColor, Image iChannel0, vec2 uv, vec2 pozzzz)
	{

		//vec2 uv =  fragCoord.xy/iResolution.xy;
		
		number jerkOffset = (1.0-step(snoise(vec2(iGlobalTime*1.3,5.0)),0.8))*0.05;
		
		number fuzzOffset = snoise(vec2(iGlobalTime*15.0,uv.y*80.0))*0.003;
		number largeFuzzOffset = snoise(vec2(iGlobalTime*1.0,uv.y*25.0))*0.004;
		
		number vertMovementOn = (1.0-step(snoise(vec2(iGlobalTime*0.2,8.0)),0.4))*vertMovementOpt;
		number vertJerk = (1.0-step(snoise(vec2(iGlobalTime*1.5,5.0)),0.6))*vertJerkOpt;
		number vertJerk2 = (1.0-step(snoise(vec2(iGlobalTime*5.5,5.0)),0.2))*vertJerkOpt;
		number yOffset = abs(sin(iGlobalTime)*4.0)*vertMovementOn+vertJerk*vertJerk2*0.3;
		number y = mod(uv.y+yOffset,1.0);
		
		
		number xOffset = (fuzzOffset + largeFuzzOffset) * horzFuzzOpt;
		
		number staticVal = 0.0;
	   
		for (number y = -1.0; y <= 1.0; y += 1.0) {
			number maxDist = 5.0/200.0;
			number dist = y/200.0;
			staticVal += staticV(vec2(uv.x,uv.y+dist))*(maxDist-abs(dist))*1.5;
		}
			
		staticVal *= bottomStaticOpt;
		
		number red 	=   Texel(	iChannel0, 	vec2(uv.x + xOffset -0.01*rgbOffsetOpt,y)).r+staticVal;
		number green = 	Texel(	iChannel0, 	vec2(uv.x + xOffset,	  y)).g+staticVal;
		number blue 	=	Texel(	iChannel0, 	vec2(uv.x + xOffset +0.01*rgbOffsetOpt,y)).b+staticVal;
		
		vec3 color = vec3(red,green,blue);
		number scanline = sin(uv.y*800.0)*0.04*scalinesOpt;
		color -= scanline;
		
		return vec4(color,1.0);
	}
]]
