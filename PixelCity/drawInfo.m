//
// File:		drawInfo.m
//
// Abstract:	Creates and maintains the texture with the strings describing
//				the capabilities of the graphics card.
//
// Version:		1.1 - updated list of extensions and minor mostly cosmetic fixes.
//				1.0 - Original release.
//				
//
// Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//				in consideration of your agreement to the following terms, and your use,
//				installation, modification or redistribution of this Apple software
//				constitutes acceptance of these terms.  If you do not agree with these
//				terms, please do not use, install, modify or redistribute this Apple
//				software.
//
//				In consideration of your agreement to abide by the following terms, and
//				subject to these terms, Apple grants you a personal, non - exclusive
//				license, under Apple's copyrights in this original Apple software ( the
//				"Apple Software" ), to use, reproduce, modify and redistribute the Apple
//				Software, with or without modifications, in source and / or binary form
//				provided that if you redistribute the Apple Software in its entirety and
//				without modifications, you must retain this notice and the following text
//				and disclaimers in all such redistributions of the Apple Software. Neither
//				the name, trademarks, service marks or logos of Apple Inc. may be used to
//				endorse or promote products derived from the Apple Software without specific
//				prior written permission from Apple.  Except as expressly stated in this
//				notice, no other rights or licenses, express or implied, are granted by
//				Apple herein, including but not limited to any patent rights that may be
//				infringed by your derivative works or by other works in which the Apple
//				Software may be incorporated.
//
//				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//				WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//				PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//				ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//				CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//				SUBSTITUTE GOODS OR SERVICE LOSS OF USE, DATA, OR PROFIT OR BUSINESS
//				INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//				AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//				UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//				OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2003-2007 Apple Inc. All Rights Reserved.
//

#import "GLCheck.h"
#import "GLString.h"
#import "drawInfo.h"

static void addCapText(BOOL capExists, NSMutableAttributedString *outString, NSString *capText, NSDictionary *attribs)
{
    if (capExists) {
        NSAttributedString *appendString = [[NSAttributedString alloc] initWithString:capText attributes:attribs];
        [outString appendAttributedString:appendString];
    }
}

