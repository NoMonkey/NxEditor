struct VertexIn
{
	float4 pos    	: POSITION;
	float2 texco    : TEXCOORD0;
};
 
struct VertexOut
{
	float4 	pos				: POSITION;
	float2 	texco			: TEXCOORD0;
};
 
struct PixelInput
{	
	float2	texco			: TEXCOORD0;
};

struct PixelOutput
{
	float4	color		: COLOR0;
};

 
VertexOut mainVS(VertexIn input,
				uniform float4x4 worldViewProj_m)
{
	VertexOut output = (VertexOut)0;
	output.pos = mul( worldViewProj_m, input.pos );
	output.texco = input.texco;	
	return output;
}

float4 PixelShaderFunctionWithoutTex(float3 eyeFragmentPos, float3 eyeLightPos, float3 eyeFragmentNormal)
{
	float SpecularPower = 30;
  // Get light direction for this fragment
	float3 lightDir = normalize(eyeFragmentPos - eyeLightPos);
  // Note: Non-uniform scaling not supported
	float diffuseLighting = saturate(dot(eyeFragmentNormal, -lightDir)); // per pixel diffuse lighting
  // Using Blinn half angle modification for perofrmance over correctness
	float3 h = normalize(normalize(float3(0,0,0) - eyeFragmentPos) - lightDir);
	float specLighting = pow(saturate(dot(h, eyeFragmentNormal)), SpecularPower);
	float3 DiffuseColor = float3 (0.8, 0.9, 1.0); //Water
	DiffuseColor = float3 (0.0,1,0.2); //Slime
	float3 SpecularColor = float3(0,0,0);
	float3 AmbientLightColor = float3(0.1, 0.1, 0.2);
	float3 LightDiffuseColor = 1;
	float3 LightSpecularColor = 1;
	return float4(saturate(
    AmbientLightColor +
    (DiffuseColor * LightDiffuseColor * diffuseLighting * 0.6) + // Use light diffuse vector as intensity multiplier
    (SpecularColor * LightSpecularColor * specLighting * 0.5) // Use light specular vector as intensity multiplier
    ), 1);
}


float4 shade(sampler normals, float2 texco, float4 lightEyePos, float3 posEye)
{
	float3 n = tex2D(normals, texco).rgb;
	//float4 lightPosEye = mul(worldView_m, lightPos);
	float3 lightDir = normalize(lightEyePos.xyz - posEye );
	//float3 viewDir	= normalize( cameraPos - worldpos );
	float3 viewDir = float3(0,1,0);
	
	float 	dotNL 	= max(0.0, dot(n, lightDir));
	float 	diff 	= saturate(dotNL);

	float3 	ref 	=  (n * 2 * dotNL) - lightDir;
	float	dotRV	= dot(ref, normalize(viewDir));
	float 	spec 	= pow(saturate(dotRV),15);

	float4 diffColor = float4(0.0, 0.5, 0.9, 1.0);
	float4 specColor = float4(1,1,1,1);
	float4 ambientColor = float4(0.1, 0.1, 0.1, 1);
 
	return diff*diffColor + spec*specColor  + ambientColor;
}

float4 ScreenToProj(float2 iCoord)
{
   // return float4(2.0f * float2(iCoord.x, 1.0f - iCoord.y) - 1, 0.0f, 1.0f);
   return float4(2.0f * iCoord - 1, 0.0f, 1.0f);
}

float3 DepthToPosition(float iDepth, float4 iPosProj, matrix mProjInv, float fFarClip)
{
    float3 vPosView = mul(mProjInv, iPosProj).xyz;
    float3 vViewRay = float3(vPosView.xy * (fFarClip / vPosView.z), fFarClip);
    float3 vPosition = vViewRay * iDepth;
    return vPosition;
}



PixelOutput mainPS(PixelInput input, 
               uniform sampler particleDepthTex : register(s0),
			   uniform sampler bgDepthTex	: register(s1),
			   uniform sampler bgTex		: register(s2),
			   uniform sampler normalTex	: register(s3),
			   uniform sampler thicknessTex : register(s4),
			   uniform float4 lightEyePos,
			   uniform float4x4 invProj_m,
			   uniform float far
			   )
{
	PixelOutput output = (PixelOutput)0; 

	if(tex2D(bgDepthTex, input.texco).r > tex2D(particleDepthTex, input.texco).r && tex2D(particleDepthTex, input.texco).r != 0)
	{
		// shade water surface
		//output.color = float4(tex2D(normalTex, input.texco).rgb, 1.0);	
		float3 posEye = DepthToPosition(tex2D(particleDepthTex, input.texco).r, ScreenToProj(input.texco), invProj_m, far);
		float4 particleColor = PixelShaderFunctionWithoutTex(posEye, lightEyePos, tex2D(normalTex, input.texco));
	//	float4 particleColor = shade(particleDepthTex, input.texco, lightEyePos, posEye);
		float thickness = tex2D(thicknessTex, input.texco).r;

		//float4 bgColor = float4(tex2D(bgTex, input.texco).rgb,1.0);
		float4 bgColor = tex2D(bgTex, input.texco + tex2D(normalTex,input.texco).rg * thickness * 0.5);
		output.color = (thickness * particleColor) + (1-thickness) * bgColor;
		if(thickness < 0.1) {
			output.color = tex2D(bgTex, input.texco);
		}
		//output.color = float4(thickness,thickness,thickness,1);
	//	output.color = particleColor;
	//	output.color = shade(normalTex, input.texco, lightEyePos, posEye);	
		//output.color = particleColor;
	//	output.color = particleColor;
	//	output.color = tex2D(normalTex, input.texco);
	}else
	{
		
		output.color = float4(tex2D(bgTex, input.texco).rgb, 1.0);
	}


	return output;
}