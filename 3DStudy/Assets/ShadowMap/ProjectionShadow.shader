Shader "Custom/ProjectionShadow"
{

    // https://light11.hatenadiary.com/entry/2020/02/26/201321

    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _NormalTexture ("Normal", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

            sampler2D _NormalTexture;
            fixed4 _Color;

            struct Input
            {
                float4 position : SV_POSITION;
                float2 normalUV : TEXCOORD0;
                float3 lightDirection : TEXCOORD1;
            };

            float4x4 InverseTangentMatrix(float3 tangent, float3 binormal, float3 normal)
            {
                float4x4 tangentMatrix = float4x4
                (
                    float4(tangent,0),
                    float4(binormal,0),
                    float4(normal,0),
                    float4(0,0,0,1)                                                            
                );

                return transpose(tangentMatrix);
            }

            Input vert(appdata_full v)
            {
                Input input;
                input.position = UnityObjectToClipPos(v.vertex);
                input.normalUV = v.texcoord;

                float3 normal = v.normal;
                float3 tangent = v.tangent;
                float3 binormal = cross(normal, tangent);

                float3 localLight = mul( unity_WorldToObject, _WorldSpaceLightPos0 );

                input.lightDirection = mul(localLight, InverseTangentMatrix(tangent,binormal,normal));

                return input;
            }

            fixed4 frag(Input IN) : SV_Target
            {
                float3 normal = UnpackNormal(tex2D(_NormalTexture,IN.normalUV));
                float3 lightDirection = normalize( IN.lightDirection );
                float diffuse = max(0,dot(normal,lightDirection));
                return diffuse * _Color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
