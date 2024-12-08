struct Attributes
{
    float3 positionOS  : POSITION;
    half3 normalOS     : NORMAL;
    half4 tangentOS    : TANGENT;
    float2 uv          : TEXCOORD0;
};

struct Varyings
{
    float2 uv                     : TEXCOORD0;
    float4 positionWSAndFogFactor : TEXCOORD1;
    float3 normalWS               : TEXCOORD2; //����
    float3 viewDirectionWS        : TEXCOORD3; //�ӽ�
    float3 SH                     : TEXCOORD4;
    float4 positionCS             : SV_POSITION;
};

struct Gradient
{
    int colorsLength;
    float4 colors[8];
};

Gradient GradientConstruct ( )
{
    Gradient g;
    g.colorsLength = 2;
    g.colors[0] = float4 ( 1, 1, 1, 0 );
    g.colors[1] = float4 ( 1, 1, 1, 1 );
    g.colors[2] = float4 ( 0, 0, 0, 0 );
    g.colors[3] = float4 ( 1, 1, 1, 3 );
    g.colors[4] = float4 ( 1, 1, 1, 4 );
    g.colors[5] = float4 ( 1, 1, 1, 5 );
    g.colors[6] = float4 ( 1, 1, 1, 6 );
    g.colors[7] = float4 ( 1, 1, 1, 7 );
    return g;

}

// Graph Functions
        
float3 SampleGradient( Gradient Gradient, float Time) //��γ���,��������,��ʱû��
{
    float3 color = Gradient.colors[0].rgb;
    for (int c = 1; c < Gradient.colorsLength; c++)
    {
        float colorPos = saturate ( (Time - Gradient.colors[c - 1].w) / (Gradient.colors[c].w - Gradient.colors[c - 1].w) ) * step ( c, Gradient.colorsLength - 1 );
        color = lerp ( color, Gradient.colors[c].rgb, colorPos );
    }
    #ifdef UNITY_COLORSPACE_GAMMA
        color = LinearToSRGB(color);
    #endif
    return color;

}

float3 desaturation (float3 color ) //ȥ���ͣ���������ԴӰ��
{
    float3 grayXfer = float3 (0.3, 0.59, 0.11 ); //�Ҷ������Ǹ����˵�����ѧ����������(?)
    float grayf = dot ( color, grayXfer );
    return float3 ( grayf, grayf, grayf );
}

Varyings vert ( Attributes  input)
{
    Varyings output = (Varyings) 0;
    
    VertexPositionInputs vertexInput = GetVertexPositionInputs ( input.positionOS );
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs ( input.normalOS, input.tangentOS );
    
    output.uv = TRANSFORM_TEX ( input.uv, _BaseMap );
    //�������
    output.positionWSAndFogFactor = float4 ( vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z )); //����ռ�λ��
    output.normalWS = vertexNormalInput.normalWS; //����ռ䷨��
    output.viewDirectionWS = unity_OrthoParams.w == 0 ? GetCameraPositionWS ( ) - vertexInput.positionWS : GetWorldToViewMatrix ( )[2].xyz; //�����������/��������:��������
    output.SH = SampleSH ( lerp ( vertexNormalInput.normalWS, float3 ( 0, 0, 0 ), _IndirectLightFlattenNormal ) ); //��ӹ�&������/��г����||ѹ�̷��߽��͸߽���Ӱ��
    output.positionCS = vertexInput.positionCS;
    
    return output;
}

