struct VertexIn
{
	float4 pos    	: POSITION;
	float2 texco    : TEXCOORD0;
};
 
struct VertexOut
{
	float4 	pos		: POSITION;
	float2 	texco	: TEXCOORD0;
	float3	lightDir : TEXCOORD1;
};
 
struct PixelInput
{	
	float2	texco	: TEXCOORD0;
	float3 lightDir : TEXCOORD1;
};

struct PixelOutput
{
	float4	color	: COLOR0;
};

 
VertexOut mainVS(VertexIn input,
				uniform float4x4 worldViewProj_m,
				uniform float4x4 world_m,
				uniform float3 lightPos)
{
	VertexOut output = (VertexOut)0;
	//output.pos = input.pos;
	output.pos = mul( worldViewProj_m, input.pos );
	output.texco = input.texco;	

	//lighting
	float3 worldpos = mul(world_m, input.pos);
	output.lightDir= normalize( lightPos - worldpos ); 
    output.lightDir = mul(worldViewProj_m, output.lightDir).xyz; 
	return output;
}





PixelOutput mainPS(PixelInput input,
			   uniform sampler	normalTex: register(s0),
			   uniform float4x4 invProj_m)
{
	PixelOutput output = (PixelOutput)0;
	float3 normal = tex2D(normalTex, input.texco).rgb;
	float diffuse = max(0.0, dot(normal, input.lightDir));

    output.color = float4(0.2,0.4,0.9,1) * diffuse;	
	float3 derp = float3(0,0,1);
	if(normal.z == derp.z)
	{
		output.color = float4(0,0,0,1);	
	}
	return output;
}


	