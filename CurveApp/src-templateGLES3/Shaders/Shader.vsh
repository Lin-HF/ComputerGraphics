//
//  Shader.vsh
//  templateGLES3
//
//  Created by Mitja Hmeljak on 2018-01-24.
//  Copyright © 2018 B481/B581 Spring 2018. All rights reserved.
//

#version 300 es

// define incoming variables:

uniform float u_Width;
uniform float u_Height;
uniform vec4 P1;
uniform vec4 P2;
uniform vec4 P3;
uniform vec4 P4;
uniform int flag;
uniform float u_pointSize;

in vec4 a_Position;


// a function to compute 2D orthogonal projection:
mat4 myOrtho2D(float pLeft, float pRight, float pBottom, float pTop) {
    float lNear = -1.0;
    float lFar = 1.0;
    float rl = pRight-pLeft;
    float tb = pTop-pBottom;
    float fn = lFar-lNear;
    // the returned matrix is defined "transposed", i.e. the last row
    //   is really the last column as used in matrix multiplication:
    return mat4(  2.0/rl,                0.0,              0.0,  0.0,
                0.0,             2.0/tb,              0.0,  0.0,
                0.0,                0.0,          -2.0/fn,  0.0,
                -(pRight+pLeft)/rl, -(pTop+pBottom)/tb, -(lFar+lNear)/fn,  1.0 );
}

// define an outgoing variable:
out vec2 var_Position;


// the main program for the Vertex Shader
void main() {
    
    gl_PointSize = u_pointSize;
    vec4 real_Position;
    if (flag != 0) {
        float t = a_Position[0];
        vec4 param_t = vec4(t*t*t, t*t, t, 1);
        mat4 Matrix;
        if (flag == 1) {
            Matrix = mat4( -1.0 ,   3.0, -3.0 , 1.0,
                          3.0 , -6.0 ,  3.0 , 0.0,
                          -3.0 ,  3.0 ,  0.0 , 0.0,
                          1.0 ,  0.0 ,  0.0 , 0.0 );
        } else if (flag == 2) {
            Matrix = 0.5 * mat4( -1.0 ,   2.0, -1.0 , 0.0,
                                3.0 , -5.0 ,  0.0 , 2.0,
                                -3.0 ,  4.0 ,  1.0 , 0.0,
                                1.0 , -1.0 ,  0.0 , 0.0 );
        } else {
            Matrix = (1.0/6.0) * mat4( -1.0 ,   3.0, -3.0 , 1.0,
                                      3.0 , -6.0 ,  0.0 , 4.0,
                                      -3.0 ,  3.0 ,  3.0 , 1.0,
                                      1.0 ,  0.0 ,  0.0 , 0.0 );
        }
        
        vec4 x = param_t * Matrix * vec4(P1[0], P2[0], P3[0], P4[0]);
        vec4 y = param_t * Matrix * vec4(P1[1], P2[1], P3[1], P4[1]);
        real_Position = vec4((x[0]+x[1]+x[2]+x[3]), (y[0]+y[1]+y[2]+y[3]), 0, 1);
    } else {
        real_Position = a_Position;
    }
    
    
    mat4 projectionMatrix = myOrtho2D(0.0, u_Width, 0.0, u_Height);
    
    // gl_PointSize = 10.0;
    
    gl_Position = projectionMatrix * real_Position;
    
    // the value for var_Position is set in this vertex shader,
    // then it goes through the interpolator before being
    // received (interpolated!) by a fragment shader:
    var_Position = gl_Position.xy;
}

