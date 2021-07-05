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
                input.uv = v.texcoord;

                // float3 normal = v.normal;
                // float3 tangent = v.tangent;
                // float3 binormal = cross(normal, tangent);

                TANGENT_SPACE_ROTATION;
                input.lightDirection = normalize( mul(rotation, ObjSpaceLightDir(v.vertex)) );
                input.viewDirection = normalize( mul(rotation, ObjSpaceViewDir(v.vertex)) );

                // float3 localLight = mul( unity_WorldToObject, _WorldSpaceLightPos0 );
                // input.lightDirection = mul(localLight, InverseTangentMatrix(tangent,binormal,normal));

                // float3 localView = mul( unity_WorldToObject, _WorldSpaceCameraPos );
                // input.viewDirection = mul(localView, InverseTangentMatrix(tangent,binormal,normal));

                return input;
            }

            fixed4 frag(Input IN) : SV_Target
            {
                float4 height = tex2D(_HeightTexture,IN.uv );

                float2 normalUV = IN.uv + IN.viewDirection.xy * height.r * _HeightFactor;
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
