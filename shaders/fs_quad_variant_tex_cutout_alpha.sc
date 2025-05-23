/*
 * Quad fragment shader variant: textured, cutout, alpha
 */

// No multiple render target
#define QUAD_VARIANT_MRT_LIGHTING 0
#define QUAD_VARIANT_MRT_LINEAR_DEPTH 0
#define QUAD_VARIANT_MRT_PBR 0

// Textured cutout
#define QUAD_VARIANT_TEX 1
#define QUAD_VARIANT_CUTOUT 1

// Use alpha
#define QUAD_VARIANT_ALPHA 1

#include "./fs_quad_common.sh"