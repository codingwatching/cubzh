/*
 * Voxels fragment shader variant: lighting pass
 */

// Lit
#define VOXEL_VARIANT_UNLIT 0

// Multiple render target lighting
#define VOXEL_VARIANT_MRT_LIGHTING 1
#define VOXEL_VARIANT_MRT_LINEAR_DEPTH 0
#define VOXEL_VARIANT_MRT_PBR 0

// No draw modes
#define VOXEL_VARIANT_DRAWMODES 0

#include "./fs_voxels_common.sh"
