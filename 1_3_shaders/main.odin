package main

import gl "vendor:OpenGl"
import "vendor:glfw"

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

	// Create vertex buffers
	vertices := [24]f32{
		0.5, 0.5, 0.0, 1.0, 1.0, 1.0,
		0.5, -0.5, 0.0, 1.0, 0.0, 1.0,
		-0.5, -0.5, 0.0, 0.0, 0.0, 1.0,
		-0.5, 0.5, 0.0, 0.0, 1.0, 1.0}
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
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of([6]f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of([6]f32), size_of([3]f32))
	gl.EnableVertexAttribArray(1)

	// Render
	for !glfw.WindowShouldClose(window) {
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		// Clear the frame buffer
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// Draw the geometry
		gl.UseProgram(program)
		gl.BindVertexArray(vao)
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
