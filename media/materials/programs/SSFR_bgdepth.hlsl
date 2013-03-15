struct VertexIn
{
	float4 pos    	: POSITION;
};
 
struct VertexOut
{
	float4 pos	: POSITION;
	float3	eyeSpacePos		: TEXCOORD1;
};
 
struct PixelInput
{	
	float3	eyeSpacePos		: TEXCOORD1;
};

struct PixelOutput
{
	float4	color	: COLOR0;
};

 
VertexOut mainVS(	VertexIn	input, uniform float4x4	worldView_m, uniform float4x4 worldViewProj_m)
{
	VertexOut output = (VertexOut)0;
	output.pos = mul( worldViewProj_m, input.pos );
	output.eyeSpacePos = mul( worldView_m, input.pos ).xyz;
	return output;	
}

PixelOutput mainPS(PixelInput input, uniform float farClipPlane, uniform float4x4 projMatrix)
{
	PixelOutput output = (PixelOutput)0;
	float4 pixelPos = float4(input.eyeSpacePos,1.0);
	float4 clipSpacePos = mul(projMatrix,pixelPos);  
	output.color.r = clipSpacePos.w / farClipPlane;
	return output;
}


