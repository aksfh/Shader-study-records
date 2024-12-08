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
    float3 normalWS               : TEXCOORD2; //法线
    float3 viewDirectionWS        : TEXCOORD3; //视角
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
        
float3 SampleGradient( Gradient Gradient, float Time) //这段抄的,反正能用,暂时没懂
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

float3 desaturation (float3 color ) //去饱和，降低主光源影响
{
    float3 grayXfer = float3 (0.3, 0.59, 0.11 ); //灰度因子是根据人的心理学测量出来的(?)
    float grayf = dot ( color, grayXfer );
    return float3 ( grayf, grayf, grayf );
}

Varyings vert ( Attributes  input)
{
    Varyings output = (Varyings) 0;
    
    VertexPositionInputs vertexInput = GetVertexPositionInputs ( input.positionOS );
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs ( input.normalOS, input.tangentOS );
    
    output.uv = TRANSFORM_TEX ( input.uv, _BaseMap );
    //打光向量
    output.positionWSAndFogFactor = float4 ( vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z )); //世界空间位置
    output.normalWS = vertexNormalInput.normalWS; //世界空间法线
    output.viewDirectionWS = unity_OrthoParams.w == 0 ? GetCameraPositionWS ( ) - vertexInput.positionWS : GetWorldToViewMatrix ( )[2].xyz; //世界相机向量/视线向量:正交向量
    output.SH = SampleSH ( lerp ( vertexNormalInput.normalWS, float3 ( 0, 0, 0 ), _IndirectLightFlattenNormal ) ); //间接光&环境光/球谐函数||压短法线降低高阶项影响
    output.positionCS = vertexInput.positionCS;
    
    return output;
}