NSArray *createCapsTextures (GLCaps * displayCaps, CGDisplayCount numDisplays)
{
	short theIndex;
	NSMutableArray *capsTextures = [NSMutableArray arrayWithCapacity: numDisplays];
	
	// draw info
    NSMutableDictionary *bold12Attribs = [NSMutableDictionary dictionary];
    [bold12Attribs setObject: [NSFont fontWithName: @"Helvetica-Bold" size: 12.0f] forKey: NSFontAttributeName];
    [bold12Attribs setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];
 
    NSMutableDictionary *bold9Attribs = [NSMutableDictionary dictionary];
    [bold9Attribs setObject: [NSFont fontWithName: @"Helvetica-Bold" size: 9.0f] forKey: NSFontAttributeName];
    [bold9Attribs setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];
 
	NSMutableDictionary *normal9Attribs = [NSMutableDictionary dictionary];
    [normal9Attribs setObject: [NSFont fontWithName: @"Helvetica" size: 9.0f] forKey: NSFontAttributeName];
    [normal9Attribs setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];

	for (theIndex = 0; theIndex < numDisplays; theIndex++) {
		
		// draw caps string
		NSMutableAttributedString *outString = [[NSMutableAttributedString alloc] initWithString:@"GL Capabilities:" attributes:bold12Attribs];
		
		NSMutableAttributedString *appendString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n  Max VRAM- %d MB (%d MB free)",
                                                                                                     displayCaps[theIndex].deviceVRAM / 1024 / 1024,
                                                                                                     displayCaps[theIndex].deviceTextureRAM / 1024 / 1024]
                                                                                         attributes:normal9Attribs];
		[outString appendAttributedString:appendString];
	
		appendString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n  Max Texture Size- 1D/2D: %d, 3D: %d, Cube: %d, Rect: %d (%d texture units)", displayCaps[theIndex].maxTextureSize, displayCaps[theIndex].max3DTextureSize, displayCaps[theIndex].maxCubeMapTextureSize, displayCaps[theIndex].maxRectTextureSize, displayCaps[theIndex].textureUnits] attributes:normal9Attribs];
		[outString appendAttributedString:appendString];

		addCapText(YES, outString, @"\n Features:", bold9Attribs);
        addCapText(displayCaps[theIndex].fAuxDeptStencil, outString, @"\n  Aux depth and stencil (GL_APPLE_aux_depth_stencil)", normal9Attribs);
		addCapText(displayCaps[theIndex].fClientStorage, outString, @"\n  Client Storage (GL_APPLE_client_storage)", normal9Attribs);
		addCapText(displayCaps[theIndex].fElementArray, outString, @"\n  Element Array (GL_APPLE_element_array)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFence, outString, @"\n  Fence (GL_APPLE_fence)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFloatPixels, outString, @"\n  Floating Point Pixels (GL_APPLE_float_pixels)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFlushBufferRange, outString, @"\n  Selective VBO flushing (GL_APPLE_flush_buffer_range)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFlushRenderer, outString, @"\n  Flush Renderer (GL_APPLE_flush_render)", normal9Attribs);
        addCapText(displayCaps[theIndex].fObjectPurgeable, outString, @"\n  Object Purgeability (GL_APPLE_object_purgeable)", normal9Attribs);
		addCapText(displayCaps[theIndex].fPackedPixels, outString, @"\n  Packed Pixels (GL_APPLE_packed_pixels or OpenGL 1.2+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fPixelBuffer, outString, @"\n  Pixel Buffers (GL_APPLE_pixel_buffer)", normal9Attribs);
		addCapText(displayCaps[theIndex].fSpecularVector, outString, @"\n  Specular Vector (GL_APPLE_specular_vector)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTextureRange, outString, @"\n  Texture Range (AGP Texturing) (GL_APPLE_texture_range)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTransformHint, outString, @"\n  Transform Hint (GL_APPLE_transform_hint)", normal9Attribs);
		addCapText(displayCaps[theIndex].fVAO, outString, @"\n  Vertex Array Object (GL_APPLE_vertex_array_object)", normal9Attribs);
		addCapText(displayCaps[theIndex].fVAR, outString, @"\n  Vertex Array Range (GL_APPLE_vertex_array_range)", normal9Attribs);
		addCapText(displayCaps[theIndex].fVPEvals, outString, @"\n  Vertex Program Evaluators (GL_APPLE_vertex_program_evaluators)", normal9Attribs);
		addCapText(displayCaps[theIndex].fYCbCr, outString, @"\n  YCbCr Textures (GL_APPLE_ycbcr_422)", normal9Attribs);
		addCapText(displayCaps[theIndex].fDepthTex, outString, @"\n  Depth Texture (GL_ARB_depth_texture or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fDrawBuffers, outString, @"\n  Multiple Render Targets (GL_ARB_draw_buffers or OpenGL 2.0+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFragmentProg, outString, @"\n  Fragment Program (GL_ARB_fragment_program)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFragmentProgShadow, outString, @"\n  Fragment Program Shadows (GL_ARB_fragment_program_shadow)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFragmentShader, outString, @"\n  Fragment Shaders (GL_ARB_fragment_shader or OpenGL 2.0+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fHalfFloatPixel, outString, @"\n  Half Float Pixels (GL_ARB_half_float_pixel)", normal9Attribs);
		addCapText(displayCaps[theIndex].fImaging, outString, @"\n  Imaging Subset (GL_ARB_imaging)", normal9Attribs);
		addCapText(displayCaps[theIndex].fMultisample, outString, @"\n  Multisample (Anti-aliasing) (GL_ARB_multisample or OpenGL 1.3+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fMultitexture, outString, @"\n  Multitexture (GL_ARB_multitexture or OpenGL 1.3+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fOcclusionQuery, outString, @"\n  Occlusion Queries (GL_ARB_occlusion_query or OpenGL 1.5+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fPBO, outString, @"\n  Pixel Buffer Objects (GL_ARB_pixel_buffer_object or OpenGL 2.1+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fPointParam, outString, @"\n  Point Parameters (GL_ARB_point_parameters or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fPointSprite, outString, @"\n  Point Sprites (GL_ARB_point_sprite or OpenGL 2.0+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fShaderObjects, outString, @"\n  Shader Objects (GL_ARB_shader_objects or OpenGL 2.0+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fShaderTextureLOD, outString, @"\n  Shader Texture LODs (GL_ARB_shader_texture_lod)", normal9Attribs);
		addCapText(displayCaps[theIndex].fShadingLanguage100, outString, @"\n  Shading Language 1.0 (GL_ARB_shading_language_100 or OpenGL 2.0+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fShadow, outString, @"\n  Shadow Support (GL_ARB_shadow or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fShadowAmbient, outString, @"\n  Shadow Ambient (GL_ARB_shadow_ambient)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexBorderClamp, outString, @"\n  Texture Border Clamp (GL_ARB_texture_border_clamp or OpenGL 1.3+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexCompress, outString, @"\n  Texture Compression (GL_ARB_texture_compression or OpenGL 1.3+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexCubeMap, outString, @"\n  Texture Env Cube Map (GL_ARB_texture_cube_map or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexEnvAdd, outString, @"\n  Texture Env Add (GL_ARB_texture_env_add, GL_EXT_texture_env_add or OpenGL 1.3+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexEnvCombine, outString, @"\n  Texture Env Combine (GL_ARB_texture_env_combine or OpenGL 1.3+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexEnvCrossbar, outString, @"\n  Texture Env Crossbar (GL_ARB_texture_env_crossbar or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexEnvDot3, outString, @"\n  Texture Env Dot3 (GL_ARB_texture_env_dot3 or OpenGL 1.3+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexFloat, outString, @"\n  Floating Point Textures (GL_ARB_texture_float)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexMirrorRepeat, outString, @"\n  Texture Mirrored Repeat (GL_ARB_texture_mirrored_repeat or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexNPOT, outString, @"\n  Non Power of Two Textures (GL_ARB_texture_non_power_of_two or OpenGL 2.0+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexRectARB, outString, @"\n  Texture Rectangle (GL_ARB_texture_rectangle)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTransposeMatrix, outString, @"\n  Transpose Matrix (GL_ARB_transpose_matrix or OpenGL 1.3+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fVertexBlend, outString, @"\n  Vertex Blend (GL_ARB_vertex_blend)", normal9Attribs);
		addCapText(displayCaps[theIndex].fVBO, outString, @"\n  Vertex Buffer Objects (GL_ARB_vertex_buffer_object or OpenGL 1.5+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fVertexProg, outString, @"\n  Vertex Program (GL_ARB_vertex_program)", normal9Attribs);
		addCapText(displayCaps[theIndex].fVertexShader, outString, @"\n  Vertex Shaders (GL_ARB_vertex_shader or OpenGL 2.0+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fWindowPos, outString, @"\n  Window Position (GL_ARB_window_pos or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fArrayRevComps4Byte, outString, @"\n  Reverse 4 Byte Array Components (GL_ATI_array_rev_comps_in_4_bytes)", normal9Attribs);
		addCapText(displayCaps[theIndex].fATIBlendEqSep, outString, @"\n  Separate Blend Equations (GL_ATI_blend_equation_separate)", normal9Attribs);
		addCapText(displayCaps[theIndex].fBlendWeightMinMax, outString, @"\n  Blend Weighted Min/Max (GL_ATI_blend_weighted_minmax)", normal9Attribs);
		addCapText(displayCaps[theIndex].fPNtriangles, outString, @"\n  PN Triangles (GL_ATI_pn_triangles or GL_ATIX_pn_triangles)", normal9Attribs);
		addCapText(displayCaps[theIndex].fPointCull, outString, @"\n  Point Culling (GL_ATI_point_cull_mode)", normal9Attribs);
		addCapText(displayCaps[theIndex].fSepStencil, outString, @"\n  Separate Stencil (GL_ATI_separate_stencil)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTextFragShader, outString, @"\n  Text Fragment Shader (GL_ATI_text_fragment_shader)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexComp3dc, outString, @"\n  ATI 3dc Compressed Textures (GL_ATI_texture_compression_3dc)", normal9Attribs);
		addCapText(displayCaps[theIndex].fCombine3, outString, @"\n  Texture Env Combine 3 (GL_ATI_texture_env_combine3)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexATIfloat, outString, @"\n  ATI Floating Point Textures (GL_ATI_texture_float)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexMirrorOnce, outString, @"\n  Texture Mirror Once (GL_ATI_texture_mirror_once)", normal9Attribs);
		addCapText(displayCaps[theIndex].fABGR, outString, @"\n  ABGR Texture Support (GL_EXT_abgr)", normal9Attribs);
		addCapText(displayCaps[theIndex].fBGRA, outString, @"\n  BGRA Texture Support (GL_EXT_bgra or OpenGL 1.2+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fBlendColor, outString, @"\n  Blend Color (GL_EXT_blend_color or GL_ARB_imaging)", normal9Attribs);
		addCapText(displayCaps[theIndex].fBlendEqSep, outString, @"\n  Separate Blending Equations for RGB and Alpha (GL_EXT_blend_equation_separate or OpenGL 2.0+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fBlendFuncSep, outString, @"\n  Separate Blend Function (GL_EXT_blend_func_separate or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fBlendMinMax, outString, @"\n  Blend Min/Max (GL_EXT_blend_minmax or GL_ARB_imaging)", normal9Attribs);
		addCapText(displayCaps[theIndex].fBlendSub, outString, @"\n  Blend Subtract (GL_EXT_blend_subtract or GL_ARB_imaging)", normal9Attribs);
		addCapText(displayCaps[theIndex].fClipVolHint, outString, @"\n  Clip Volume Hint (GL_EXT_clip_volume_hint)", normal9Attribs);
		addCapText(displayCaps[theIndex].fColorSubtable, outString, @"\n  Color Subtable ( GL_EXT_color_subtable or GL_ARB_imaging)", normal9Attribs);
		addCapText(displayCaps[theIndex].fCVA, outString, @"\n  Compiled Vertex Array (GL_EXT_compiled_vertex_array)", normal9Attribs);
		addCapText(displayCaps[theIndex].fDepthBounds, outString, @"\n  Depth Boundary Test (GL_EXT_depth_bounds_test)", normal9Attribs);
		addCapText(displayCaps[theIndex].fConvolution, outString, @"\n  Convolution ( GL_EXT_convolution or GL_ARB_imaging)", normal9Attribs);
		addCapText(displayCaps[theIndex].fDrawRangeElements, outString, @"\n  Draw Range Elements (GL_EXT_draw_range_elements)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFogCoord, outString, @"\n  Fog Coordinate (GL_EXT_fog_coord)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFBOblit, outString, @"\n  FBO Blit (GL_EXT_framebuffer_blit)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFBO, outString, @"\n  Framebuffer Objects or FBOs (GL_EXT_framebuffer_object)", normal9Attribs);
		addCapText(displayCaps[theIndex].fGeometryShader4, outString, @"\n  4th Gen Geometry Shader (GL_EXT_geometry_shader4)", normal9Attribs);
		addCapText(displayCaps[theIndex].fGPUProgParams, outString, @"\n  GPU Program Parameters (GL_EXT_gpu_program_parameters)", normal9Attribs);
		addCapText(displayCaps[theIndex].fGPUShader4, outString, @"\n  4th Gen GPU Shaders (GL_EXT_gpu_shader4)", normal9Attribs);
		addCapText(displayCaps[theIndex].fHistogram, outString, @"\n  Histogram ( GL_EXT_histogram or GL_ARB_imaging)", normal9Attribs);
		addCapText(displayCaps[theIndex].fDepthStencil, outString, @"\n  Packed Depth and Stencil (GL_EXT_packed_depth_stencil)", normal9Attribs);
		addCapText(displayCaps[theIndex].fMultiDrawArrays, outString, @"\n  Multi-Draw Arrays (GL_EXT_multi_draw_arrays or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fPaletteTex, outString, @"\n  Paletted Textures (GL_EXT_paletted_texture)", normal9Attribs);
		addCapText(displayCaps[theIndex].fRescaleNorm, outString, @"\n  Rescale Normal (GL_EXT_rescale_normal or OpenGL 1.2+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fSecColor, outString, @"\n  Secondary Color (GL_EXT_secondary_color or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fSepSpecColor, outString, @"\n  Separate Specular Color (GL_EXT_separate_specular_color or OpenGL 1.2+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fShadowFunc, outString, @"\n  Shadow Function (GL_EXT_shadow_funcs)", normal9Attribs);
		addCapText(displayCaps[theIndex].fShareTexPalette, outString, @"\n  Shared Texture Palette (GL_EXT_shared_texture_palette)", normal9Attribs);
		addCapText(displayCaps[theIndex].fStencil2Side, outString, @"\n  2-Sided Stencil (GL_EXT_stencil_two_side)", normal9Attribs);
		addCapText(displayCaps[theIndex].fStencilWrap, outString, @"\n  Stencil Wrap (GL_EXT_stencil_wrap or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexCompDXT1, outString, @"\n  DXT Compressed Textures (GL_EXT_texture_compression_dxt1)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTex3D, outString, @"\n  3D Texturing (GL_EXT_texture3D or OpenGL 1.2+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexCompressS3TC, outString, @"\n  Texture Compression S3TC (GL_EXT_texture_compression_s3tc)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexFilterAniso, outString, @"\n  Anisotropic Texture Filtering (GL_EXT_texture_filter_anisotropic)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexLODBias, outString, @"\n  Texture Level Of Detail Bias (GL_EXT_texture_lod_bias or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexMirrorClamp, outString, @"\n  Texture mirror clamping (GL_EXT_texture_mirror_clamp)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexRect, outString, @"\n  Texture Rectangle (GL_EXT_texture_rectangle)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexSRGB, outString, @"\n  sRGB Textures (GL_EXT_texture_sRGB or OpenGL 2.1+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTransformFeedback, outString, @"\n  Transform Feedback (GL_EXT_transform_feedback)", normal9Attribs);
		addCapText(displayCaps[theIndex].fConvBorderModes, outString, @"\n  Convolution Border Modes (GL_HP_convolution_border_modes or GL_ARB_imaging)", normal9Attribs);
		addCapText(displayCaps[theIndex].fRasterPosClip, outString, @"\n  Raster Position Clipping (GL_IBM_rasterpos_clip)", normal9Attribs);
		addCapText(displayCaps[theIndex].fBlendSquare, outString, @"\n  Blend Square (GL_NV_blend_square or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fDepthClamp, outString, @"\n  Depth Clamp (GL_NV_depth_clamp)", normal9Attribs);
		addCapText(displayCaps[theIndex].fFogDist, outString, @"\n  Eye Radial Fog Distance (GL_NV_fog_distance)", normal9Attribs);
		addCapText(displayCaps[theIndex].fLightMaxExp, outString, @"\n  Light Max Exponent (GL_NV_light_max_exponent)", normal9Attribs);
		addCapText(displayCaps[theIndex].fMultisampleFilterHint, outString, @"\n  Multi-Sample Filter Hint (GL_NV_multisample_filter_hint)", normal9Attribs);
		addCapText(displayCaps[theIndex].fNVPointSprite, outString, @"\n  NV Point Sprites (GL_NV_point_sprite)", normal9Attribs);
		addCapText(displayCaps[theIndex].fRegCombiners, outString, @"\n  Register Combiners (GL_NV_register_combiners)", normal9Attribs);
		addCapText(displayCaps[theIndex].fRegCombiners2, outString, @"\n  Register Combiners 2 (GL_NV_register_combiners2)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexGenReflect, outString, @"\n  TexGen Reflection (GL_NV_texgen_reflection)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexEnvCombine4, outString, @"\n  Texture Env Combine 4 (GL_NV_texture_env_combine4)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexShader, outString, @"\n  Texture Shader (GL_NV_texture_shader)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexShader2, outString, @"\n  Texture Shader 2 (GL_NV_texture_shader2)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexShader3, outString, @"\n  Texture Shader 3 (GL_NV_texture_shader3)", normal9Attribs);
		addCapText(displayCaps[theIndex].fGenMipmap, outString, @"\n  MipMap Generation (GL_SGIS_generate_mipmap or OpenGL 1.4+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexEdgeClamp, outString, @"\n  Texture Edge Clamp (GL_SGIS_texture_edge_clamp or OpenGL 1.2+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fTexLOD, outString, @"\n  Texture Level Of Detail (GL_SGIS_texture_lod or OpenGL 1.2+)", normal9Attribs);
		addCapText(displayCaps[theIndex].fColorMatrix, outString, @"\n  Color Matrix ( GL_SGI_color_matrix or GL_ARB_imaging)", normal9Attribs);
		addCapText(displayCaps[theIndex].fColorTable, outString, @"\n  Color Table ( GL_SGI_color_table or GL_ARB_imaging)", normal9Attribs);
		
		GLString *capsTexture = [[GLString alloc] initWithAttributedString:outString
                                                                 textColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f]
                                                                  boxColor:[NSColor colorWithDeviceRed:0.4f green:0.4f blue:0.0f alpha:0.4f]
                                                               borderColor:[NSColor colorWithDeviceRed:0.8f green:0.8f blue:0.0f alpha:0.8f]];
		[capsTextures addObject:capsTexture];
	}
    return capsTextures;
}

void drawCaps (GLCaps * displayCaps, CGDisplayCount numDisplays, GLlong renderer, GLfloat width) // view width for drawing location
{ // we are already in an orthographic per pixel projection
    NSArray *capsTextures = createCapsTextures(displayCaps, numDisplays);
	short i;
	// match display in caps list
	for (i = 0; i < numDisplays; i++) {
		if (renderer == displayCaps[i].rendererID) {
			GLString *capsTexture = [capsTextures objectAtIndex:i];
			[capsTexture drawAtPoint:NSMakePoint (width - 10.0f - [capsTexture frameSize].width, 10.0f)];
            NSLog(@"%@", capsTexture);
			break;
		}
	}
}
