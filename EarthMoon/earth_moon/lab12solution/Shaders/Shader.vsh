//
//  Shader.vsh
//  templateGLES3
//
//  Created by Mitja Hmeljak on 2018-01-24.
//  Copyright © 2018 B481/B581 Spring 2018. All rights reserved.
//

#version 300 es
//#include <cmath>

// define incoming variables:

uniform float u_FoV;
uniform float u_Aspect;
uniform float u_Near;
uniform float u_Far;

uniform int obj_flag;

//uniform int u_TransFlag;
uniform mat4 modelMat;
uniform mat4 viewMat;
uniform mat4 moonMat;
uniform mat4 earthlight;
uniform mat4 moonlight;
uniform vec3 halfplane;
uniform vec3 lightdirection;

in vec4 a_Position;
in vec2 a_TextureCoordinates;
in vec3 a_normal;



// define outgoing (varying) variables:

out vec2 var_Position;
out vec2 var_TextureCoordinates;
out vec4 light_color;

const float c_zero = 0.0;
const float c_one = 1.0;

//uniform material_properties material;
//uniform directional_light light;
//light
vec4 light_diffuse = vec4(0.4, 0.4, 0.4, 1.0);
vec3 light_direction = lightdirection;
vec4 light_ambient = vec4(0.4, 0.4, 0.4, 1.0);
vec3 half_plane = halfplane;
vec4 light_specular_color = vec4(0.1, 0.1, 0.1, 1.0);
//material
vec4 m_ambient_color = vec4(0.6, 0.6, 0.6, 1.0);
vec4 m_diffuse_color = vec4(0.3, 0.3, 0.3, 1.0);
vec4 m_specular_color = vec4(0.1, 0.1, 0.1, 1.0);
float m_specular_exponent;

vec4 directional_light_color (vec3 normal) {
    vec4 computed_color = vec4(c_zero, c_zero, c_zero, c_zero);

    m_specular_exponent = 0.1;
    float ndotl;
    float ndoth;

    ndotl = max(c_zero, dot(normal, light_direction));
    ndoth = max(c_zero, dot(normal, half_plane));

    computed_color += (light_ambient * m_ambient_color);
    computed_color += (ndotl * light_diffuse * m_diffuse_color);

    if (ndoth > c_zero) {
        computed_color += (pow(ndoth, m_specular_exponent) * m_specular_color * light_specular_color);
    }
    return computed_color;
}

mat4 myScale(float pSX, float pSY, float pSZ) {
    // the returned matrix is defined "transposed", i.e. the last row
    //   is really the last column as used in matrix multiplication:
    return mat4(  pSX,         0.0,         0.0,      0.0,
                0.0,         pSY,         0.0,      0.0,
                0.0,         0.0,         pSZ,      0.0,
                0.0,         0.0,         0.0,      1.0   );
}

// function that computes a 3D perspective transformation matrix:
mat4 myGLUPerspective(in float pFoV, in float pAspect, in float pNear, in float pFar)  {

    mat4 lPerspectiveMatrix = mat4(0.0);

    float lAngle = (pFoV / 180.0) * 3.14159;
    float lFocus = 1.0 / tan ( lAngle * 0.5 );


    lPerspectiveMatrix[0][0] = lFocus / pAspect;
    lPerspectiveMatrix[1][1] = lFocus;
    lPerspectiveMatrix[2][2] = (pFar + pNear) / (pNear - pFar);
    lPerspectiveMatrix[2][3] = -1.0;
    lPerspectiveMatrix[3][2] = (2.0 * pFar * pNear) / (pNear - pFar);

    return lPerspectiveMatrix;
}

void main() {

    //  define a projectionMatrix using myGLUPerspective()
    //  with perspective parameters as from uniform variables:
    mat4 projectionMatrix = myGLUPerspective(u_FoV, u_Aspect, u_Near, u_Far);

    mat4 viewMatrix;
    vec4 position = a_Position;
    vec4 newNormal = vec4(a_normal.x, a_normal.y,a_normal.z,1.0);
    switch (obj_flag) {
        case 1,3:
//            viewMatrix = myTranslate(0.0, 0.0, -30.0);
            viewMatrix = viewMat *  myScale(7.0, 7.0, 7.0) * modelMat;
            break;
        case 2,5: //Moon
            //            viewMatrix = myTranslate(0.0, 0.0, -30.0);
            viewMatrix = viewMat * moonMat;
            break;
        default:
            viewMatrix = viewMat;
            break;
    }
    

    // the predefined (and compulsory!) gl_Position variable is assigned a value:
    gl_Position = projectionMatrix * viewMatrix * a_Position;

    // the value for var_Position is set in this vertex shader,
    // then it goes through the interpolator before being
    // received (interpolated!) by a fragment shader:
    var_TextureCoordinates = a_TextureCoordinates;
    var_Position = gl_Position.xy;
    switch (obj_flag) {
        case 1,3:
            //            viewMatrix = myTranslate(0.0, 0.0, -30.0);
            newNormal = projectionMatrix * earthlight  *  myScale(7.0, 7.0, 7.0) * newNormal;
            break;
        case 2,5: //Moon
            //            viewMatrix = myTranslate(0.0, 0.0, -30.0);
            newNormal = projectionMatrix  * moonlight *  myScale(7.0, 7.0, 7.0) * newNormal;
            break;
        default:
            break;
    }
    
    //vec3 normal = vec3(gl_Position.x, gl_Position.y, gl_Position.z);
    light_color = directional_light_color(vec3(newNormal.x, newNormal.y, newNormal.z));
    //light_color = vec4(1.0, 0.0, 0.0, 1.0);
}

