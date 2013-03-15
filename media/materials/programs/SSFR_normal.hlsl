struct VertexIn
{
	float4 pos    	: POSITION;
	float2 texco    : TEXCOORD0;
};
 
struct VertexOut
{
	float4 	pos		: POSITION;
	float2 	texco	: TEXCOORD0;
};
 
struct PixelInput
{	
	float2	texco	: TEXCOORD0;
};

struct PixelOutput
{
	float4	color	: COLOR0;
};

 
VertexOut mainVS(VertexIn input,
				uniform float4x4 worldViewProj_m)
{
	VertexOut output = (VertexOut)0;
	//output.pos = input.pos;
	output.pos = mul( worldViewProj_m, input.pos );
	output.texco = input.texco;	
	return output;
}



float3 uvToEye(float2 texCoord, float depth, float4x4 iP_m){
	// Get x/w and y/w from the viewport position
	float x = texCoord.x * 2.0 - 1.0;
	//float y = (1 - texCoord.y) * 2.0 - 1.0;
	//float x = (1 - texCoord.x) * 2.0 - 1.0;
	float y = texCoord.y * 2.0 - 1.0;
	float4 clipPos = float4(x , y, depth, 1.0f);
	// Transform by the inverse projection matrix
	//float4 viewPos = mul(clipPos, iP_m); 
	float4 viewPos = mul(iP_m , clipPos);
	// Divide by w to get the view-space position
	return viewPos.xyz / viewPos.w;
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
			   uniform sampler	depthTex: register(s0),
			   uniform float4x4 invProj_m,
			   uniform float4x4 invWorldView_m,
			   uniform float far,
			   uniform float4 lightPos,
			   uniform float4x4 worldView_m)
{
	PixelOutput output = (PixelOutput)0;	
	
	//float maxDepth = ??; // use?
	// read eye-space depth from texture
	float depth = tex2D(depthTex, input.texco).r;
	if (depth < 0.001) {
		output.color = 0;
		discard;
		return output;
	}
	
	
	// calculate eye-space position from depth
	float2 texelSize;
	texelSize.x = 1.0/1366.0; // TODO: set dynamic
	texelSize.y = 1.0/768.0; 
	
	float3 posEye	= DepthToPosition(depth, ScreenToProj(input.texco), invProj_m, far);
	
	float3 left		= DepthToPosition(tex2D(depthTex, input.texco + float2(-texelSize.x, 0)).r, ScreenToProj(input.texco + float2(-texelSize.x, 0)), invProj_m, far);
	float3 right	= DepthToPosition(tex2D(depthTex, input.texco + float2(texelSize.x, 0)).r, ScreenToProj(input.texco + float2(texelSize.x, 0)), invProj_m, far);
	float3 top		= DepthToPosition(tex2D(depthTex, input.texco + float2(0, -texelSize.y)).r, ScreenToProj(input.texco + float2(0, -texelSize.y)), invProj_m, far);	
	float3 bottom	= DepthToPosition(tex2D(depthTex, input.texco + float2(0, texelSize.y)).r, ScreenToProj(input.texco + float2(0, texelSize.y)), invProj_m, far);
	/*
	float3 posEye = uvToEye(input.texco, depth, invProj_m);
	float3 left		= uvToEye(input.texco + float2(-texelSize.x, 0), tex2D(depthTex, input.texco + float2(-texelSize.x, 0)).r, invProj_m);
	float3 right	= uvToEye(input.texco + float2(texelSize.x, 0), tex2D(depthTex, input.texco + float2(texelSize.x, 0)).r, invProj_m);
	float3 top		= uvToEye(input.texco + float2(0, -texelSize.y), tex2D(depthTex, input.texco + float2(0, -texelSize.y)).r, invProj_m);
	float3 bottom	= uvToEye(input.texco + float2(0, texelSize.y), tex2D(depthTex, input.texco + float2(0, texelSize.y)).r, invProj_m);
	*/

	if(abs(posEye.z - left.z > 0.2) || abs(posEye.z - right.z > 0.2) || abs(posEye.z - top.z > 0.2) || abs(posEye.z - bottom.z > 0.2) ) discard;
	
	// calculate differences
	float3 ddx1 = right - posEye;
	float3 ddx2 = posEye - left;		
	if (abs(ddx1.z) > abs(ddx2.z)) {
		ddx1 = ddx2;
	}

	float3 ddy1 = bottom - posEye;
	float3 ddy2 = posEye - top;
	if (abs(ddy2.z) < abs(ddy1.z)) {
		ddy1 = ddy2;
	}
	


	// calculate normal
	float3 n = cross(ddx1, ddy1);
	n = normalize(n);
	//output.color = float4(n.x, -n.y, n.z ,1.0);
	
	n.y = -n.y;
	/*
	float4 lightPosEye = mul(worldView_m, lightPos);
	float3 lightDir = normalize( lightPosEye - posEye );
	//float3 viewDir	= normalize( cameraPos - worldpos );
	float3 viewDir = float3(0,1,0);
	
	float 	dotNL 	= max(0.0, dot(n, lightDir));
	float 	diff 	= saturate(dotNL);

	float3 	ref 	=  (n * 2 * dotNL) - lightDir;
	float	dotRV	= dot(ref, viewDir);
	float 	spec 	= pow(saturate(dotRV),15);

	float4 diffColor = float4(0.0, 0.5, 0.9, 1.0);
	float4 specColor = float4(1,1,1,1);
	float4 ambientColor = float4(0.1, 0.1, 0.1, 1);
 
	output.color = diff  * diffColor + spec*specColor  + ambientColor;

	/*
	float4 lightPosEye = mul(worldView_m, lightPos);
	float3 lightDir = normalize( lightPosEye - posEye );
	float diffuse = max(0.0, dot(n, lightDir));
	output.color = diffuse * float4(0.0,0.5,0.9,1.0);
	*/

	//normalize normal
	n = (n+1) / 2;
//	n = n * 2 -1;
	output.color = float4(n,1.0);
	return output;
}


	