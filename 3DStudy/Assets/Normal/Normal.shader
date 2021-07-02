Shader "Custom/Normal"
{
    Properties
    {
        _NormalTexture ("Normal", 2D) = "white" {}
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

            struct Input
            {
                float4 position : SV_POSITION;
                float2 normalUV : TEXCOORD0;
            };

            Input vert(appdata_full v)
            {
                Input input;
                input.position = UnityObjectToClipPos(v.vertex);
                input.normalUV = v.texcoord;
                return input;
            }

            fixed4 frag (Input IN) : SV_Target
            {
                // Albedo comes from a texture tinted by color
                fixed4 c = tex2D (_NormalTexture, IN.normalUV);
                return c;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
