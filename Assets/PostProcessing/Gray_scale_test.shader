Shader "Hidden/Custom/Grayscale"
{
    HLSLINCLUDE

        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
        float _Blend;
        float noise3D(in float3 p){
    
            // Just some float3 figures, analogous to stride. You can change this, if you want.
	        float3 s = float3(113, 157, 1);
	
	        float3 ip = floor(p); // Unique unit cell ID.
    
            // Setting up the stride vector for randomization and interpolation, kind of. 
            // All kinds of shortcuts are taken here. Refer to IQ's original formula.
            float4 h = float4(0., s.yz, s.y + s.z) + dot(ip, s);
    
	        p -= ip; // Cell's fractional component.
	
            // A bit of cubic smoothing, to give the noise that rounded look.
            p = p*p*(3. - 2.*p);
    
            // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
            // then interpolating along X. There are countless ways to randomize, but this is
            // the way most are familar with: fract(sin(x)*largeNumber).
            h = lerp(frac(sin(h)*43758.5453), frac(sin(h + s.x)*43758.5453), p.x);
	
            // Interpolating along Y.
            h.xy = lerp(h.xz, h.yw, p.y);
    
            // Interpolating along Z, and returning the 3D noise value.
            return lerp(h.x, h.y, p.z); // Range: [0, 1].
	
        }

        float getMist(in float3 rd){

            float mist = 0.;
    
            //ro -= vec3(0, 0, iTime*3.);
    
            float t0 = 0.;
            float FAR = 80;
            float3 ro = _WorldSpaceCameraPos;
            ro.z = _Time.y*1.5;

            float3 lp = float3(FAR*.25, FAR*.25, FAR) + float3(0, 0, ro.z);
            
    
            for (int i = 0; i<24; i++){
        
                // If we reach the surface, don't accumulate any more values.
                //if (t0>t) break; 
        
                // Lighting. Technically, a lot of these points would be
                // shadowed, but we're ignoring that.
                float sDi = length(lp-ro)/FAR; 
	            float sAtt = 1./(1. + sDi*0.25);
	    
                // Noise layer.
                float3 ro2 = (ro + rd*t0)*2.5;
                float c = noise3D(ro2)*0.65 + noise3D(ro2*3.0)*0.25 + noise3D(ro2*9.0)*0.1;
                //float c = noise3D(ro2)*.65 + noise3D(ro2*4.)*.35; 

                float n = c;//max(.65-abs(c - .5)*2., 0.);//smoothstep(0., 1., abs(c - .5)*2.);
                mist += n*sAtt;
        
                // Advance the starting point towards the hit point. You can 
                // do this with constant jumps (FAR/8., etc), but I'm using
                // a variable jump here, because it gave me the aesthetic 
                // results I was after.
                t0 += clamp(c*.25, 0.1, 1.0);
        
            }
    
            // Add a little noise, then clamp, and we're done.
            return max(mist/48., 0.);
    
            // A different variation (float n = (c. + 0.);)
            //return smoothstep(.05, 1., mist/32.);

        }
        float2 path(in float z){ 
    
            return float2(4.*sin(z * 0.1), 0);
        }
        /*
        float trace(in float3 ro, in float3 rd){

            float t = 0.0;
            float h = 0.0;

            float FAR = _ProjectionParams.z;
    
            for(int i=0; i<96; i++){
    
                h = map(ro + rd*t);
                // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
                // "t" increases. It's a cheap trick that works in most situations... Not all, though.
                if(abs(h)<0.001*(t*.125 + 1.) || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
                t += h; 
            }

            return min(t, FAR);
        }*/

        float4 Frag(VaryingsDefault i) : SV_Target
        {

                
            // Calculate the view direction from the camera to this fragment
            float3 ro = _WorldSpaceCameraPos;
            float3 lookAt = ro + float3(0, -0.15, 0.5);
            //(fragCoord - iResolution.xy*.5)/iResolution.y;
            //float2 u = (i.texcoord.xy - _ScreenParams.xy* 0.5)/ _ScreenParams.y;
            float2 u = i.texcoord.xy;
            ro.xy += path(ro.z);
	        lookAt.xy += path(lookAt.z);

            float FOV = 3.14159265/2.5; // FOV - Field of view.
            float3 forward = normalize(lookAt - ro);
            float3 right = normalize(float3(forward.z, 0, -forward.x )); 
            float3 up = cross(forward, right);

            float3 rd = normalize(forward + FOV*u.x*right + FOV*u.y*up);

            float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
            //float3 my_coor = _WorldSpaceCameraPos;
            //float FAR = _ProjectionParams.z;
            

            float dust = getMist(rd)*(-rd.y+1.0);
            //float3 dust_color =float3( 0.9,0.6,0.1);
            float3 dust_color =float3( 0.8,0.5,0.1);

            color.rgb = color.rgb* 0.75 + (color.rgb + 0.25 * float3(1.2, 1, 0.9)) * dust_color * dust * 4;

            //float luminance = dot(color.rgb, float3(0.2126729, 0.7151522, 0.0721750));
            //color.rgb = lerp(color.rgb, luminance.xxx, _Blend.xxx);
            
            return color;
        }

    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDefault
                #pragma fragment Frag

            ENDHLSL
        }
    }
}