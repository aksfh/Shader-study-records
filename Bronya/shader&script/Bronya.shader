Shader "GenshinAvatarShader/Bronya/01"
{
    Properties
    {
        [KeywordEnum(None,Face,Hair,UpperBody,LowerBody)] _Area("Material area",float)=0
        [HideInInspector] _HeadForward("",Vector) = (0 ,0 ,1)
        [HideInInspector] _HeadRight("",Vector) = (1 ,0 ,0)

        [Header(Base Color)]
        [HideInInspector] _BaseMap("",2D) = "white" {}
        [NoScaleOffset] _FaceColorMap("Face color map (Default white)", 2D) = "white" {}
        [NoScaleOffset] _HairColorMap("Hair color map (Default white)", 2D) = "white" {}
        [NoScaleOffset] _UpperBodyColorMap("Upper body color map (Default white)", 2D) = "white" {}
        [NoScaleOffset] _LowerBodyColorMap("Lower body color map (Default white)", 2D) = "white" {}
        _FrontFaceTintColor("Front face tint color (Default white)",COLOR) = (1 ,1 ,1)
        _BackFaceTintColor("Back face tint colo r(Default white)",COLOR) = (1 ,1 ,1)
        _Alpha("Alpha (Default 1)", Range(0 ,1)) = 1
        _AlphaClip("Alpha clip (Default 0.333)", Range(0 ,1)) = 0.333

        [Header(Light Map)]
        [NoScaleOffset] _HairLightMap("Hair light map (Default black)", 2D) = "black" {}
        [NoScaleOffset] _UpperBodyLightMap("Upper body light map (Default black)", 2D) = "black" {}
        [NoScaleOffset] _LowerBodyLightMap("Lower body light map (Default black)", 2D) = "black" {}

        [Header(Ramp Map)]
        [NoScaleOffset] _HairCoolRamp("Hair cool ramp (Default white)", 2D) = "white" {}
        [NoScaleOffset] _HairWarmRamp("Hair warm ramp (Default white)", 2D) = "white" {}
        [NoScaleOffset] _BodyCoolRamp("Body cool ramp (Default white)", 2D) = "white" {}
        [NoScaleOffset] _BodyWarmRamp("Body warm ramp (Default white)", 2D) = "white" {}

        [Header(Indirect Lighting)]
        _IndirectLightFlattenNormal("Indirect light flatten normal (Default 0)", Range(0 ,1)) = 0
        _IndirectLightUsage("Indirect light usage (Default 0.5)", Range(0 ,1)) = 0.5
        _IndirectLightOcclusionUsage("Indirect light occlusion usage (Default 0.5)", Range(0 ,1)) = 0.5
        _IndirectLightMixBaseColor("Indirect light mix base color (Default 1)", Range(0 ,1)) = 1

        [Header(Main Lighting)]
        _MainLightColorUsage("Main light color usage (Default 1)", Range(0 ,1)) = 1
        _ShadowThresholdCenter("Shadow threshold canter (Default 0)", Range(-1 ,1)) = 0
        _ShadowThresholdSoftness("Shadow threshold softness (Default 0.1)", Range(0 ,1)) = 0.1
        _ShadowRampOffset("Shadow ramp offset (Default 0.75)", Range(0 ,1)) = 0.75

        [Header(Face)]
        [NoScaleOffset] _FaceMap("Face map (Default black)",2D) = "black" {}
        _FaceShadowOffset("Face shadow offset (Default -0.01)", Range(-1, 1)) = -0.01
        _FaceShadowTransitionSoftness("Face shadow transition softness (Default 0.05)", Range(0, 1)) = 0.05

        [Header(Specular)]
        _SpecularExpon("Specular exponent (Default 50)", Range(1 ,128)) = 50
        _SpecularKsNonMetal("Specular Ks non_metal (Default 0.04)", Range(0, 1)) = 0.04
        _SpecularKsMetal("Specular Ks metal (Default 1)", Range(0, 1)) = 1
        _SpecularBrightness("Specular brightness (Default 1)", Range(0, 10)) = 1

        [Header(Stockings)]
        [NoScaleOffset] _UpperBodyStockings("Upper body stockings (Default black)",2D) = "black" {}
        [NoScaleOffset] _LowerBodyStockings("Lower body stockings (Default black)",2D) = "black" {}
        _StockingsDarkColor("Stockings dark color (Default black)", color) = (0 ,0 ,0)
        [HDR] _StockingsLightColor("Stockings light color (Default 1.8 ,1.48299 ,0.856821)", color) = (1.8 ,1.48299 ,0.856821)
        [HDR] _StockingsTransitionColor("Stockings transition color (Default 0.360381 ,0.242986 ,0.358131)", color) = (0.360381 ,0.242986 ,0.358131)
        _StockingsTransitionThreshold("Stockings transition threshold (Default 0.58)", Range(0, 1)) = 0.58
        _StockingsTransitionPower("Stockings transition power (Default 1)", Range(0.1, 50)) = 1
        _StockingsTransitionHardness("Stockings transition hardness (Default 0.4)", Range(0, 1)) = 0.4
        _StockingsTextureUsage("Stockings texture usage (Default 0.1)", Range(0, 1)) = 0.1

        [Header(Rim Lighting)]
        _RimLightWidth("Rim light width (Default 1)", Range(0, 10)) = 1
        _RimLightThreshold("Rim light threshold (Default 0.05)", Range(-1, 1)) = 0.05
        _RimLightFadeout("Rim light fadeout (Default 1)", Range(0.01, 1)) = 1
        [HDR] _RimLightTintColor("Rim light tint color (Default white)", color) = (1 ,1 ,1)
        _RimLightBrightness("Rim light brightness (Default 1)", Range(0, 10)) = 1
        _RimLightMixAlbedo("Rim light mix albedo (Default 0.9)", Range(0, 1)) = 0.9

        [Header(Emission)]
        [Toggle(_EMISSION_ON)] _UseEmission("Use emission (Default NO)",float) = 0
        _EmissionMixBaseColor("Emission mix base coloro (Default 1)", Range(0, 1)) = 1
        _EmissionTintColor("Emission tint coloro (Default white)", color) = (1 ,1 ,1)
        _EmissionIntensity("Emission intensity (Default 1)", Range(0, 100)) = 1

        [Header(Outline)]
        [Toggle(_OUTLINE_ON)] _UseOutline("Use outline(Default YES)",float) = 1
        [Toggle(_OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL)] _OutlineVertexColorSmoothNormal("Outline vertex color smooth normal(Default NO)",float) = 0
        _OutlineWidth("Outline width (Default 1)", Range(0, 10)) = 1
        _OutlineGamma("Outline gamma (Default 16)", Range(0, 255)) = 16

        [Header(Surface Options)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull (Default Back)",float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendMode("Src blend mode (Default One)",float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendMode("Dst blend mode (Default Zero)",float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend operation (Default Add)",float) = 0
        [Enum(Off, 0, On, 1)] _ZWrite("Cull (Default On)",float) = 1
        _StencilRef("Stencil reference (Default 0)", Range(0, 255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil comparison (Default disabled)",int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOp("Stencil pass operation (Default keep)",int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOp("Stencil fail operation (Default keep)",int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFailOp("Stencil Z fail operation (Default keep)",int) = 0

        [Header(Draw Overlay)]
        [Toggle(_DRAW_OVERLAY_ON)] _UseDrawOverlay("Use draw overlay (Default NO)",float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendModeOverlay("Src blend mode overlay (Default One)",float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendModeOverlay("Dst blend mode overlay (Default Zero)",float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOpOverlay("Blend operation overlay (Default Add)",float) = 0
        _StencilRefOverlay("Overlay pass stencil reference (Default 0)", Range(0, 255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilCompOverlay("Overlay pass stencil comparison (Default disabled)",int) = 0 

    }
    SubShader
    {
        LOD 100

        HLSLINCLUDE
        #pragma shader_feature_local _AREA_FACE
        #pragma shader_feature_local _AREA_HAIR
        #pragma shader_feature_local _AREA_UPPERBODY
        #pragma shader_feature_local _AREA_LOWERBODY
        #pragma shader_feature_local _OUTLINE_ON
        #pragma shader_feature_local _OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL
        #pragma shader_feature_local _DRAW_OVERLAY_ON
        #pragma shader_feature_local _EMISSION_ON
        ENDHLSL

        Pass
        {
            Name "ShadowCaster" 
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite [_ZWrite]
            ZTest LEqual
            ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            //------------------------
            //
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //-------------------------
            //GPU
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            //-------------------------
            //
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            ENDHLSL
        }

        Pass
       {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite [_ZWrite]
            ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            //------------------------
            //
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //-------------------------
            //GPU
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            ENDHLSL
        }

        Pass
       {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite [_ZWrite]
            Cull [_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            //------------------------
            //
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //-------------------------
            //GPU
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"

            ENDHLSL
        }

        Pass
       {
            Name "DrawCore"
            Tags
                {
                "RenderPipeline" = "UniversalPipeline"
                "RenderType" = "Opaque"
                }

            Cull [_Cull]
            Stencil
                {
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass [_StencilPassOp]
                Fail [_StencilFailOp]
                ZFail [_StencilZFailOp]
                }

            Blend [_SrcBlendMode] [_DstBlendMode]
            BlendOp [_BlendOp]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma multi_compile _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

            #include "SRUniversalInput.hlsl"
            #include "SRUniversalDrawCorePass.hlsl"

            ENDHLSL
        }

         Pass //Ã¼Ã«°ëÍ¸
       {
            Name "DrawOverlay"
            Tags
                {
                "RenderPipeline" = "UniversalPipeline"
                "RenderType" = "Opaque"
                "LightMode" = "UniversalForward"
                }

            Cull [_Cull]
            Stencil
                {
                Ref [_StencilRefOverlay]
                Comp [_StencilCompOverlay]
                }

            Blend [_SrcBlendModeOverlay] [_DstBlendModeOverlay]
            BlendOp [_BlendOpOverlay]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma multi_compile _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

            #if _DRAW_OVERLAY_ON
            #include "SRUniversalInput.hlsl"
            #include "SRUniversalDrawCorePass.hlsl"
            #else
            struct Attributes {};
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };
            Varyings vert(Attributes input)
            {
                return (Varyings)0;
            }
            float4 frag(Varyings input) : SV_TARGET
            {
                return 0;
            }
            
            #endif

            ENDHLSL
        }

        Pass //Ãè±ß
       {
            Name "DrawOutline"
            Tags
                {
                "RenderPipeline" = "UniversalPipeline"
                "RenderType" = "Opaque"
                "LightMode" = "UniversalForwardOnly"
                }

            Cull Front //ÕýÃæÌÞ³ý
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

            #if _OUTLINE_ON
            #include "SRUniversalInput.hlsl"
            #include "SRUniversalDrawOutlinePass.hlsl"
            #else
            struct Attributes {};
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };
            Varyings vert(Attributes input)
            {
                return (Varyings)0;
            }
            float4 frag(Varyings input) : SV_TARGET
            {
                return 0;
            }
            
            #endif

           ENDHLSL
        }

    }
}
