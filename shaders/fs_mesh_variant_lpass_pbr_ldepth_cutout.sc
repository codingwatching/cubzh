/*
 * Mesh fragment shader variant: lighting pass, pbr, linear depth, cutout
 */

// Multiple render target lighting w/ pbr and linear depth
#define MESH_VARIANT_MRT_LIGHTING 1
#define MESH_VARIANT_MRT_LINEAR_DEPTH 1
#define MESH_VARIANT_MRT_PBR 1

// No alpha
#define MESH_VARIANT_ALPHA 0

// Cutout
#define MESH_VARIANT_CUTOUT 1

#include "./fs_mesh_common.sh"