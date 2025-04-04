// -------------------------------------------------------------
//  Cubzh Core
//  material.h
//  Created by Arthur Cormerais on February 3, 2025.
// -------------------------------------------------------------

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stdint.h>

typedef struct _Material Material;
typedef struct _Texture Texture;

typedef enum {
    AlphaMode_Opaque,
    AlphaMode_Cutout,
    AlphaMode_Blend
} AlphaMode;

typedef enum {
    MaterialTexture_Albedo,
    MaterialTexture_Normal,
    MaterialTexture_Metallic,
    MaterialTexture_Emissive
#define MaterialTexture_Count 4
} MaterialTexture;

Material* material_new(void);
void material_free(Material* m);
bool material_retain(Material* m);
void material_release(Material* m);

void material_set_albedo(Material* m, const uint32_t rgba);
uint32_t material_get_albedo(const Material* m);
void material_set_metallic(Material* m, const float value);
float material_get_metallic(const Material* m);
void material_set_roughness(Material* m, const float value);
float material_get_roughness(const Material* m);
void material_set_emissive(Material* m, const uint32_t rgb);
uint32_t material_get_emissive(const Material* m);
void material_set_alpha_cutout(Material* m, const float value);
float material_get_alpha_cutout(const Material* m);
void material_set_opaque(Material* m, const bool value);
bool material_is_opaque(const Material* m);
void material_set_double_sided(Material* m, const bool value);
bool material_is_double_sided(const Material* m);
void material_set_unlit(Material* m, const bool value);
bool material_is_unlit(const Material* m);
void material_set_texture(Material* m, MaterialTexture slot, Texture* texture);
Texture* material_get_texture(const Material* m, MaterialTexture slot);
void material_set_filtering(Material* m, const bool value);
bool material_has_filtering(const Material* m);

#ifdef __cplusplus
}
#endif 