float4 frag ( Varyings  input, bool isFrontFace : SV_IsFrontFace) : SV_TARGET
{
    float3 positionWS = input.positionWSAndFogFactor.xyz;
    float4 shadowCoord = TransformWorldToShadowCoord ( positionWS ); //��ȡͶӰ����
    Light mainLight = GetMainLight ( shadowCoord ); //ʹ��ͶӰ�����ȡ����Դ
    float3 LightDirectionWS = normalize ( mainLight.direction ); //��ȡ������������Դ����
    
    float3 normalWS = normalize ( input.normalWS ); //��һ��
    
    float3 viewDirectionWS = normalize ( input.viewDirectionWS ); //��һ��
    
    
    float3 baseColor = tex2D ( _BaseMap, input.uv );
    float4 areaMap = 0;
    #if _AREA_FACE
        areaMap = tex2D(_FaceColorMap, input.uv);
    #elif _AREA_HAIR
        areaMap = tex2D(_HairColorMap, input.uv);
    #elif _AREA_UPPERBODY
        areaMap = tex2D(_UpperBodyColorMap, input.uv);
    #elif _AREA_LOWERBODY
        areaMap = tex2D(_LowerBodyColorMap, input.uv);
    #endif
    
    baseColor = areaMap.rgb;
    baseColor *= lerp ( _BackFaceTintColor, _FrontFaceTintColor, isFrontFace );
    
    float4 lightMap = 0;
    #if _AREA_HAIR || _AREA_UPPERBODY || _AREA_LOWERBODY
    {
        #if _AREA_HAIR
            lightMap = tex2D(_HairLightMap, input.uv);
        #elif _AREA_UPPERBODY
            lightMap = tex2D(_UpperBodyLightMap, input.uv);
        #elif _AREA_LOWERBODY
            lightMap = tex2D(_LowerBodyLightMap, input.uv);
        #endif
    }
    #endif
    float4 faceMap = 0;
    #if _AREA_FACE
        faceMap = tex2D(_FaceMap, input.uv);
    #endif
    
    float3 indirectLightColor = input.SH.rgb * _IndirectLightUsage; //��г��������ֵ/������������ģ��/���ȿ���
    
    #if _AREA_HAIR || _AREA_UPPERBODY || _AREA_LOWERBODY //AO
    indirectLightColor *= lerp ( 1, lightMap.r, _IndirectLightOcclusionUsage);
    #else
    indirectLightColor *= lerp ( 1, lerp ( faceMap.g, 1, step ( faceMap.r, 0.5 ) ), _IndirectLightOcclusionUsage );
    #endif
    
    indirectLightColor *= lerp ( 1, baseColor, _IndirectLightMixBaseColor ); //��г���ϻ�����ɫ��ֵ
    
    float3 mainLightColor = lerp (desaturation(mainLight.color), mainLight.color, _MainLightColorUsage ); //����Դ��ɫ����ֵ���ɫ�ʼ���Ӱ��
    
    float mainLightShadow = 1;
    
    int rampRowIndex = 0;
    int rampRowNum = 1;
    
    #if _AREA_HAIR || _AREA_UPPERBODY || _AREA_LOWERBODY
    {
        float NoL = dot(normalWS, LightDirectionWS);
        float remappedNoL = NoL * 0.5 + 0.5; //�����ع���
        mainLightShadow = smoothstep(1 - lightMap.g + _ShadowThresholdCenter - _ShadowThresholdSoftness, 1 - lightMap.g + _ShadowThresholdCenter + _ShadowThresholdSoftness , remappedNoL); //��Ӱϸ��&ƽ��
        mainLightShadow *= lightMap.r; //����AO
    
        #if _AREA_HAIR //rampͼuv
            rampRowIndex = 0;
            rampRowNum = 1;
        #elif _AREA_UPPERBODY || _AREA_LOWERBODY //�������۹���û��������������
            int rawIndex = (round((lightMap.a + 0.0425) / 0.0625) - 1) / 2;
            rampRowIndex = lerp(rawIndex, rawIndex + 4 < 8 ? rawIndex + 4 : rawIndex + 4 - 8, fmod(rawIndex, 2));
            rampRowNum = 8;
        #endif
    }
    #elif _AREA_FACE //�����þ��볡ͼ����Ӱ
    {
        float3 headForward = normalize(_HeadForward); //ͷ��ǰ����
        float3 headRight = normalize(_HeadRight); //ͷ��������
        float3 headUp = cross(headForward, headRight); //ͷ��������/ǰ��������������õ���������
    
        float3 fixedLightDirectionWS = normalize(LightDirectionWS - dot(LightDirectionWS, headUp) * headUp); //������ͶӰ��ͷ����ϵˮƽ�棨��Ȼ����ߵ���Ӱ�ᷴ��
        float2 sdfUV =float2(sign(dot(fixedLightDirectionWS, headRight)), 1) * input.uv * float2(-1, 1); //����������������ж���Ӱ���ҷ���,�����Ҹ�����sdfͼ��������Ұ�����u���귴��
        float sdfValue = tex2D(_FaceMap, sdfUV).a; //����sdfͼ
        sdfValue += _FaceShadowOffset; //��������������������������Ϊ0���沿�ᱻ����������ƫ��ֵ�����޸�
    
        float sdfThreshold = 1 - (dot(fixedLightDirectionWS, headForward) * 0.5 + 0.5); //sdf��ֵ,����0����1������ֵ����
        float sdf = smoothstep(sdfThreshold - _FaceShadowTransitionSoftness, sdfThreshold + _FaceShadowTransitionSoftness, sdfValue); //�Ƚϣ�������ֵ��������&ƽ����Ӱ
    
        mainLightShadow = lerp(faceMap.g, sdf, step(faceMap.r, 0.5)); //sdf����������滻��AO���������Ժ󲻻ᵼ���������ڵ�
    
        rampRowIndex = 0;
        rampRowNum = 8;
    }
    #endif
    
    float rampUVx = mainLightShadow * (1 - _ShadowRampOffset) + _ShadowRampOffset;
    float rampUVy = (2 * rampRowIndex + 1) * (1.0 / (rampRowNum * 2));
    float2 rampUV = float2 ( rampUVx, rampUVy);
    float3 coolRamp = 1;
    float3 warmRamp = 1;
    
    #if _AREA_HAIR
        coolRamp = tex2D(_HairCoolRamp, rampUV).rgb;
        warmRamp = tex2D(_HairWarmRamp, rampUV).rgb;
    #elif _AREA_FACE || _AREA_UPPERBODY || _AREA_LOWERBODY
        coolRamp = tex2D(_BodyCoolRamp, rampUV).rgb;
        warmRamp = tex2D(_BodyWarmRamp, rampUV).rgb;
    #endif
    
    float isDay = LightDirectionWS.y * 0.5 + 0.5; //������������
    float3 rampColor = lerp ( coolRamp, warmRamp, isDay ); //��ֵ��ůramp
    
    mainLightColor *= baseColor * rampColor;
    
    float3 specularColor = 0;
    
    #if _AREA_HAIR || _AREA_UPPERBODY || _AREA_LOWERBODY
    {
        float3 halfVectorWS = normalize(viewDirectionWS + LightDirectionWS);
        float NoH = dot(normalWS,halfVectorWS);
        float blinnPhong = pow(saturate(NoH), _SpecularExpon);
    
        float nonMetalSpecular = step(1.04 - blinnPhong, lightMap.b) * _SpecularKsNonMetal;
        float metalSpecular = blinnPhong * lightMap.b * _SpecularKsMetal;
    
        float metallic =0;
        #if _AREA_UPPERBODY || _AREA_LOWERBODY
            metallic = saturate((abs(lightMap.a - 0.52) - 0.1) / (0 - 0.1));
        #endif
    
        specularColor = lerp(nonMetalSpecular, metalSpecular * baseColor, metallic);
        specularColor *= mainLight.color;
        specularColor *= _SpecularBrightness;
    }
    #endif
    
    float3 stockingsEffect = 1;
    
     #if _AREA_UPPERBODY || _AREA_LOWERBODY
    {
        float2 stockingsMapRG = 0;
        float stockingsMapB = 0;
    
        #if _AREA_UPPERBODY //ϸ���������
            stockingsMapRG = tex2D(_UpperBodyStockings, input.uv).rg;
            stockingsMapB = tex2D(_UpperBodyStockings, input.uv * 20).b;
        #elif _AREA_LOWERBODY
            stockingsMapRG = tex2D(_LowerBodyStockings, input.uv).rg;
            stockingsMapB = tex2D(_LowerBodyStockings, input.uv * 20).b;
        #endif
    
        float NoV = dot(normalWS, viewDirectionWS); //���ߵ���ӽ�ģ��Ƥ��͸����˿
        float fac = NoV;
        fac = pow(saturate(fac), _StockingsTransitionPower); //���������������С
        fac = saturate((fac - _StockingsTransitionHardness / 2) / (1 - _StockingsTransitionHardness)); //������������Ӳ��
        fac = fac * (stockingsMapB * _StockingsTextureUsage + (1 - _StockingsTextureUsage)); //����ϸ������
        fac = lerp(fac, 1, stockingsMapRG.g); //��Ȳ�ֵ����
        Gradient curve = GradientConstruct();
        curve.colorsLength = 3;
        curve.colors[0] = float4(_StockingsDarkColor, 0);
        curve.colors[1] = float4(_StockingsTransitionColor, _StockingsTransitionThreshold);
        curve.colors[2] = float4(_StockingsLightColor, 1);
        float3 stockingsColor = SampleGradient(curve, fac);
    
        stockingsEffect = lerp(1, stockingsColor, stockingsMapRG.r); //����
    }
    #endif
    
    float linearEyeDepth = LinearEyeDepth (input.positionCS.z, _ZBufferParams ); //��ȡ�������
    float3 normalVS = mul ( (float3x3) UNITY_MATRIX_V, normalWS ); //����ռ䷨��ת������ռ�
    float2 uvOffset = float2 ( sign ( normalVS.x ), 0 ) * _RimLightWidth / (1 + linearEyeDepth) / 100; //���ߺ��������uvƫ�Ʒ��򣬳�ƫ����,����ȣ�ʵ�ֽ���Զϸ
    int2 loadTexPos = input.positionCS.xy + uvOffset * _ScaledScreenParams.xy; //������Ȼ����õ�����Ļ�ռ������uvƫ��ת��������ƫ��
    loadTexPos = min ( max ( loadTexPos, 0 ), _ScaledScreenParams.xy - 1 ); //��Ȼ���ü����磬��������½�����
    float offsetSceneDepth = LoadSceneDepth ( loadTexPos ); //��Ȼ������ƫ���������
    float offsetLinearEyeDepth = LinearEyeDepth ( offsetSceneDepth, _ZBufferParams ); //��Ȼ�������ԣ�ת��������
    float rimLight = saturate ( offsetLinearEyeDepth - (linearEyeDepth + _RimLightThreshold) ) / _RimLightFadeout; //�����������,��һ�¼���Ч��
    float3 rimLightColor = rimLight * mainLight.color.rgb;
    rimLightColor *= _RimLightTintColor; //��Ե����ɫ
    rimLightColor *= _RimLightBrightness; //��Ե������
    
    float3 emissionColor = 0; //�۾��߹ⷢ��
    #if EMISSION_ON
    {
        emissionColor = areaMap.a;
        emissionColor *= lerp(1, baseColor, _EmissionMixBaseColor );
        emissionColor *= _EmissionTintColor;
        emissionColor *= _EmissionIntensity;
    }
    #endif
    
    float fakeOutlineEffect = 0;
    float3 fakeOutlineColor = 0;
    
    #if _AREA_FACE && _OUTLINE_ON //�������
    {
        float fakeOutline = faceMap.b;
        float3 headForward = normalize(_HeadForward);                                                        //������ӽǱ仯
        fakeOutlineEffect = smoothstep(0.0, 0.25, pow(saturate(dot(headForward, viewDirectionWS)), 20) * fakeOutline); //ǰ��������ӽ��������ݽ��Ϳ��ӷ�Χ����̧��Ȩ��
    
        float2 outlineUV = float2(0, 0.0625);
        float3 coolRamp = tex2D(_BodyCoolRamp, outlineUV).rgb; //Outline�����Ƥ�������ɫ
        float3 warmRamp = tex2D(_BodyWarmRamp, outlineUV).rgb;
        float3 ramp = lerp ( coolRamp, warmRamp, 0.5 ); //��ů��ȡһ��
        fakeOutlineColor = pow(ramp, _OutlineGamma);
    }
    #endif
    
    
    
    
    

    float3 albedo = 0;
    albedo += indirectLightColor;
    albedo += mainLightColor;
    albedo += specularColor;
    albedo *= stockingsEffect;
    albedo += rimLightColor * lerp ( 1, albedo, _RimLightMixAlbedo );
    albedo += emissionColor; //��ͼ������ȱ��aͨ���ĸ߹�ͼ�����Դ�����ʱû��Ч��
    //albedo = lerp ( albedo, fakeOutlineColor, fakeOutlineEffect ); //��֪����ͼ���⻹��д�������⣬���ֽǶȱ�����߻���ְ��飬���䲿��Ҳ�ᱻӰ�죬�˳���ͼ���⵫���Ҳ������������滻��ͼ
    
    
    float alpha = _Alpha;
    
    #if _DRAW_OVERLAY_ON //����üë͸������͸������ ps���ٷ����������������Ƭֱ�ӵ�ס
    {
        float3 headForward = normalize(_HeadForward);
        alpha = lerp(1, alpha, saturate(dot(headForward, viewDirectionWS))); //ǰ��������ӽ�����,ԽСalphaԽ�ӽ�1
    }
    #endif
        
    float4 color = float4 ( albedo, alpha );
    clip ( color.a - _AlphaClip ); //��alpha�޳�
    color.rgb = MixFog ( color.rgb, input.positionWSAndFogFactor.w );
    return color;
}