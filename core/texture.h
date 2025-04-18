// -------------------------------------------------------------
//  Cubzh Core
//  texture.h
//  Created by Arthur Cormerais on February 25, 2025.
// -------------------------------------------------------------

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stdint.h>

#include "weakptr.h"

typedef enum {
    TextureType_Albedo,
    TextureType_Normal,
    TextureType_Metallic,
    TextureType_Emissive,
    TextureType_Cubemap
} TextureType;

typedef struct _Texture Texture;

Texture* texture_new_raw(const void* data, const uint32_t size, const TextureType type);
Texture* texture_new_cubemap_faces(const void* top, const void* bottom, const void* front, const void* back, const void* right, const void* left,
                                   const uint32_t faceSize, const uint32_t width, const uint32_t height, const uint8_t format);
void texture_free(Texture* t);
bool texture_retain(Texture* t);
void texture_release(Texture* t);

void texture_set_parsed_data(Texture* t, const void* data, const uint32_t size, const uint32_t width, const uint32_t height, const uint8_t format);
const void* texture_get_data(const Texture* t);
uint32_t texture_get_data_size(const Texture* t);
bool texture_is_raw(const Texture* t);
uint32_t texture_get_width(const Texture* t);
uint32_t texture_get_height(const Texture* t);
TextureType texture_get_type(const Texture* t);
uint8_t texture_get_format(const Texture* t);
uint32_t texture_get_data_hash(const Texture* t);
uint32_t texture_get_rendering_hash(const Texture* t);
Weakptr *texture_get_weakptr(Texture *t);
Weakptr *texture_get_and_retain_weakptr(Texture *t);
void texture_set_filtering(Texture* t, bool value);
bool texture_has_filtering(const Texture* t);

#ifdef __cplusplus
}
#endif 