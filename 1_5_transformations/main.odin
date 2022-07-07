package main

import glm "core:math/linalg/glsl"

import gl "vendor:OpenGl"
import "vendor:glfw"
import stbi "vendor:stb/image"

main :: proc() {
	glfw.Init()
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	// Create a window
	window := glfw.CreateWindow(800, 600, "LearnOpenGL Odin", nil, nil)
	if window == nil {
		panic("Failed to create GLFW window")
	}
	defer glfw.DestroyWindow(window)

	// Set window callbacks and load GL
	glfw.MakeContextCurrent(window)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	// Compile shaders
	vert_src := string(#load("./shader.vert"))
	frag_src := string(#load("./shader.frag"))
	program, ok := gl.load_shaders_source(vert_src, frag_src)
	if !ok {
		panic("Shader compilation failed")
	}
	defer gl.DeleteProgram(program)

	// Create vertex and index buffers
	vertices := [4][5]f32 {
		{0.5, 0.5, 0.0, 1.0, 1.0}, // top right
		{0.5, -0.5, 0.0, 1.0, 0.0}, // bottom right
		{-0.5, -0.5, 0.0, 0.0, 0.0}, // bottom left
		{-0.5, 0.5, 0.0, 0.0, 1.0}, // top left 
	}
	indices := [6]i32{0, 1, 3, 1, 2, 3}

	vbo, vao, ebo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)
	defer gl.DeleteVertexArrays(1, &vao)
	defer gl.DeleteBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &ebo)

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0][0], gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of([5]f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of([5]f32), size_of([3]f32))
	gl.EnableVertexAttribArray(1)

	// Load image and create texture
	tex1, tex2: u32
	width, height, chans: i32
	gl.GenTextures(1, &tex1)
	gl.BindTexture(gl.TEXTURE_2D, tex1)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	im_data := stbi.load("images/container.jpg", &width, &height, &chans, 0)
	if im_data == nil {
		panic("Failed to load image")
	}
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, im_data)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	stbi.image_free(im_data)

	gl.GenTextures(1, &tex2)
	gl.BindTexture(gl.TEXTURE_2D, tex2)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	stbi.set_flip_vertically_on_load(1)
	im_data = stbi.load("images/awesomeface.png", &width, &height, &chans, 0)
	if im_data == nil {
		panic("Failed to load image")
	}
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, im_data)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	stbi.image_free(im_data)

	// Bind the texture uniforms
	gl.UseProgram(program)
	gl.Uniform1i(gl.GetUniformLocation(program, "texture1"), 0)
	gl.Uniform1i(gl.GetUniformLocation(program, "texture2"), 1)

	// Render
	for !glfw.WindowShouldClose(window) {
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		// Clear the frame buffer
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// Bind the textures
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, tex1)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, tex2)

		// Compute and apply uniforms
		gl.UseProgram(program)
		translation := glm.mat4Translate(glm.vec3{0.5, -0.5, 0.0})
		rotation := glm.mat4Rotate(glm.vec3{0.0, 0.0, 1.0}, f32(glfw.GetTime()))
		transform := translation * rotation
		transform_loc := gl.GetUniformLocation(program, "transform")
		gl.UniformMatrix4fv(transform_loc, 1, false, &transform[0][0])

		// Draw the geometry
		gl.BindVertexArray(vao)
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
