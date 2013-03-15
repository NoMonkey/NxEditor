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
	//float	depth		: DEPTH;
	float4	color		: COLOR0;
};

 
VertexOut mainVS(VertexIn input,
				uniform float4x4 worldViewProj_m)
{
	VertexOut output = (VertexOut)0;
	output.texco = input.texco;
	//output.pos = input.pos;
	output.pos = mul( worldViewProj_m, input.pos );
	return output;
	
}


float smooth(int2 blurDir, float filterRadius, sampler depthSampler, float blurScale, float blurDepthFalloff, float2 texcoord, float texelSize)
{
	float depth = tex2D(depthSampler, texcoord).x;
	float sum = 0;
	float wsum = 0;
	for(float x=-filterRadius; x<=filterRadius; x += texelSize) {
		float dsample = tex2D(depthSampler, texcoord + x*blurDir).r;
		
		// spatial domain
		float r = x * blurScale;
		float w = exp(-r*r);
		// range domain
		float r2 = (dsample - depth) * blurDepthFalloff;
		float g = exp(-r2*r2);
		sum += dsample * w * g;
		wsum += w * g;
	}
	if (wsum > 0.0) {
		sum /= wsum;
	}
	return sum;
}




PixelOutput mainPS(PixelInput input, 
               uniform sampler depthTex : register(s0))
{
	PixelOutput output = (PixelOutput)0; 
	/*
	if(tex2D(depthTex, input.texco).r > 0.1)
	{
		discard;
		return output;
	}
	*/
	float2 texelSize = float2(1.0/1366.0, 1.0/768.0); // TODO: set dynamic

	int blurRadius = 15;
	float blurDepthFalloff = 0.1;
	float blurScale = 0.1;
	
	float x = smooth(int2(1,0), texelSize.x * blurRadius, depthTex, blurScale, blurDepthFalloff, input.texco, texelSize.x);
	float y = smooth(int2(0,1), texelSize.y * blurRadius, depthTex, blurScale, blurDepthFalloff, input.texco, texelSize.y);
	output.color.r = (x+y) / 2;
//output.color.r = x;
	//output.color.r = tex2D(depthTex, input.texco).r;
	//output.color = float4(1,0,0,1);
	return output;
}