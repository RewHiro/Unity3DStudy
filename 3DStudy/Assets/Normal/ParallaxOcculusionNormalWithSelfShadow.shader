Shader "Custom/ParalaxOcculusionNormalWithSelfShadow"
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

            float2 parallaxMapping( float3 objectViewDirection, float2 uv, out float height )
            {
                // 参考:https://titanwolf.org/Network/Articles/Article?AID=3c01329d-d71a-4b11-ba56-b0ad82019c50#gsc.tab=0
                // 参考:https://www.programmersought.com/article/99606296884/

                const float3 rayDirection = objectViewDirection;
                const int layers = 32;
                const float2 deltaUV = _HeightFactor * rayDirection.xy / rayDirection.z / layers;
                float deltaHeight = 1.0 / layers;

                float rayHeight = 1.0;
                float2 currentUV = uv;
                float objectHeight = tex2D(_HeightTexture, currentUV );

                [unroll]
                for(int i = 0; i < layers && objectHeight < rayHeight; ++i)
                {
                    currentUV -= deltaUV;

                    objectHeight = tex2D(_HeightTexture,currentUV );
                    rayHeight -= deltaHeight;
                }

                float2 previousUV = currentUV + deltaUV;
                float previousHeight = tex2D(_HeightTexture, previousUV ) - deltaHeight + rayHeight;
                float nextHeight = objectHeight + rayHeight;
                float ratio = nextHeight / ( nextHeight - previousHeight );

                height = rayHeight + nextHeight * ( 1.0 - ratio ) + previousHeight * ratio;

                return currentUV * (1.0 - ratio) + previousUV * ratio;
            }

            float parallaxSoftShadowMultiplier( float3 lightDirection, float2 uv, float height )
            {
                float shadowMultipiler = 1;

                if( dot(float3( 0, 0, 1 ), lightDirection) > 0 )
                {
                    float numSamplesUnderSurface = 0;
                    shadowMultipiler = 0;
                    float numLayers = 32;
                    float layerHeight = height / numLayers;
                    float2 texStep = _HeightFactor * lightDirection.xy / lightDirection.z / numLayers;
                    
                    float currentLayerHeight = height - layerHeight;
                    float2 currentTextureCoords = uv + texStep;
                    float heightFromTexture = tex2D( _HeightTexture, currentTextureCoords );
                    int stepIndex = 1;

                    [unroll]
                    for( int i = 0; i < numLayers && currentLayerHeight > 0; i++)
                    {
                        if(heightFromTexture < currentLayerHeight)
                        {
                            numSamplesUnderSurface += 1;
                            float newShadowMutiplier = ( currentLayerHeight - heightFromTexture ) * ( 1.0 - stepIndex/numLayers);
                            shadowMultipiler = max(shadowMultipiler, newShadowMutiplier);
                        }

                        stepIndex += 1;
                        currentLayerHeight -= layerHeight;
                        currentTextureCoords += texStep;
                        heightFromTexture = tex2D( _HeightTexture, currentTextureCoords );
                    }

                    if(numSamplesUnderSurface < 1)
                    {
                        shadowMultipiler = 1;
                    }
                    else
                    {
                        shadowMultipiler = 1.0 - shadowMultipiler;
                    }
                }

                return shadowMultipiler;
            }

            fixed4 frag(Input IN) : SV_Target
            {
                float height = 0.0;
                float2 normalUV = parallaxMapping( normalize(IN.objectViewDirection), IN.uv, height );
                float3 normal = UnpackNormal(tex2D(_NormalTexture,normalUV));
                float3 lightDirection = normalize( IN.lightDirection );
                float diffuse = max(0,dot(normal,lightDirection)) * parallaxSoftShadowMultiplier( lightDirection, IN.uv, height );
                return diffuse * _Color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