float4 frag ( Varyings  input, bool isFrontFace : SV_IsFrontFace) : SV_TARGET
{
    float3 positionWS = input.positionWSAndFogFactor.xyz;
    float4 shadowCoord = TransformWorldToShadowCoord ( positionWS ); //获取投影坐标
    Light mainLight = GetMainLight ( shadowCoord ); //使用投影坐标获取主光源
    float3 LightDirectionWS = normalize ( mainLight.direction ); //获取世界坐标主光源向量
    
    float3 normalWS = normalize ( input.normalWS ); //归一化
    
    float3 viewDirectionWS = normalize ( input.viewDirectionWS ); //归一化
    
    
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
    
    float3 indirectLightColor = input.SH.rgb * _IndirectLightUsage; //球谐函数返回值/环境光漫反射模拟/亮度控制
    
    #if _AREA_HAIR || _AREA_UPPERBODY || _AREA_LOWERBODY //AO
    indirectLightColor *= lerp ( 1, lightMap.r, _IndirectLightOcclusionUsage);
    #else
    indirectLightColor *= lerp ( 1, lerp ( faceMap.g, 1, step ( faceMap.r, 0.5 ) ), _IndirectLightOcclusionUsage );
    #endif
    
    indirectLightColor *= lerp ( 1, baseColor, _IndirectLightMixBaseColor ); //球谐光混合基础颜色插值
    
    float3 mainLightColor = lerp (desaturation(mainLight.color), mainLight.color, _MainLightColorUsage ); //主光源颜色？插值光的色彩减弱影响
    
    float mainLightShadow = 1;
    
    int rampRowIndex = 0;
    int rampRowNum = 1;
    
    #if _AREA_HAIR || _AREA_UPPERBODY || _AREA_LOWERBODY
    {
        float NoL = dot(normalWS, LightDirectionWS);
        float remappedNoL = NoL * 0.5 + 0.5; //兰伯特光照
        mainLightShadow = smoothstep(1 - lightMap.g + _ShadowThresholdCenter - _ShadowThresholdSoftness, 1 - lightMap.g + _ShadowThresholdCenter + _ShadowThresholdSoftness , remappedNoL); //阴影细节&平滑
        mainLightShadow *= lightMap.r; //光照AO
    
        #if _AREA_HAIR //ramp图uv
            rampRowIndex = 0;
            rampRowNum = 1;
        #elif _AREA_UPPERBODY || _AREA_LOWERBODY //计算理论过程没看懂，抄上先了
            int rawIndex = (round((lightMap.a + 0.0425) / 0.0625) - 1) / 2;
            rampRowIndex = lerp(rawIndex, rawIndex + 4 < 8 ? rawIndex + 4 : rawIndex + 4 - 8, fmod(rawIndex, 2));
            rampRowNum = 8;
        #endif
    }
    #elif _AREA_FACE //脸部用距离场图做阴影
    {
        float3 headForward = normalize(_HeadForward); //头部前向量
        float3 headRight = normalize(_HeadRight); //头部右向量
        float3 headUp = cross(headForward, headRight); //头部上向量/前向量差乘右向量得到向上向量
    
        float3 fixedLightDirectionWS = normalize(LightDirectionWS - dot(LightDirectionWS, headUp) * headUp); //光向量投影到头坐标系水平面（不然人物颠倒阴影会反）
        float2 sdfUV =float2(sign(dot(fixedLightDirectionWS, headRight)), 1) * input.uv * float2(-1, 1); //光向量点乘右向量判断阴影左右方向,正数右负数左；sdf图方向左黑右白所以u坐标反向
        float sdfValue = tex2D(_FaceMap, sdfUV).a; //采样sdf图
        sdfValue += _FaceShadowOffset; //光照正背面光向量与右向量点乘为0，面部会被点亮，给点偏移值即可修复
    
        float sdfThreshold = 1 - (dot(fixedLightDirectionWS, headForward) * 0.5 + 0.5); //sdf阈值,正面0背面1，低阈值更亮
        float sdf = smoothstep(sdfThreshold - _FaceShadowTransitionSoftness, sdfThreshold + _FaceShadowTransitionSoftness, sdfValue); //比较，超过阈值点亮像素&平滑阴影
    
        mainLightShadow = lerp(faceMap.g, sdf, step(faceMap.r, 0.5)); //sdf遮罩外五官替换成AO，光照在脑后不会导致整张脸黑掉
    
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
    
    float isDay = LightDirectionWS.y * 0.5 + 0.5; //光向量竖坐标
    float3 rampColor = lerp ( coolRamp, warmRamp, isDay ); //插值冷暖ramp
    
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
    
        #if _AREA_UPPERBODY //细节纹理采样
            stockingsMapRG = tex2D(_UpperBodyStockings, input.uv).rg;
            stockingsMapB = tex2D(_UpperBodyStockings, input.uv * 20).b;
        #elif _AREA_LOWERBODY
            stockingsMapRG = tex2D(_LowerBodyStockings, input.uv).rg;
            stockingsMapB = tex2D(_LowerBodyStockings, input.uv * 20).b;
        #endif
    
        float NoV = dot(normalWS, viewDirectionWS); //法线点乘视角模拟皮肤透过黑丝
        float fac = NoV;
        fac = pow(saturate(fac), _StockingsTransitionPower); //幂运算调整亮区大小
        fac = saturate((fac - _StockingsTransitionHardness / 2) / (1 - _StockingsTransitionHardness)); //调整亮暗过度硬度
        fac = fac * (stockingsMapB * _StockingsTextureUsage + (1 - _StockingsTextureUsage)); //混入细节纹理
        fac = lerp(fac, 1, stockingsMapRG.g); //厚度插值亮区
        Gradient curve = GradientConstruct();
        curve.colorsLength = 3;
        curve.colors[0] = float4(_StockingsDarkColor, 0);
        curve.colors[1] = float4(_StockingsTransitionColor, _StockingsTransitionThreshold);
        curve.colors[2] = float4(_StockingsLightColor, 1);
        float3 stockingsColor = SampleGradient(curve, fac);
    
        stockingsEffect = lerp(1, stockingsColor, stockingsMapRG.r); //遮罩
    }
    #endif
    
    float linearEyeDepth = LinearEyeDepth (input.positionCS.z, _ZBufferParams ); //获取线性深度
    float3 normalVS = mul ( (float3x3) UNITY_MATRIX_V, normalWS ); //世界空间法线转到相机空间
    float2 uvOffset = float2 ( sign ( normalVS.x ), 0 ) * _RimLightWidth / (1 + linearEyeDepth) / 100; //法线横坐标采样uv偏移方向，乘偏移量,除深度，实现近粗远细
    int2 loadTexPos = input.positionCS.xy + uvOffset * _ScaledScreenParams.xy; //采样深度缓冲用的是屏幕空间坐标把uv偏移转换成坐标偏移
    loadTexPos = min ( max ( loadTexPos, 0 ), _ScaledScreenParams.xy - 1 ); //深度缓冲裁剪出界，坐标加上下界限制
    float offsetSceneDepth = LoadSceneDepth ( loadTexPos ); //深度缓冲采样偏移像素深度
    float offsetLinearEyeDepth = LinearEyeDepth ( offsetSceneDepth, _ZBufferParams ); //深度缓冲非线性，转换成线性
    float rimLight = saturate ( offsetLinearEyeDepth - (linearEyeDepth + _RimLightThreshold) ) / _RimLightFadeout; //两个深度做差,除一下减弱效果
    float3 rimLightColor = rimLight * mainLight.color.rgb;
    rimLightColor *= _RimLightTintColor; //边缘光颜色
    rimLightColor *= _RimLightBrightness; //边缘光亮度
    
    float3 emissionColor = 0; //眼睛高光发光
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
    
    #if _AREA_FACE && _OUTLINE_ON //鼻子描边
    {
        float fakeOutline = faceMap.b;
        float3 headForward = normalize(_HeadForward);                                                        //描边随视角变化
        fakeOutlineEffect = smoothstep(0.0, 0.25, pow(saturate(dot(headForward, viewDirectionWS)), 20) * fakeOutline); //前向量点乘视角向量，幂降低可视范围，再抬高权重
    
        float2 outlineUV = float2(0, 0.0625);
        float3 coolRamp = tex2D(_BodyCoolRamp, outlineUV).rgb; //Outline里面的皮肤描边颜色
        float3 warmRamp = tex2D(_BodyWarmRamp, outlineUV).rgb;
        float3 ramp = lerp ( coolRamp, warmRamp, 0.5 ); //冷暖各取一半
        fakeOutlineColor = pow(ramp, _OutlineGamma);
    }
    #endif
    
    
    
    
    

    float3 albedo = 0;
    albedo += indirectLightColor;
    albedo += mainLightColor;
    albedo += specularColor;
    albedo *= stockingsEffect;
    albedo += rimLightColor * lerp ( 1, albedo, _RimLightMixAlbedo );
    albedo += emissionColor; //贴图有问题缺少a通道的高光图，所以此行暂时没有效果
    //albedo = lerp ( albedo, fakeOutlineColor, fakeOutlineEffect ); //不知道贴图问题还是写的有问题，部分角度鼻子描边会出现暗块，耳朵部分也会被影响，八成贴图问题但是找不到其他可以替换贴图
    
    
    float alpha = _Alpha;
    
    #if _DRAW_OVERLAY_ON //控制眉毛透明不会透到背面 ps：官方做法是脸里面放面片直接挡住
    {
        float3 headForward = normalize(_HeadForward);
        alpha = lerp(1, alpha, saturate(dot(headForward, viewDirectionWS))); //前向量点乘视角向量,越小alpha越接近1
    }
    #endif
        
    float4 color = float4 ( albedo, alpha );
    clip ( color.a - _AlphaClip ); //补alpha剔除
    color.rgb = MixFog ( color.rgb, input.positionWSAndFogFactor.w );
    return color;
}