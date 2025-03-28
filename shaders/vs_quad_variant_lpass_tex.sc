/*
 * Quad vertex shader variant: lighting pass, textured
 */

// Multiple render target lighting
#define QUAD_VARIANT_MRT_LIGHTING 1
#define QUAD_VARIANT_MRT_LINEAR_DEPTH 0
#define QUAD_VARIANT_MRT_TRANSPARENCY 0
#define QUAD_VARIANT_MRT_SHADOW_PACK 0
#define QUAD_VARIANT_MRT_SHADOW_SAMPLE 0

// Textured
#define QUAD_VARIANT_TEX 1
#define QUAD_VARIANT_CUTOUT 0

#include "./vs_quad_common.sh"