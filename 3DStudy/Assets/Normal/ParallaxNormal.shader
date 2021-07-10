#warning Upgrade NOTE: unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/ParalaxNormal"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _NormalTexture ("Normal", 2D) = "bump" {}
        _HeightTexture ("Height", 2D) = "gray" {}
        _HeightFactor ("Height Factor", Range(0.0,0.1)) = 0.03
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

            fixed4 _Color;
            sampler2D _NormalTexture;
            sampler2D _HeightTexture;
            half _HeightFactor;

            struct Input
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDirection : TEXCOORD1;
                float3 viewDirection : TEXCOORD2;
            };

            float3x3 InverseTangentMatrix(float3 tangent, float3 binormal, float3 normal)
            {
                // return float3x3(tangent,binormal,normal);
                float4x4 tangentMatrix = float4x4
                (
                    float4(tangent,0),
                    float4(binormal,0),
                    float4(normal,0),
                    float4(0,0,0,1)                                                            
                );

                return transpose( tangentMatrix );
            }

            Input vert(appdata_full v)
            {
                Input input;
                input.position = UnityObjectToClipPos(v.vertex);
                input.uv = v.texcoord;

                TANGENT_SPACE_ROTATION;
                input.lightDirection = mul(rotation, ObjSpaceLightDir(v.vertex));
                input.viewDirection = mul(rotation, ObjSpaceViewDir(v.vertex));

                return input;
            }

            fixed4 frag(Input IN) : SV_Target
            {
                float4 height = tex2D(_HeightTexture,IN.uv );

                float2 normalUV = IN.uv + normalize( IN.viewDirection.xy ) * height.r * _HeightFactor;
                float3 normal = UnpackNormal(tex2D(_NormalTexture,normalUV));
                float3 lightDirection = normalize( IN.lightDirection );
                float diffuse = max(0,dot(normal,lightDirection));
                return diffuse * _Color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
