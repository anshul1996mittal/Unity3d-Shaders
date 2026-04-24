Shader "CustomShader/Water/StylizedWater_Final"
{
    Properties
    {
        _ShallowColor ("Shallow Color", Color) = (0.3,0.8,1,0.6)
        _DeepColor ("Deep Color", Color) = (0.0,0.2,0.6,0.6)

        _WaveSpeed ("Wave Speed", Float) = 1
        _WaveStrength ("Wave Strength", Float) = 0.1

        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamThreshold ("Foam Threshold", Float) = 0.05
        _FoamSmooth ("Foam Smoothness", Float) = 0.1

        _FresnelPower ("Fresnel Power", Float) = 3
        _FresnelIntensity ("Fresnel Intensity", Float) = 0.5
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float wave : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            float4 _ShallowColor;
            float4 _DeepColor;

            float _WaveSpeed;
            float _WaveStrength;

            float4 _FoamColor;
            float _FoamThreshold;
            float _FoamSmooth;

            float _FresnelPower;
            float _FresnelIntensity;

            float hash(float2 p)
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
            }
            //  Vertex
            v2f vert(appdata v)
            {
                v2f o;
                float rand = hash(v.vertex.xz);
                //  Wave motion
                float wave = wave = sin(v.vertex.x * 2 + _Time.y * _WaveSpeed + rand * 6.28);
                //sin(v.vertex.x * 2 + _Time.y * _WaveSpeed)
                           //+ sin(v.vertex.z * 2 + _Time.y * _WaveSpeed);

                wave = wave * 0.5 + 0.5; // normalize 0–1
                wave *= _WaveStrength;

                v.vertex.y += wave;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.wave = wave;

                //  World data
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.vertex).xyz);

                return o;
            }

            // Fragment
            half4 frag(v2f i) : SV_Target
            {
                // Depth color
                float depth = i.uv.y;
                float3 waterColor = lerp(_ShallowColor.rgb, _DeepColor.rgb, depth);

                // Foam (soft)
                float foam = smoothstep(_FoamThreshold, _FoamThreshold + _FoamSmooth, i.wave);

                float3 foamColor = lerp(waterColor, _FoamColor.rgb, foam);

                // Fresnel (edge glow)
                float fresnel = pow(1.0 - saturate(dot(i.viewDir, i.worldNormal)), _FresnelPower);
                fresnel *= _FresnelIntensity;

                float3 finalColor = foamColor + fresnel;

                return float4(finalColor, _ShallowColor.a);
            }

            ENDHLSL
        }
    }
}