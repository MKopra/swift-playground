#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 metallicCard(
    float2 position,
    half4 color,
    float2 size,
    float pitch,
    float roll
) {
    // Keep old shader for compatibility
    return half4(0.3, 0.3, 0.3, 1.0);
}

[[ stitchable ]] half4 barbell(
    float2 position,
    half4 color,
    float2 size,
    float pitch,
    float roll,
    float spinAngle
) {
    float2 uv = position / size;

    // Cylinder parameters
    float cylinderRadius = 0.35; // Radius in UV space (vertical)
    float cylinderCenterY = 0.5;

    // Distance from center line
    float distFromCenter = abs(uv.y - cylinderCenterY);

    // Check if we're on the cylinder
    if (distFromCenter > cylinderRadius) {
        // Black background
        return half4(0.0, 0.0, 0.0, 1.0);
    }

    // Calculate cylinder surface properties
    // Map Y position to angle on cylinder surface (0 to PI, front-facing half)
    float normalizedDist = distFromCenter / cylinderRadius;
    float surfaceAngle = asin(normalizedDist);
    if (uv.y < cylinderCenterY) {
        surfaceAngle = -surfaceAngle;
    }

    // The "depth" into the cylinder - 1 at center, 0 at edges
    float depth = cos(surfaceAngle);

    // Cylinder normal (pointing outward)
    float3 cylinderNormal = float3(0.0, sin(surfaceAngle), depth);

    // Convert spin angle to radians and apply to texture coordinates
    float spinRad = spinAngle * 3.14159 / 180.0;

    // Calculate texture coordinates that wrap around the cylinder
    // As the bar spins, the texture scrolls
    float circumferencePos = surfaceAngle + spinRad;

    // Knurling parameters
    float knurlScale = 12.0;
    float2 knurlUV = float2(uv.x * knurlScale * (size.x / size.y), circumferencePos * knurlScale);

    // Get position within each diamond cell
    float d1 = fract(knurlUV.x + knurlUV.y);
    float d2 = fract(knurlUV.x - knurlUV.y);

    // Distance from center of diamond (0 at center, 0.5 at edges)
    float distFromCenter1 = abs(d1 - 0.5);
    float distFromCenter2 = abs(d2 - 0.5);

    // Create truncated pyramid - flat top with angled sides
    float grooveWidth = 0.12; // Width of the groove between diamonds
    float topSize = 0.15;     // Size of the flat top

    // Are we in a groove?
    bool inGroove1 = distFromCenter1 > (0.5 - grooveWidth);
    bool inGroove2 = distFromCenter2 > (0.5 - grooveWidth);
    bool inGroove = inGroove1 || inGroove2;

    // Are we on the flat top?
    bool onTop = distFromCenter1 < topSize && distFromCenter2 < topSize;

    // Height: grooves are deep, tops are high, sides slope
    float knurlHeight;
    if (inGroove) {
        knurlHeight = -1.0;
    } else if (onTop) {
        knurlHeight = 1.0;
    } else {
        // Sloped side - interpolate based on distance from top
        float slopeDist1 = (distFromCenter1 - topSize) / (0.5 - grooveWidth - topSize);
        float slopeDist2 = (distFromCenter2 - topSize) / (0.5 - grooveWidth - topSize);
        float slopeDist = max(slopeDist1, slopeDist2);
        knurlHeight = mix(1.0, -0.5, slopeDist);
    }

    // Signs for facet directions (needed for both normals and glimmer)
    float sign1 = d1 > 0.5 ? 1.0 : -1.0;
    float sign2 = d2 > 0.5 ? 1.0 : -1.0;

    // Determine which of the 4 facets we're on and calculate normal
    float3 knurlNormal = float3(0.0, 0.0, 1.0);

    if (!inGroove && !onTop) {
        // We're on one of the 4 angled faces
        float facetAngle = 0.7; // Steepness of facet

        if (distFromCenter1 > distFromCenter2) {
            // On a facet facing along diagonal 1
            knurlNormal = normalize(float3(sign1 * facetAngle, sign1 * facetAngle, 1.0));
        } else {
            // On a facet facing along diagonal 2
            knurlNormal = normalize(float3(sign2 * facetAngle, -sign2 * facetAngle, 1.0));
        }
    } else if (inGroove) {
        // Groove walls
        if (inGroove1 && !inGroove2) {
            knurlNormal = normalize(float3(sign1 * 0.9, sign1 * 0.9, 0.3));
        } else if (inGroove2 && !inGroove1) {
            knurlNormal = normalize(float3(sign2 * 0.9, -sign2 * 0.9, 0.3));
        } else {
            // Corner of groove - points down
            knurlNormal = float3(0.0, 0.0, -1.0);
        }
    }

    // Combine knurl normal with cylinder normal
    float3 normal = cylinderNormal;
    normal.x += knurlNormal.x * 0.5;
    normal.y += knurlNormal.y * cos(surfaceAngle) * 0.5;
    normal.z = normal.z * 0.7 + knurlNormal.z * 0.3;
    normal = normalize(normal);

    // Edge detection for glimmer (at groove edges)
    float edge1 = 1.0 - smoothstep(0.0, 0.03, abs(distFromCenter1 - (0.5 - grooveWidth)));
    float edge2 = 1.0 - smoothstep(0.0, 0.03, abs(distFromCenter2 - (0.5 - grooveWidth)));

    // Metallic colors
    float3 darkMetal = float3(0.08, 0.09, 0.10);
    float3 midMetal = float3(0.22, 0.24, 0.26);
    float3 lightMetal = float3(0.8, 0.83, 0.88);

    // Base color with depth shading
    float3 baseColor = mix(darkMetal, midMetal, depth * 0.8 + 0.2);
    baseColor += knurlHeight * 0.08;

    // Normalize tilt values
    float normalizedPitch = clamp(pitch / 20.0, -1.0, 1.0);
    float normalizedRoll = clamp(roll / 20.0, -1.0, 1.0);

    // Light direction based on tilt
    float3 lightDir = normalize(float3(-normalizedRoll * 0.5, -0.3 - normalizedPitch * 0.3, 1.0));

    // Diffuse lighting on cylinder
    float diffuse = max(0.0, dot(normal, lightDir));

    // Specular highlight
    float3 viewDir = float3(0.0, 0.0, 1.0);
    float3 halfVec = normalize(lightDir + viewDir);
    float specular = pow(max(0.0, dot(normal, halfVec)), 32.0);
    float specularBroad = pow(max(0.0, dot(normal, halfVec)), 8.0) * 0.4;

    // Edge glimmer based on light direction
    float2 lightDir2D = normalize(float2(sign1 + sign2, sign1 - sign2));
    float2 tiltLight = normalize(float2(-normalizedRoll, -normalizedPitch) + float2(0.001, 0.001));
    float edgeFacing = dot(lightDir2D, tiltLight);
    float glimmer = (edge1 + edge2) * pow(max(0.0, abs(edgeFacing)), 1.5) * 1.5;

    // Combine lighting
    float3 finalColor = baseColor;
    finalColor += diffuse * 0.15;
    finalColor += specularBroad * lightMetal;
    finalColor += specular * lightMetal * 0.8;
    finalColor += glimmer * lightMetal * depth;

    // Darker at cylinder edges (falloff)
    float edgeFalloff = pow(1.0 - depth, 2.0) * 0.3;
    finalColor -= edgeFalloff;

    // Subtle edge highlight (rim light)
    float rim = pow(1.0 - depth, 4.0) * 0.15;
    finalColor += rim * float3(0.4, 0.45, 0.5);

    finalColor = clamp(finalColor, 0.0, 1.0);

    return half4(half3(finalColor), 1.0);
}
