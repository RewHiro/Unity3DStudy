Shader "Custom/ParalaxOcculusionNormal"
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
                float3 objectViewDirection : TEXCOORD2;
            };

            Input vert(appdata_full v)
            {
                Input input;
                input.position = UnityObjectToClipPos(v.vertex);
                input.uv = v.texcoord;

                TANGENT_SPACE_ROTATION;
                input.lightDirection = mul(rotation, ObjSpaceLightDir(v.vertex));

                input.objectViewDirection = mul(rotation, ObjSpaceViewDir(v.vertex));

                return input;
            }

            fixed4 frag(Input IN) : SV_Target
            {
                // 参考:https://titanwolf.org/Network/Articles/Article?AID=3c01329d-d71a-4b11-ba56-b0ad82019c50#gsc.tab=0

                float3 rayDirection = normalize(IN.objectViewDirection);
                float2 diff = _HeightFactor * rayDirection.xy / rayDirection.z / 32;

                float rayHeight = 1.0;
                float objectHeight = 0.0;
                float2 uv = IN.uv;

                [unroll]
                for(int i = 0; i < 32 && objectHeight < rayHeight; ++i)
                {
                    uv -= diff;

                    objectHeight = tex2D(_HeightTexture,uv );
                    rayHeight -= 1.0 / 32;
                }

                float2 normalUV = uv;
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
