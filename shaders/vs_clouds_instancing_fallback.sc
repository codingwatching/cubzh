/*
 * Instanced clouds vertex shader fallback
 */

// No compute, instances are static
#define SKY_VARIANT_COMPUTE 0

// No multiple render target
#define SKY_VARIANT_MRT_LIGHTING 0
#define SKY_VARIANT_MRT_LINEAR_DEPTH 0

#include "./vs_clouds_instancing_common.sh"
