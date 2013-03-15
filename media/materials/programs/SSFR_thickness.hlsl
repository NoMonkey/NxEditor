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

 
VertexOut mainVS(	VertexIn	input,
			uniform float4x4	worldViewProj_m,
			uniform float4x4	worldView_m,
			uniform float		sphereRadius,
			uniform float4		depthRange,
			uniform float4		texelOffsets
   	    )
{
	VertexOut output = (VertexOut)0;
	input.pos.y += sphereRadius;  // ORIGINAL
	output.pos = mul( worldViewProj_m, input.pos );
	output.texco = input.texco;
	return output;
	
}

    PixelOutput mainPS(PixelInput input)
    {
       PixelOutput output = (PixelOutput)0;
       // calculate eye-space sphere normal from texture coordinates
       float3 N;
       N.xy = input.texco*2.0-1.0;
       float r2 = dot(N.xy, N.xy);
       if (r2 > 1.0) discard;   // kill pixels outside circle
       N.z = sqrt(1.0 - r2);
       
       // calculate depth
	   float multiplier = 0.01; //Slime
	   //multiplier = 0.005; //Water
		output.color = float4(multiplier, multiplier, multiplier, 1);
	   return output;
    }


