Shader "Custom/ProjectionShadow"
{

    // https://light11.hatenadiary.com/entry/2020/02/26/201321

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

            struct v2f
            {
                float4 position : SV_POSITION;
                float4 projectorSpacePosition : TEXCOORD0;
                float3 worldPosition : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            sampler2D _ShadowProjectorTexture;
            float4x4 _ShadowProjectorMatrixVP;
            float4 _ShadowProjectorPosition;

            v2f vert(appdata_full v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                o.projectorSpacePosition = mul(mul(_ShadowProjectorMatrixVP, unity_ObjectToWorld), v.vertex);
                o.projectorSpacePosition = ComputeScreenPos(o.projectorSpacePosition);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul( unity_ObjectToWorld, v.vertex );
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                i.projectorSpacePosition.xyz /= i.projectorSpacePosition.w;
                float2 uv = i.projectorSpacePosition.xy;
                float4 projectorTex = tex2D(_ShadowProjectorTexture, uv);

                fixed3 isOut = step((i.projectorSpacePosition - 0.5) * sign(i.projectorSpacePosition), 0.5);
                float alpha = isOut.x * isOut.y * isOut.z;

                alpha = step( -dot( lerp(-_ShadowProjectorPosition.xyz, _ShadowProjectorPosition.xyz - i.worldPosition, _ShadowProjectorPosition.w ), i.worldNormal ), 0 );
                return lerp(1, projectorTex, alpha);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
