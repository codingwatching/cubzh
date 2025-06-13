// -------------------------------------------------------------
//  Cubzh Core
//  quad.h
//  Created by Arthur Cormerais on May 3, 2023.
// -------------------------------------------------------------

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stdio.h>

#include "float3.h"
#include "transform.h"

typedef struct _Quad Quad;

Quad *quad_new(void);
Quad *quad_new_copy(const Quad* q);
void quad_release(Quad *q);
void quad_free(Quad *q); // called in transform_release, does not free transform

Transform *quad_get_transform(const Quad *q);
void quad_set_data(Quad *q, Weakptr *data, uint32_t size);
void *quad_get_data(const Quad *q);
uint32_t quad_get_data_size(const Quad *q);
uint32_t quad_get_data_hash(const Quad *q);
void quad_set_width(Quad *q, float value);
float quad_get_width(const Quad *q);
void quad_set_height(Quad *q, float value);
float quad_get_height(const Quad *q);
void quad_set_anchor_x(Quad *q, float value);
float quad_get_anchor_x(const Quad *q);
void quad_set_anchor_y(Quad *q, float value);
float quad_get_anchor_y(const Quad *q);
void quad_set_tiling_u(Quad *q, float value);
float quad_get_tiling_u(const Quad *q);
void quad_set_tiling_v(Quad *q, float value);
float quad_get_tiling_v(const Quad *q);
void quad_set_offset_u(Quad *q, float value);
float quad_get_offset_u(const Quad *q);
void quad_set_offset_v(Quad *q, float value);
float quad_get_offset_v(const Quad *q);
void quad_set_cutout(Quad *q, float value);
float quad_get_cutout(const Quad *q);
void quad_set_color(Quad *q, uint32_t color);
uint32_t quad_get_color(const Quad *q);
void quad_set_vertex_color(Quad *q, uint32_t c, uint8_t idx);
uint32_t quad_get_vertex_color(const Quad *q, uint8_t idx);
bool quad_uses_vertex_colors(const Quad *q);
void quad_set_layers(Quad *q, uint16_t value);
uint16_t quad_get_layers(const Quad *q);
void quad_set_doublesided(Quad *q, bool toggle);
bool quad_is_doublesided(const Quad *q);
void quad_set_shadow(Quad *q, bool toggle);
bool quad_has_shadow(const Quad *q);
void quad_set_unlit(Quad *q, bool toggle);
bool quad_is_unlit(const Quad *q);
void quad_set_mask(Quad *q, bool toggle);
bool quad_is_mask(const Quad *q);
void quad_set_alpha_blending(Quad *q, bool toggle);
bool quad_uses_alpha_blending(const Quad *q);
void quad_set_filtering(Quad *q, bool toggle);
bool quad_uses_filtering(const Quad *q);
void quad_set_sort_order(Quad *q, uint8_t value);
uint8_t quad_get_sort_order(const Quad *q);
void quad_set_9slice(Quad *q, bool toggle);
bool quad_uses_9slice(const Quad *q);
void quad_set_9slice_uv(Quad *q, float u, float v);
float quad_get_9slice_u(const Quad *q);
float quad_get_9slice_v(const Quad *q);
void quad_set_9slice_scale(Quad *q, float value);
float quad_get_9slice_scale(const Quad *q);
void quad_set_9slice_corner_width(Quad *q, float value);
float quad_get_9slice_corner_width(const Quad *q);

// MARK: - Utils -

float quad_utils_get_diagonal(const Quad *q);
bool quad_utils_get_visibility(const Quad *q, bool *isOpaque);

#ifdef __cplusplus
} // extern "C"
#endif
