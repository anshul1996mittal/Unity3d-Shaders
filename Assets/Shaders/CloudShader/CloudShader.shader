Shader "CustomShader/Sky/CloudShader_Final"
{
    Properties
    {
        _TopSkyColor ("Top Sky Color", Color) = (0.2,0.5,1,1)
        _HorizonColor ("Horizon Color", Color) = (0.6,0.8,1,1)

        _CloudColor ("Cloud Color", Color) = (1,1,1,1)

        _CloudSpeed ("Cloud Speed", Float) = 0.1
        _CloudScale ("Cloud Scale", Float) = 3
        _CloudDensity ("Cloud Density", Float) = 0.5
        _CloudSoftness ("Cloud Softness", Float) = 0.2
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float4 _TopSkyColor;
            float4 _HorizonColor;
            float4 _CloudColor;

            float _CloudSpeed;
            float _CloudScale;
            float _CloudDensity;
            float _CloudSoftness;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // Better hash-based noise
            float hash(float2 p)
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
            }

            float noise(float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);

                float a = hash(i);
                float b = hash(i + float2(1,0));
                float c = hash(i + float2(0,1));
                float d = hash(i + float2(1,1));

                float2 u = f * f * (3.0 - 2.0 * f);

                return lerp(a, b, u.x) +
                       (c - a)* u.y * (1.0 - u.x) +
                       (d - b)* u.x * u.y;
            }

            // FBM (layered noise)
            float fbm(float2 uv)
            {
                float value = 0.0;
                float amplitude = 0.5;

                for(int i = 0; i < 4; i++)
                {
                    value += noise(uv) * amplitude;
                    uv *= 2.0;
                    amplitude *= 0.5;
                }

                return value;
            }

            half4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;

                // Animate clouds
                float2 cloudUV = uv * _CloudScale;
                cloudUV.x += _Time.y * _CloudSpeed;

                // Generate layered clouds
                float n = fbm(cloudUV);

                // Soft cloud mask
                float cloud = smoothstep(_CloudDensity, _CloudDensity + _CloudSoftness, n);

                // Sky gradient
                float skyLerp = uv.y;
                float3 skyColor = lerp(_HorizonColor.rgb, _TopSkyColor.rgb, skyLerp);

                // Combine sky + clouds
                float3 finalColor = lerp(skyColor, _CloudColor.rgb, cloud);

                return float4(finalColor, 1);
            }

            ENDHLSL
        }
    }
}