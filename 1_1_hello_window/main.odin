package main

import "core:fmt"
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

	// Render
	for !glfw.WindowShouldClose(window) {
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
