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
                // 参考:https://www.programmersought.com/article/99606296884/

                const float3 rayDirection = normalize(IN.objectViewDirection);
                const int layers = 32;
                const float2 deltaUV = _HeightFactor * rayDirection.xy / rayDirection.z / layers;
                float deltaHeight = 1.0 / layers;

                float rayHeight = 1.0;
                float2 uv = IN.uv;
                float objectHeight = tex2D(_HeightTexture,uv );;

                [unroll]
                for(int i = 0; i < layers && objectHeight < rayHeight; ++i)
                {
                    uv -= deltaUV;

                    objectHeight = tex2D(_HeightTexture,uv );
                    rayHeight -= deltaHeight;
                }

                float2 previousUV = uv + deltaUV;
                float previousHeight = tex2D(_HeightTexture, previousUV ) - deltaHeight;
                float nextHeight = objectHeight;
                float ratio = nextHeight / ( nextHeight - previousHeight );

                float2 normalUV = uv * (1.0 - ratio) + previousUV * ratio;
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
