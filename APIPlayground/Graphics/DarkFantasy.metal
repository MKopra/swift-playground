#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float time;
    float2 resolution;
    float2 cameraRotation;
};

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + float2(1,0)), f.x),
               mix(hash(i + float2(0,1)), hash(i + float2(1,1)), f.x), f.y);
}

float fbm(float2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// ============================================================================
// ARCH GEOMETRY (Fixed frame - no parallax)
// ============================================================================

constant float PILLAR_WIDTH = 0.11;
constant float PILLAR_INNER_X = 0.13;
constant float ARCH_TOP_Y = 0.22;
constant float PILLAR_BOTTOM = -0.55;

bool insideArchOpening(float2 p) {
    if (p.y < PILLAR_BOTTOM) return false;
    if (abs(p.x) > PILLAR_INNER_X) return false;
    if (p.y <= ARCH_TOP_Y) return true;
    float2 archCenter = float2(0.0, ARCH_TOP_Y);
    return length(p - archCenter) < PILLAR_INNER_X;
}

bool insideArchStone(float2 p) {
    float outerX = PILLAR_INNER_X + PILLAR_WIDTH;
    float archThickness = PILLAR_WIDTH;

    if (p.x < -PILLAR_INNER_X && p.x > -outerX && p.y < ARCH_TOP_Y && p.y > PILLAR_BOTTOM) {
        return true;
    }
    if (p.x > PILLAR_INNER_X && p.x < outerX && p.y < ARCH_TOP_Y && p.y > PILLAR_BOTTOM) {
        return true;
    }
    if (p.y > ARCH_TOP_Y - 0.02) {
        float2 archCenter = float2(0.0, ARCH_TOP_Y);
        float dist = length(p - archCenter);
        if (dist > PILLAR_INNER_X && dist < PILLAR_INNER_X + archThickness) {
            return true;
        }
    }
    return false;
}

// ============================================================================
// PARALLAX DEPTH FACTORS - POV looking AT the arch
// We're standing back looking at this scene - closer objects move MORE
// Lower = further away (moves less), Higher = closer (moves more)
// ============================================================================

constant float DEPTH_DEEP_SPACE = 0.01;    // Distant stars barely move
constant float DEPTH_NEBULA_DEEP = 0.015;  // Deepest nebula layer
constant float DEPTH_NEBULA_MID = 0.025;   // Middle nebula layer
constant float DEPTH_NEBULA_CLOSE = 0.035; // Closest nebula layer
constant float DEPTH_STARS = 0.02;         // Star field
constant float DEPTH_COSMIC_ARC = 0.04;    // Cosmic arc (inside portal)
constant float DEPTH_MOON = 0.05;          // Moon
constant float DEPTH_MOUNTAINS_FAR = 0.05;   // Background mountains (furthest)
constant float DEPTH_MOUNTAINS_MID = 0.065;  // Mid mountains
constant float DEPTH_MOUNTAINS = 0.08;       // Foreground mountains (closest)
constant float DEPTH_PATH = 0.09;          // Ground/path inside
constant float DEPTH_FIGURE = 0.11;        // Figure
constant float DEPTH_ARCH = 0.14;          // Arch frame (closest to viewer)

// Pan limits - TIGHT to prevent looking past edges
constant float MAX_PAN = 0.15;

// ============================================================================
// LAYER RENDERING FUNCTIONS
// ============================================================================

// Layer 1: Deep space - MANDY STYLE (black + neon pink/purple)
// Render layered nebula with parallax - call this multiple times with different UVs
float3 renderNebulaLayer(float2 uv, float time, int layer) {
    float3 col = float3(0.0);

    // Each layer has different characteristics
    float layerOffset = float(layer) * 100.0;
    float layerScale = 2.0 + float(layer) * 0.5;  // Deeper layers = larger scale
    float layerIntensity = 0.4 - float(layer) * 0.08;  // Deeper = dimmer

    // Flowing nebula gas using FBM
    float nebula1 = fbm(uv * layerScale + time * 0.003 + layerOffset);
    float nebula2 = fbm(uv * (layerScale * 1.5) + time * 0.005 + layerOffset + 50.0);
    float nebula3 = fbm(uv * (layerScale * 0.7) - time * 0.002 + layerOffset + 100.0);

    // Combine for wispy, flowing effect
    float nebulaShape = nebula1 * 0.5 + nebula2 * 0.3 + nebula3 * 0.2;

    // Threshold to create gaps of black void
    nebulaShape = smoothstep(0.35, 0.65, nebulaShape);

    // Color based on layer depth - deeper = more purple, closer = more pink
    float3 layerColor;
    if (layer == 0) {
        // Closest layer - hot pink/magenta
        layerColor = mix(float3(1.0, 0.1, 0.5), float3(0.9, 0.2, 0.6), nebula2);
    } else if (layer == 1) {
        // Mid layer - purple/magenta blend
        layerColor = mix(float3(0.7, 0.1, 0.8), float3(0.5, 0.05, 0.9), nebula1);
    } else {
        // Deep layer - deep purple/blue
        layerColor = mix(float3(0.4, 0.05, 0.7), float3(0.2, 0.1, 0.5), nebula3);
    }

    // Radial falloff from center - nebula concentrated in middle
    float2 center = float2(0.0, 0.1);
    float radialDist = length(uv - center);
    float radialFade = 1.0 - smoothstep(0.1, 0.4, radialDist);

    col = layerColor * nebulaShape * layerIntensity * radialFade;

    return col;
}

float3 renderDeepSpace(float2 uv, float time, bool isOutside) {
    // === DEEP BLACK VOID ===
    float3 col = float3(0.01, 0.005, 0.015);

    // === STARS - rendered first, behind nebula ===
    for (int i = 0; i < 100; i++) {
        float fi = float(i);
        float px = fract(sin(fi * 73.156 + 17.32) * 43758.5453) * 2.0 - 1.0;
        float py = fract(sin(fi * 157.93 + 89.47) * 28461.2391) * 1.4 - 0.6;
        float2 starPos = float2(px, py);
        float starDist = length(uv - starPos);
        float starSize = 0.0006 + fract(sin(fi * 293.7) * 18927.4) * 0.001;
        float starBright = 0.5 + fract(sin(fi * 547.2) * 36742.8) * 0.5;
        float twinkle = 0.85 + 0.15 * sin(time * 1.0 + fi * 0.5);
        float star = smoothstep(starSize, 0.0, starDist) * starBright * twinkle;
        col += float3(0.95, 0.92, 1.0) * star;
    }

    return col;
}

// New function for layered nebula with parallax
float3 renderNebulaParallax(float2 uvLayer0, float2 uvLayer1, float2 uvLayer2, float time) {
    float3 col = float3(0.0);

    // === LAYER 2 (deepest, slowest parallax) - deep purple ===
    float deep1 = fbm(uvLayer2 * 1.8 + time * 0.002);
    float deep2 = fbm(uvLayer2 * 2.5 - time * 0.003 + 50.0);
    float deepShape = deep1 * 0.6 + deep2 * 0.4;
    deepShape = smoothstep(0.3, 0.7, deepShape);
    float2 deepCenter = float2(0.0, 0.12);
    float deepFade = 1.0 - smoothstep(0.08, 0.35, length(uvLayer2 - deepCenter));
    float3 deepColor = mix(float3(0.25, 0.02, 0.5), float3(0.15, 0.05, 0.35), deep2);
    col += deepColor * deepShape * 0.35 * deepFade;

    // === LAYER 1 (middle) - purple/magenta ===
    float mid1 = fbm(uvLayer1 * 2.2 + time * 0.004 + 100.0);
    float mid2 = fbm(uvLayer1 * 3.0 + time * 0.005 + 150.0);
    float midShape = mid1 * 0.5 + mid2 * 0.5;
    midShape = smoothstep(0.35, 0.68, midShape);
    float2 midCenter = float2(-0.02, 0.10);
    float midFade = 1.0 - smoothstep(0.06, 0.28, length(uvLayer1 - midCenter));
    float3 midColor = mix(float3(0.6, 0.08, 0.75), float3(0.45, 0.04, 0.85), mid1);
    col += midColor * midShape * 0.45 * midFade;

    // === LAYER 0 (closest, fastest parallax) - hot pink ===
    float close1 = fbm(uvLayer0 * 2.8 + time * 0.006 + 200.0);
    float close2 = fbm(uvLayer0 * 3.5 - time * 0.004 + 250.0);
    float closeShape = close1 * 0.55 + close2 * 0.45;
    closeShape = smoothstep(0.38, 0.72, closeShape);
    float2 closeCenter = float2(0.02, 0.08);
    float closeFade = 1.0 - smoothstep(0.04, 0.22, length(uvLayer0 - closeCenter));
    float3 closeColor = mix(float3(1.0, 0.12, 0.5), float3(0.85, 0.08, 0.55), close2);
    col += closeColor * closeShape * 0.55 * closeFade;

    // === BRIGHT CORE - small glowing center ===
    float2 corePos = float2(0.0, 0.10);
    float coreDist = length(uvLayer0 - corePos);
    float core = exp(-coreDist * 40.0) * 0.8;
    col += float3(1.0, 0.85, 0.92) * core;

    // Soft glow around core
    float coreGlow = exp(-coreDist * 15.0) * 0.25;
    col += float3(0.95, 0.5, 0.7) * coreGlow;

    return col;
}

// Render environment OUTSIDE the arch - MATCHES INSIDE exactly
float3 renderOuterEnvironment(float2 skyUV, float2 groundUV, float2 mountainUV, float time,
                               float2 nebulaClose, float2 nebulaMid, float2 nebulaDeep) {
    float3 col = float3(0.0);

    // Same mountain base as inside
    float mountainBase = -0.40;
    float mx = mountainUV.x;

    // === MOUNTAINS (same as inside - render at all x positions) ===
    // Extend mountains further to the sides for outer environment
    float leftSpire1 = 0.26 * max(0.0, 1.0 - abs(mx + 0.05) * 8.0);   // Wider reach
    float leftSpire2 = 0.20 * max(0.0, 1.0 - abs(mx + 0.02) * 9.0);
    float leftSpire3 = 0.18 * max(0.0, 1.0 - abs(mx + 0.085) * 7.0);
    float leftSpire4 = 0.14 * max(0.0, 1.0 - abs(mx + 0.11) * 8.0);
    float rightSlope1 = 0.12 * max(0.0, 1.0 - abs(mx - 0.03) * 7.0);
    float rightSlope2 = 0.10 * max(0.0, 1.0 - abs(mx - 0.07) * 7.5);
    float rightSlope3 = 0.08 * max(0.0, 1.0 - abs(mx - 0.10) * 8.0);

    // Additional far peaks for outer areas
    float farLeft = 0.12 * max(0.0, 1.0 - abs(mx + 0.20) * 5.0);
    float farRight = 0.10 * max(0.0, 1.0 - abs(mx - 0.18) * 5.0);

    float leftHeight = max(max(leftSpire1, leftSpire2), max(leftSpire3, leftSpire4));
    float rightHeight = max(rightSlope1, max(rightSlope2, rightSlope3));
    float mountainHeight = max(max(leftHeight, rightHeight), max(farLeft, farRight));
    float mountainTop = mountainBase + mountainHeight;

    // === DUNE HORIZON (sharp transition to mountains) ===
    float horizonBase = -0.36;
    float horizonWave = 0.015 * sin(groundUV.x * 7.0) + 0.008 * sin(groundUV.x * 13.0 + 1.0);
    float horizonY = horizonBase + horizonWave;

    // Determine what to render based on position
    bool isBelowHorizon = groundUV.y < horizonY;
    bool isInMountains = (mountainUV.y < mountainTop && mountainHeight > 0.01 && mountainUV.y >= horizonY);

    if (isBelowHorizon) {
        // === DUNES (same as inside) ===
        float distFactor = saturate((horizonY - groundUV.y) / 0.20);
        float3 duneCol = float3(0.08, 0.07, 0.09);

        // Dune 1
        float d1Wave = 0.025 * sin(groundUV.x * 10.0 + 0.5) + 0.012 * sin(groundUV.x * 18.0 + 2.0);
        float d1Top = horizonY - 0.015 + d1Wave;
        float d1Slope = cos(groundUV.x * 10.0 + 0.5);
        if (groundUV.y < d1Top) {
            float d1Depth = (d1Top - groundUV.y) / 0.025;
            float d1Light = saturate(0.3 + d1Slope * 0.15 - d1Depth * 0.2);
            duneCol = mix(float3(0.10, 0.09, 0.12), float3(0.18, 0.17, 0.20), d1Light);
        }

        // Dune 2
        float d2Wave = 0.032 * sin(groundUV.x * 7.5 + 2.5) + 0.018 * sin(groundUV.x * 14.0);
        float d2Top = horizonY - 0.05 + d2Wave;
        float d2Slope = cos(groundUV.x * 7.5 + 2.5);
        if (groundUV.y < d2Top) {
            float d2Depth = (d2Top - groundUV.y) / 0.035;
            float d2Light = saturate(0.35 + d2Slope * 0.2 - d2Depth * 0.25);
            duneCol = mix(float3(0.12, 0.11, 0.12), float3(0.24, 0.21, 0.19), d2Light);
        }

        // Dune 3
        float d3Wave = 0.038 * sin(groundUV.x * 5.5 + 1.2) + 0.022 * sin(groundUV.x * 11.0 + 3.0);
        float d3Top = horizonY - 0.095 + d3Wave;
        float d3Slope = cos(groundUV.x * 5.5 + 1.2);
        if (groundUV.y < d3Top) {
            float d3Depth = (d3Top - groundUV.y) / 0.04;
            float d3Light = saturate(0.4 + d3Slope * 0.22 - d3Depth * 0.3);
            duneCol = mix(float3(0.14, 0.12, 0.11), float3(0.30, 0.26, 0.22), d3Light);
        }

        col = duneCol;

        // Atmospheric haze
        float3 atmosCol = float3(0.05, 0.05, 0.08);
        col = mix(atmosCol, col, 0.35 + distFactor * 0.65);

        float bottomFade = smoothstep(-0.58, -0.45, groundUV.y);
        col *= bottomFade;

    } else if (isInMountains) {
        // === MOUNTAINS ===
        float heightRatio = saturate((mountainUV.y - mountainBase) / max(mountainHeight, 0.01));

        // Calculate peak position for face shading
        float peakX = 0.0;
        if (leftSpire1 >= rightHeight && leftSpire1 >= leftSpire2) peakX = -0.05;
        else if (leftSpire2 >= rightHeight) peakX = -0.02;
        else if (rightSlope1 >= rightSlope2) peakX = 0.03;
        else peakX = 0.07;

        float faceAngle = (mx - peakX) * 8.0;
        float faceLighting = smoothstep(-1.0, 1.0, faceAngle) * 0.4 + 0.3;

        float3 darkFace = float3(0.35, 0.42, 0.55);
        float3 litFace = float3(0.72, 0.78, 0.88);
        col = mix(darkFace, litFace, faceLighting + heightRatio * 0.3);

        // Snow on peaks
        float snowLine = smoothstep(0.0, 0.06, mountainUV.y - mountainTop + 0.05);
        col = mix(col, float3(0.85, 0.90, 0.96), snowLine * 0.7);

    } else {
        // === SKY - Same dark cosmic sky as inside with parallax nebula ===
        col = renderDeepSpace(skyUV, time, true);
        col += renderNebulaParallax(nebulaClose, nebulaMid, nebulaDeep, time);
    }

    return col;
}

// Layer 2: Nebula/Galaxy - SMALL tight core, doesn't wash out colors
float3 renderNebula(float2 uv, float time) {
    float3 col = float3(0.0);

    float2 nebulaCenter = float2(0.0, 0.12);
    float nebulaDist = length(uv - nebulaCenter);

    // Very small, tight bright core - doesn't spread far
    // Using lavender/pink tint instead of pure white to match nebula
    float core = exp(-nebulaDist * 80.0) * 1.5;  // Much tighter (80 vs 45), lower intensity
    col += float3(0.98, 0.92, 0.96) * core;  // Slight pink tint

    // Tiny inner glow - pink/lavender
    float innerGlow = exp(-nebulaDist * 50.0) * 0.4;  // Much tighter and dimmer
    col += float3(0.95, 0.85, 0.95) * innerGlow;  // Pink-lavender

    return col;
}

// Layer 3: Star field
float3 renderStars(float2 uv, float time, float nebulaDist) {
    float3 col = float3(0.0);

    for (int layer = 0; layer < 5; layer++) {
        float scale = 30.0 + float(layer) * 18.0;
        float2 starUV = uv * scale;
        float2 starID = floor(starUV);
        float2 starF = fract(starUV) - 0.5;
        float starRand = hash(starID + float(layer) * 100.0);

        float threshold = 0.65 - float(layer) * 0.07;
        if (starRand > threshold) {
            float starBright = (starRand - threshold) * 8.0;
            float twinkle = 0.65 + 0.35 * sin(time * 2.0 + starRand * 40.0);
            float starSize = 0.03 + starRand * 0.025;
            float star = smoothstep(starSize, 0.0, length(starF)) * starBright * twinkle;
            star *= smoothstep(0.0, 0.06, nebulaDist);
            col += float3(1.0, 0.98, 0.92) * star * 2.5;
        }
    }
    return col;
}

// Layer 4: Cosmic arc - DISABLED
float3 renderArc(float2 uv) {
    return float3(0.0);  // Removed the line in the sky
}

// Layer 5: Moon
float3 renderMoon(float2 uv, thread float &moonMask) {
    float2 moonPos = float2(0.02, -0.29);
    float moonDist = length(uv - moonPos);
    float moonCutout = length(uv - moonPos - float2(0.009, 0.007));
    float moon = smoothstep(0.020, 0.014, moonDist) * smoothstep(0.011, 0.018, moonCutout);
    moonMask = moon;

    return float3(0.63, 0.66, 0.72) * moon;
}

// Layer 6a: FAR BACKGROUND Mountains - smooth silhouettes
float3 renderMountainsFar(float2 uv, thread float &mountainMask) {
    float3 col = float3(0.0);
    mountainMask = 0.0;

    float mountainBase = -0.33;
    float mx = uv.x;

    // Smooth distant peaks using sine waves (no noise)
    float farLeft1 = 0.07 * max(0.0, 1.0 - abs(mx + 0.14) * 3.2);
    float farLeft2 = 0.055 * max(0.0, 1.0 - abs(mx + 0.24) * 3.8);
    float farRight1 = 0.06 * max(0.0, 1.0 - abs(mx - 0.15) * 3.5);
    float farRight2 = 0.05 * max(0.0, 1.0 - abs(mx - 0.26) * 4.0);

    float mountainHeight = max(max(farLeft1, farLeft2), max(farRight1, farRight2));
    // Smooth sine variation instead of noise
    mountainHeight += 0.008 * sin(mx * 25.0 + 1.0);
    float mountainTop = mountainBase + mountainHeight;

    if (uv.y < mountainTop && mountainHeight > 0.01) {
        mountainMask = 0.85;

        // Clean gradient - dark at base, lighter at top
        float heightFactor = saturate((uv.y - mountainBase) / max(mountainHeight, 0.01));
        float3 baseCol = float3(0.16, 0.20, 0.30);
        float3 topCol = float3(0.28, 0.34, 0.48);
        col = mix(baseCol, topCol, heightFactor * 0.6);
    }

    return col;
}

// Layer 6b: MID-GROUND Mountains - smooth silhouettes
float3 renderMountainsMid(float2 uv, thread float &mountainMask) {
    float3 col = float3(0.0);
    mountainMask = 0.0;

    float mountainBase = -0.36;
    float mx = uv.x;

    // Smooth mid-distance peaks
    float midLeft1 = 0.14 * max(0.0, 1.0 - abs(mx + 0.09) * 5.5);
    float midLeft2 = 0.11 * max(0.0, 1.0 - abs(mx + 0.17) * 6.0);
    float midRight1 = 0.12 * max(0.0, 1.0 - abs(mx - 0.10) * 5.8);
    float midRight2 = 0.10 * max(0.0, 1.0 - abs(mx - 0.18) * 6.2);

    float mountainHeight = max(max(midLeft1, midLeft2), max(midRight1, midRight2));
    // Smooth sine variation
    mountainHeight += 0.01 * sin(mx * 20.0 + 2.0);
    float mountainTop = mountainBase + mountainHeight;

    if (uv.y < mountainTop && mountainHeight > 0.01) {
        mountainMask = 0.9;

        float heightRatio = saturate((uv.y - mountainBase) / max(mountainHeight, 0.01));

        // Clean gradient colors
        float3 baseCol = float3(0.30, 0.36, 0.50);
        float3 topCol = float3(0.52, 0.58, 0.70);
        col = mix(baseCol, topCol, heightRatio * 0.7);

        // Subtle snow on peaks (smooth transition)
        float snowLine = smoothstep(0.0, 0.03, uv.y - mountainTop + 0.025);
        col = mix(col, float3(0.62, 0.68, 0.78), snowLine * 0.4);
    }

    return col;
}

// Layer 6c: FOREGROUND Mountains - detailed with 3D shading
float3 renderMountains(float2 uv, thread float &mountainMask) {
    float3 col = float3(0.0);

    float mountainBase = -0.40;
    float mx = uv.x;

    // LEFT SIDE - Multiple sharp spires with varied heights
    float leftSpire1 = 0.26 * max(0.0, 1.0 - abs(mx + 0.05) * 12.0);
    float leftSpire2 = 0.20 * max(0.0, 1.0 - abs(mx + 0.02) * 14.0);
    float leftSpire3 = 0.18 * max(0.0, 1.0 - abs(mx + 0.085) * 11.0);
    float leftSpire4 = 0.14 * max(0.0, 1.0 - abs(mx + 0.11) * 13.0);

    // RIGHT SIDE - Softer peaks
    float rightSlope1 = 0.12 * max(0.0, 1.0 - abs(mx - 0.03) * 10.0);
    float rightSlope2 = 0.10 * max(0.0, 1.0 - abs(mx - 0.07) * 11.0);
    float rightSlope3 = 0.08 * max(0.0, 1.0 - abs(mx - 0.10) * 12.0);

    float leftHeight = max(max(leftSpire1, leftSpire2), max(leftSpire3, leftSpire4));
    float rightHeight = max(rightSlope1, max(rightSlope2, rightSlope3));
    float mountainHeight = max(leftHeight, rightHeight);
    float mountainTop = mountainBase + mountainHeight;

    mountainMask = 0.0;

    if (uv.y < mountainTop && mountainHeight > 0.01) {
        mountainMask = 1.0;
        float heightRatio = saturate((uv.y - mountainBase) / max(mountainHeight, 0.01));

        // Calculate which peak we're on for proper face shading
        float peakX = 0.0;
        if (leftSpire1 >= rightHeight && leftSpire1 >= leftSpire2) peakX = -0.05;
        else if (leftSpire2 >= rightHeight) peakX = -0.02;
        else if (rightSlope1 >= rightSlope2) peakX = 0.03;
        else peakX = 0.07;

        // Face shading - left faces darker, right faces lighter
        float faceAngle = (mx - peakX) * 8.0;
        float faceLighting = smoothstep(-1.0, 1.0, faceAngle) * 0.4 + 0.3;

        // Base colors
        float3 darkFace = float3(0.35, 0.42, 0.55);
        float3 litFace = float3(0.72, 0.78, 0.88);

        col = mix(darkFace, litFace, faceLighting + heightRatio * 0.3);

        // Snow/ice on peaks
        float snowLine = smoothstep(0.0, 0.06, uv.y - mountainTop + 0.05);
        col = mix(col, float3(0.85, 0.90, 0.96), snowLine * 0.7);

        // Subtle ice texture (very fine, not grainy)
        float iceDetail = sin(uv.x * 200.0 + uv.y * 150.0) * 0.02;
        col += iceDetail * heightRatio;
    }

    return col;
}

// Layer 7: Path and ground - 3D DUNES with realistic shading
float3 renderPath(float2 uv, thread float &pathMask) {
    float3 col = float3(0.0);
    pathMask = 0.0;

    // Undulating horizon with SHARP transition
    float horizonBase = -0.36;
    float horizonWave = 0.015 * sin(uv.x * 7.0) + 0.008 * sin(uv.x * 13.0 + 1.0);
    float horizonY = horizonBase + horizonWave;

    float pathBottom = -0.56;

    // SHARP horizon edge (not soft/blurry)
    float horizonBlend = smoothstep(horizonY + 0.003, horizonY - 0.001, uv.y);

    if (uv.y < horizonY + 0.02) {
        pathMask = horizonBlend;

        float distFactor = saturate((horizonY - uv.y) / (horizonY - pathBottom));

        // === 3D DUNES with light/shadow faces ===
        // Warmer, more natural desert/earth tones
        float3 duneCol = float3(0.08, 0.07, 0.09);  // Base dark ground

        // Dune 1: Far - small, hazy, cool tones (atmospheric)
        float d1Wave = 0.025 * sin(uv.x * 10.0 + 0.5) + 0.012 * sin(uv.x * 18.0 + 2.0);
        float d1Top = horizonY - 0.015 + d1Wave;
        float d1Slope = cos(uv.x * 10.0 + 0.5);
        if (uv.y < d1Top) {
            float d1Depth = (d1Top - uv.y) / 0.025;
            float d1Light = saturate(0.3 + d1Slope * 0.15 - d1Depth * 0.2);
            float3 d1Lit = float3(0.18, 0.17, 0.20);
            float3 d1Shadow = float3(0.10, 0.09, 0.12);
            duneCol = mix(d1Shadow, d1Lit, d1Light);
        }

        // Dune 2: Mid-far - slightly warmer
        float d2Wave = 0.032 * sin(uv.x * 7.5 + 2.5) + 0.018 * sin(uv.x * 14.0);
        float d2Top = horizonY - 0.05 + d2Wave;
        float d2Slope = cos(uv.x * 7.5 + 2.5);
        if (uv.y < d2Top) {
            float d2Depth = (d2Top - uv.y) / 0.035;
            float d2Light = saturate(0.35 + d2Slope * 0.2 - d2Depth * 0.25);
            float3 d2Lit = float3(0.24, 0.21, 0.19);
            float3 d2Shadow = float3(0.12, 0.11, 0.12);
            duneCol = mix(d2Shadow, d2Lit, d2Light);
        }

        // Dune 3: Mid - warmer earth tones
        float d3Wave = 0.038 * sin(uv.x * 5.5 + 1.2) + 0.022 * sin(uv.x * 11.0 + 3.0);
        float d3Top = horizonY - 0.095 + d3Wave;
        float d3Slope = cos(uv.x * 5.5 + 1.2);
        if (uv.y < d3Top) {
            float d3Depth = (d3Top - uv.y) / 0.04;
            float d3Light = saturate(0.4 + d3Slope * 0.22 - d3Depth * 0.3);
            float3 d3Lit = float3(0.30, 0.26, 0.22);
            float3 d3Shadow = float3(0.14, 0.12, 0.11);
            duneCol = mix(d3Shadow, d3Lit, d3Light);
        }

        // Dune 4: Near - warmest, most saturated
        float d4Wave = 0.045 * sin(uv.x * 4.0 + 0.3) + 0.028 * sin(uv.x * 8.0 + 1.8);
        float d4Top = horizonY - 0.15 + d4Wave;
        float d4Slope = cos(uv.x * 4.0 + 0.3);
        if (uv.y < d4Top) {
            float d4Depth = (d4Top - uv.y) / 0.05;
            float d4Light = saturate(0.45 + d4Slope * 0.25 - d4Depth * 0.35);
            float3 d4Lit = float3(0.36, 0.30, 0.24);
            float3 d4Shadow = float3(0.16, 0.13, 0.11);
            duneCol = mix(d4Shadow, d4Lit, d4Light);
        }

        // PATH with perspective
        float pathWidthFar = 0.012;
        float pathWidthNear = 0.13;
        float pathWidth = mix(pathWidthFar, pathWidthNear, pow(distFactor, 0.6));
        float pathEdge = smoothstep(pathWidth, pathWidth * 0.25, abs(uv.x));

        // Path color gradient
        float3 pathFar = float3(0.22, 0.21, 0.22);
        float3 pathNear = float3(0.50, 0.44, 0.36);
        float3 pathCol = mix(pathFar, pathNear, distFactor * 0.85);

        // Blend path over dunes
        col = mix(duneCol, pathCol, pathEdge);

        // Atmospheric haze in distance
        float3 atmosCol = float3(0.06, 0.07, 0.12);
        col = mix(atmosCol, col, 0.35 + distFactor * 0.65);

        col *= horizonBlend;

        // Fade to dark at bottom
        float bottomFade = smoothstep(pathBottom, pathBottom + 0.05, uv.y);
        col *= bottomFade;
        pathMask *= bottomFade * horizonBlend;
    }

    return col;
}

// Layer 8: Figure and rock - SMALL SILHOUETTE FACING AWAY
float3 renderFigure(float2 uv, thread float &figureMask, thread float &shadowMask) {
    float3 col = float3(0.0);
    figureMask = 0.0;
    shadowMask = 0.0;

    // Figure position - lower on the path
    float2 figureBase = float2(0.0, -0.46);

    // === SHADOW - DIRECTLY at figure's feet (touching the figure) ===
    // Shadow ellipse at the exact base of the figure - NO offset
    float2 shadowCenter = float2(0.0, figureBase.y);
    float2 shadowP = uv - shadowCenter;
    // Flat ellipse on ground - elongated horizontally
    float shadowEllipse = (shadowP.x * shadowP.x) / (0.020 * 0.020) + (shadowP.y * shadowP.y) / (0.005 * 0.005);
    shadowMask = smoothstep(1.0, 0.2, shadowEllipse) * 0.45;

    // Small rock/mound the figure stands on (centered under figure)
    float2 rockPos = float2(0.0, figureBase.y - 0.006);
    float2 rockP = (uv - rockPos) * float2(0.8, 5.0);
    float rockDist = length(rockP);
    float rock = smoothstep(0.035, 0.005, rockDist);

    // Smooth rock color (no noise texture for clean fantasy look)
    float3 rockCol = float3(0.12, 0.13, 0.16);
    // Simple gradient lighting
    float rockLight = 0.7 + 0.3 * smoothstep(-0.015, 0.015, uv.x);
    rockCol *= rockLight;

    // === SMALL FIGURE FACING AWAY (silhouette from behind) ===
    float2 fp = uv - figureBase;

    // SMALLER figure dimensions
    float figureHeight = 0.055;
    float headY = figureHeight * 0.85;
    float shoulderY = figureHeight * 0.70;
    float waistY = figureHeight * 0.40;

    // Simple cloak silhouette (seen from behind - no face visible)
    float cloakWidth;
    if (fp.y < 0.0) {
        cloakWidth = 0.0;
    } else if (fp.y < waistY) {
        // Bottom of cloak - wider, flowing
        float t = fp.y / waistY;
        cloakWidth = mix(0.018, 0.012, t);
        cloakWidth += sin(fp.y * 300.0) * 0.002 * (1.0 - t);
    } else if (fp.y < shoulderY) {
        // Body tapers up
        float t = (fp.y - waistY) / (shoulderY - waistY);
        cloakWidth = mix(0.012, 0.010, t);
    } else if (fp.y < headY) {
        // Shoulders to neck
        float t = (fp.y - shoulderY) / (headY - shoulderY);
        cloakWidth = mix(0.010, 0.005, t);
    } else {
        // Hood (back of head - rounded)
        float t = (fp.y - headY) / (figureHeight - headY);
        cloakWidth = mix(0.005, 0.002, t * t);
    }

    float cloakDist = abs(fp.x) - cloakWidth;
    float cloak = smoothstep(0.003, 0.0, cloakDist) * step(0.0, fp.y) * step(fp.y, figureHeight);

    // Hood from behind (simple rounded shape)
    float2 headCenter = figureBase + float2(0.0, headY + 0.006);
    float headDist = length((uv - headCenter) * float2(1.0, 0.8));
    float hood = smoothstep(0.010, 0.006, headDist);

    // Staff (thin, to the side)
    float2 staffBase = figureBase + float2(0.012, 0.005);
    float2 staffTop = figureBase + float2(0.014, figureHeight + 0.020);
    float2 staffDir = normalize(staffTop - staffBase);
    float2 toStaff = uv - staffBase;
    float staffLen = dot(toStaff, staffDir);
    float staffDist = length(toStaff - staffDir * staffLen);
    float staffWidth = 0.0018;
    float staff = smoothstep(staffWidth + 0.0005, staffWidth - 0.0005, staffDist)
                * step(0.0, staffLen) * step(staffLen, length(staffTop - staffBase));

    // Small orb at staff top
    float2 orbPos = staffTop;
    float orbDist = length(uv - orbPos);
    float orb = smoothstep(0.006, 0.003, orbDist);

    // Combine figure parts
    float figure = max(cloak, hood);

    // === SIMPLE SILHOUETTE SHADING (figure seen from behind) ===
    if (figure > 0.0 || staff > 0.0 || orb > 0.0) {
        // Dark silhouette - backlit figure
        float3 darkCloak = float3(0.08, 0.03, 0.02);
        float3 edgeCloak = float3(0.25, 0.08, 0.05);

        // Subtle rim light from the nebula behind
        float rimLight = smoothstep(0.003, 0.0, abs(abs(fp.x) - cloakWidth)) * 0.5;
        rimLight += smoothstep(0.004, 0.0, abs(fp.y - figureHeight)) * 0.3;

        float3 cloakCol = mix(darkCloak, edgeCloak, rimLight);

        // Hood slightly different tone
        if (hood > cloak * 0.5) {
            cloakCol = mix(cloakCol, float3(0.06, 0.02, 0.02), 0.3);
        }

        col = cloakCol;

        // Staff - dark wood
        if (staff > 0.0) {
            col = mix(col, float3(0.15, 0.10, 0.06), staff);
        }

        // Small orb glow
        if (orb > 0.0) {
            float3 orbCol = float3(0.4, 0.55, 0.75);
            col = mix(col, orbCol, orb);
        }
    }

    figureMask = max(max(rock, figure), max(staff, orb));

    // Composite rock
    if (rock > 0.0 && figure < 0.3 && staff < 0.3) {
        col = mix(col, rockCol, rock * (1.0 - max(figure, staff)));
    }

    return col;
}

// Layer: Arch structure - STONE BLOCKS with aged weathering
float3 renderArch(float2 uv, float time) {
    // Calculate distance from inner edge for 3D depth
    float distToInner = abs(uv.x) - PILLAR_INNER_X;
    bool isArchCurve = uv.y > ARCH_TOP_Y;

    if (isArchCurve) {
        float2 archCenter = float2(0.0, ARCH_TOP_Y);
        distToInner = length(uv - archCenter) - PILLAR_INNER_X;
    }
    float distToOuter = PILLAR_WIDTH - distToInner;

    // === HORIZONTAL STONE BLOCK LAYERS ===
    float blockHeight = 0.024;
    float blockCoord;
    if (isArchCurve) {
        float2 archCenter = float2(0.0, ARCH_TOP_Y);
        float angle = atan2(uv.x - archCenter.x, uv.y - archCenter.y);
        blockCoord = (angle + 1.57) * 0.16;
    } else {
        blockCoord = uv.y;
    }

    float blockIndex = floor(blockCoord / blockHeight);
    float withinBlock = fract(blockCoord / blockHeight);

    // Mortar lines between blocks
    float mortarLine = smoothstep(0.0, 0.1, withinBlock) * smoothstep(1.0, 0.9, withinBlock);

    // Per-block variation
    float blockVar = fract(sin(blockIndex * 127.1) * 43758.5453);

    // === STONE COLORS - dark terracotta/brown ===
    float3 darkStone = float3(0.35, 0.18, 0.12);    // Dark brown-red
    float3 baseStone = float3(0.52, 0.28, 0.18);    // Terracotta
    float3 lightStone = float3(0.62, 0.35, 0.24);   // Lighter highlight

    // === SUBTLE WEATHERING (keeps stone look) ===
    float weathering = fbm(uv * 20.0 + 100.0) * 0.5 + 0.5;
    float fineTex = noise(uv * 60.0) * 0.15;

    // === 3D LIGHTING ===
    float3 lightDir = normalize(float3(0.0, 0.7, 0.7));
    float3 surfaceNormal;

    if (isArchCurve) {
        float2 archCenter = float2(0.0, ARCH_TOP_Y);
        float2 radialDir = normalize(uv - archCenter);
        surfaceNormal = normalize(float3(radialDir.x * 0.5, radialDir.y * 0.5, 0.75));
    } else {
        float sideSign = sign(uv.x);
        surfaceNormal = normalize(float3(sideSign * 0.4, 0.0, 0.9));
    }

    float diffuse = max(0.3, dot(surfaceNormal, lightDir));

    // Build stone color
    float3 archColor = mix(darkStone, baseStone, diffuse);
    archColor = mix(archColor, lightStone, blockVar * 0.15 + weathering * 0.1);
    archColor += fineTex * float3(0.08, 0.05, 0.03);  // Fine texture variation

    // Mortar shadows
    archColor *= 0.55 + mortarLine * 0.45;

    // === AGING - subtle darkening and staining ===
    float aging = smoothstep(0.4, 0.7, weathering) * 0.2;
    archColor = mix(archColor, archColor * 0.7, aging);

    // Slight dark staining in lower areas
    float staining = smoothstep(0.1, -0.4, uv.y) * 0.15;
    archColor *= 1.0 - staining;

    // Inner edge shadow
    float innerShadow = smoothstep(0.0, 0.02, distToInner);
    archColor *= 0.4 + innerShadow * 0.6;

    // === COSMIC RIM LIGHT from portal ===
    float rimLight = smoothstep(0.012, 0.0, distToInner);
    float3 cosmicRim = float3(0.85, 0.35, 0.5);  // Pink/magenta glow
    archColor += cosmicRim * rimLight * 0.5;

    // Subtle secondary rim
    float rimLight2 = smoothstep(0.022, 0.006, distToInner);
    archColor += float3(0.5, 0.2, 0.6) * rimLight2 * 0.25;

    // Outer edge highlight
    float outerHighlight = smoothstep(0.015, 0.0, distToOuter);
    archColor += float3(0.1, 0.05, 0.03) * outerHighlight;

    return saturate(archColor);
}

// ============================================================================
// MAIN SHADER - Composites all layers with parallax
// ============================================================================

kernel void darkFantasyShader(
    texture2d<float, access::write> outTexture [[texture(0)]],
    uint2 tid [[thread_position_in_grid]],
    constant Uniforms &uniforms [[buffer(0)]]
) {
    float2 res = uniforms.resolution;
    float time = uniforms.time;

    // Clamp panning to prevent looking past edges
    float2 look = clamp(uniforms.cameraRotation, float2(-MAX_PAN), float2(MAX_PAN));

    // Base UV
    float2 baseUV = (float2(tid) - res * 0.5) / res.y;
    baseUV.y = -baseUV.y;

    // Create parallax UVs for each depth layer
    // POV looking AT the scene - closer objects (arch) move MORE
    float2 uvDeepSpace  = baseUV + look * DEPTH_DEEP_SPACE;
    float2 uvNebulaDeep = baseUV + look * DEPTH_NEBULA_DEEP;
    float2 uvNebulaMid  = baseUV + look * DEPTH_NEBULA_MID;
    float2 uvNebulaClose = baseUV + look * DEPTH_NEBULA_CLOSE;
    float2 uvStars      = baseUV + look * DEPTH_STARS;
    float2 uvCosmicArc  = baseUV + look * DEPTH_COSMIC_ARC;
    float2 uvMoon       = baseUV + look * DEPTH_MOON;
    float2 uvMountainsFar = baseUV + look * DEPTH_MOUNTAINS_FAR;   // Background mountains
    float2 uvMountainsMid = baseUV + look * DEPTH_MOUNTAINS_MID;   // Mid mountains
    float2 uvMountains  = baseUV + look * DEPTH_MOUNTAINS;          // Foreground mountains
    float2 uvPath       = baseUV + look * DEPTH_PATH;
    float2 uvFigure     = baseUV + look * DEPTH_FIGURE;
    float2 uvArch       = baseUV + look * DEPTH_ARCH;  // Arch moves most (closest)

    // Initialize output
    float3 col = float3(0.0);

    // Check arch geometry against arch's parallax UV (arch moves with POV)
    bool inOpening = insideArchOpening(uvArch);
    bool inStone = insideArchStone(uvArch);

    if (inOpening) {
        // Render cosmic scene through arch opening with parallax layers

        // Layer 1: Deep space background (black void + stars)
        col = renderDeepSpace(uvStars, time, false);

        // Layer 2: Layered nebula with parallax (3 depth layers)
        col += renderNebulaParallax(uvNebulaClose, uvNebulaMid, uvNebulaDeep, time);

        // Layer 4: Cosmic arc
        col += renderArc(uvCosmicArc);

        // Layer 5: Moon
        float moonMask = 0.0;
        float3 moonCol = renderMoon(uvMoon, moonMask);
        col = mix(col, moonCol, moonMask);

        // Layer 6a: FAR Background Mountains (most distant, slowest parallax)
        float mountainMaskFar = 0.0;
        float3 mountainColFar = renderMountainsFar(uvMountainsFar, mountainMaskFar);
        col = mix(col, mountainColFar, mountainMaskFar);

        // Layer 6b: MID Mountains
        float mountainMaskMid = 0.0;
        float3 mountainColMid = renderMountainsMid(uvMountainsMid, mountainMaskMid);
        col = mix(col, mountainColMid, mountainMaskMid);

        // Layer 6c: FOREGROUND Mountains (closest, fastest parallax)
        float mountainMask = 0.0;
        float3 mountainCol = renderMountains(uvMountains, mountainMask);
        col = mix(col, mountainCol, mountainMask);

        // Layer 7: Path
        float pathMask = 0.0;
        float3 pathCol = renderPath(uvPath, pathMask);
        col = mix(col, pathCol, pathMask);

        // Layer 8: Figure, rock, and shadow
        float figureMask = 0.0;
        float shadowMask = 0.0;
        float3 figureCol = renderFigure(uvFigure, figureMask, shadowMask);

        // Apply shadow to ground (darken where shadow falls)
        col = mix(col, col * 0.4, shadowMask * pathMask);

        // Render figure on top
        col = mix(col, figureCol, figureMask);
    }

    // Arch structure (fixed frame)
    if (inStone) {
        col = renderArch(uvArch, time);
    }

    // Environment outside arch (stars, mountains AND ground when looking past the arch)
    if (!inOpening && !inStone) {
        // Use uvDeepSpace for sky, uvPath for ground, uvMountains for mountains
        col = renderOuterEnvironment(uvStars, uvPath, uvMountains, time,
                                      uvNebulaClose, uvNebulaMid, uvNebulaDeep);
    }

    // Vignette
    float2 vignetteUV = float2(tid) / res;
    col *= 1.0 - dot(vignetteUV - 0.5, vignetteUV - 0.5) * 0.5;

    // Tone mapping
    col = col / (col + 1.0);
    col = pow(col, float3(0.45));

    // Very subtle film grain (minimal for clean fantasy look)
    float2 grainUV = float2(tid) / res;
    float grain = noise(grainUV * 200.0 + time * 0.3) * 0.02;
    col += grain - 0.01;
    col = saturate(col);

    outTexture.write(float4(col, 1.0), tid);
}
