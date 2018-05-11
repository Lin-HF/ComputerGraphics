//
//  MyOpenGLESKitViewController.swift
//  templateGLES3
//
//  Created by Mitja Hmeljak on 2018-01-24.
//  Copyright © 2018 B481/B581 Spring 2018. All rights reserved.
//

import GLKit
import OpenGLES


// OpenGL ES requires the use of C-like pointers to "CPU memory",
// without the automated memory management provided by Swift:
func obtainUnsafePointer(_ i: Int) -> UnsafeRawPointer? {
    return UnsafeRawPointer(bitPattern: i)
}

var gVertexData: [GLfloat] = []
//High light vertex
var highlightVertextData: [GLfloat] = []
//High light line segment
var highlightLineData: [GLfloat] = []
var pretouch: [GLfloat] = []
let E_MODE_EDIT:GLint = 0
let E_MODE_PROXIMITY:GLint = 1
let E_MODE_INSERT:GLint = 2
var MODE = E_MODE_PROXIMITY
var moveIndex = -1

//var gVertexData: [GLfloat] = [
//
//    // vertex data structured thus:
//    //  positionX, positionY, etc.
//    //
//    100.0, 100.0,
//    200.0, 123.0
//]

var gColorData: [[GLfloat]] = [
    // color data in RGBA float format
    [0.0, 0.5, 0.0, 1.0],
    [0.5, 0.0, 0.0, 1.0],
    [0.0, 1.0, 0.0, 1.0],
    [1.0, 0.0, 0.0, 1.0],
    [1.0, 1.0, 1.0, 1.0]
]

var firstDerivative_1: [GLfloat] = [
    -1, -1, -1, -1
]

var firstDerivative_2: [GLfloat] = [
    -1, -1, -1, -1
]

var secondDerivative_1: [GLfloat] = [
    -1, -1, -1, -1
]

var secondDerivative_2: [GLfloat] = [
    -1, -1, -1, -1
]

var isdrawFisrt: Bool = false
var isdrawSecond: Bool = false

//Interpolation T
var t : [GLfloat] = []

var flag: GLint = 0
var curveFlag: GLint = 1
let BAZIER: GLint = 1
let CATMULLROM: GLint = 2
let B_SPLINE: GLint = 3
var step = 0


class MyOpenGLESKitViewController: GLKViewController {

    @IBAction func bazier(_ sender: Any) {
        curveFlag = BAZIER;

    }
    @IBAction func catmullrom(_ sender: Any) {
        curveFlag = CATMULLROM;

    }
    @IBAction func bspline(_ sender: Any) {
        curveFlag = B_SPLINE;

    }
    @IBAction func restart(_ sender: UIButton) {
        gVertexData.removeAll()
    }
    @IBAction func drawFirst(_ sender: UIButton) {
        isdrawFisrt = !isdrawFisrt
    }
    @IBAction func drawSecond(_ sender: UIButton) {
        isdrawSecond = !isdrawSecond
    }
    
    
    var myGLESProgram: GLuint = 0

    var myPosAttrib: GLuint = 0
    //
    var myControlAttr: GLint = 0
    //

    var myModelViewProjectionMatrix:GLKMatrix4 = GLKMatrix4Identity

    var myViewPortWidth:GLsizei = -1
    var myViewPortHeight:GLsizei = -1

    var myWidthUniform: GLint = 0
    var myHeightUniform: GLint = 0
    var myColorUniform: GLint = 0

    var myVertexArray: GLuint = 0
    var myVertexBuffer: GLuint = 0

    var myGLESContext: EAGLContext? = nil
    var myGLKView: GLKView? = nil

    // touch event data:
    var myTouchXbegin: GLfloat = -1.0
    var myTouchYbegin: GLfloat = -1.0
    var myTouchXcurrent: GLfloat = -1.0
    var myTouchYcurrent: GLfloat = -1.0
    var myTouchXold: GLfloat = -1.0
    var myTouchYold: GLfloat = -1.0
    var myTouchPhase: UITouchPhase? = nil
    
    var pointSize: GLint = 0

    // polygon build data:
    var myEnteredVertices = 0
    // Curve:
    var myP1: GLint = 0
    var myP2: GLint = 0
    var myP3: GLint = 0
    var myP4: GLint = 0
    var myFlag: GLint = 0

    // ------------------------------------------------------------------------
    deinit {
        self.tearDownGL()

        if EAGLContext.current() === self.myGLESContext {
            EAGLContext.setCurrent(nil)
        }
    }


    // ------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        for i in stride(from: 0, through: 1.0, by: 0.001) {
            t.append(GLfloat(i))
        }
        // This view controller's view has loaded.
        //   It's time to initialize OpenGL ES!

        // Initialize a newly allocated OpenGL ES *rendering context*
        //   with the specified version of the OpenGL ES rendering API:
        self.myGLESContext = EAGLContext(api: EAGLRenderingAPI.openGLES3)

        if !(self.myGLESContext != nil) {
            NSLog("EAGLContext failed to initialize OpenGL ES 3 context :-( ")
            return
        }

        // now that the OpenGL ES rendering context is available,
        //   set our (MyOpenGLESKitViewController's) view as a GL view:
        self.myGLKView = self.view as? GLKView
        // The GLKView directly manages a framebuffer object
        //   on our application’s behalf.
        // Our code just needs to draw into the framebuffer
        //   when the contents need to be updated.
        self.myGLKView!.context = self.myGLESContext!
        // set the *depth* (z-buffer)'s size:
        self.myGLKView!.drawableDepthFormat = GLKViewDrawableDepthFormat.formatNone
        // in 3D we'll often need the depth buffer, e.g.:
        // lView.drawableDepthFormat = GLKViewDrawableDepthFormat.Format24

        self.setupGL()

    } // end of viewDidLoad()

    // ------------------------------------------------------------------------
    // the system is running out of memory: clean up an abandon GLES
    // ------------------------------------------------------------------------
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        if self.isViewLoaded && (self.view.window != nil) {
            self.view = nil

            self.tearDownGL()

            if EAGLContext.current() === self.myGLESContext {
                EAGLContext.setCurrent(nil)
            }
            self.myGLESContext = nil
        }
    } // end of didReceiveMemoryWarning()


    // ------------------------------------------------------------------------
    // initialize OpenGL ES:
    // ------------------------------------------------------------------------
    func setupGL() {
        EAGLContext.setCurrent(self.myGLESContext)


        let lGL_VERSION_ptr = glGetString(GLenum(GL_VERSION))
        //        let lGL_VERSION = String.fromCString(lGL_VERSION_ptr as! UnsafePointer<CChar>)
        let lGL_VERSION = String(cString: lGL_VERSION_ptr!)
        print("glGetString(GLenum(GL_VERSION_ptr)) = \(String(describing: lGL_VERSION_ptr))")
        print("   returned: '\(lGL_VERSION)'")
        //        print("   returns 'OpenGL ES 2.0 APPLE-12.0.40' ")
        //        print("   or 'OpenGL ES 3.0 APPLE-12.0.40' ")
        let lGL_SHADING_LANGUAGE_VERSION_ptr = glGetString(GLenum(GL_SHADING_LANGUAGE_VERSION))
        let lGL_SHADING_LANGUAGE_VERSION = String(cString: lGL_SHADING_LANGUAGE_VERSION_ptr!)
        print("glGetString(GLenum(GL_SHADING_LANGUAGE_VERSION_ptr)) = \(String(describing: lGL_SHADING_LANGUAGE_VERSION_ptr))")
        print("   returns '\(lGL_SHADING_LANGUAGE_VERSION)' ")
        //        print("   returns 'OpenGL ES GLSL ES 1.00' ")
        //        print("   or 'OpenGL ES GLSL ES 3.00' ")


        // get shaders ready -- load, compile, link GLSL code into GPU program:
        if (!self.loadShaders()) {
            self.alertUserNoShaders()
        }

        // in 2D, we don't need depth/Z-buffer:
        glDisable(GLenum(GL_DEPTH_TEST))

        // glViewport(x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei)
        self.myViewPortWidth = GLsizei(self.view.bounds.size.width)
        self.myViewPortHeight = GLsizei(self.view.bounds.size.height)

        glViewport ( 0, 0, self.myViewPortWidth, self.myViewPortHeight )

        // Set the background color
        glClearColor ( 0.0, 0.0, 0.0, 1.0 );

    } // end of setupGL()

    // ------------------------------------------------------------------------
    func tearDownGL() {
        EAGLContext.setCurrent(self.myGLESContext)

        glDeleteBuffers(1, &myVertexBuffer)
        glDeleteVertexArrays(1, &myVertexArray)

        if myGLESProgram != 0 {
            glDeleteProgram(myGLESProgram)
            myGLESProgram = 0
        }
    }



    // ------------------------------------------------------------------------
    // user interface to alert our user about an inescapable shader problem:
    func alertUserNoShaders() {

        // provide an UIAlertController:
        // http://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/

        let lAlert = UIAlertController(
            title: "Alert",
            message: "I haven't been successful in creating OpenGL shaders",
            preferredStyle: UIAlertControllerStyle.alert)

        // the alert controller only has a "Cancel" button:

        let lCancelAction = UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.default,
            handler: {
                (action: UIAlertAction) -> Void in
                // do nothing if "Cancel" is pressed
        }
        )

        // add the two actions as buttons to the alert controller:
        lAlert.addAction(lCancelAction)
        // present the alert to the user:
        present(lAlert, animated: true, completion: nil)
    }  // end of func addUser()


    

    // ------------------------------------------------------------------------
    // MARK: - GLKView and GLKViewController delegate methods
    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
    func update() {
        if MODE == E_MODE_EDIT {
            if highlightLineData.count == 4 && myTouchPhase == UITouchPhase.moved{
                if pretouch.count == 0 {
                    pretouch.append(myTouchXbegin)
                    pretouch.append(myTouchYbegin)
                }
                    let move_x = myTouchXcurrent - pretouch[0]
                    let move_y = myTouchYcurrent - pretouch[1]
                    gVertexData[moveIndex] += move_x
                    gVertexData[moveIndex+2] += move_x
                    gVertexData[moveIndex+1] += move_y
                    gVertexData[moveIndex+3] += move_y
                    highlightLineData[0] = gVertexData[moveIndex]
                    highlightLineData[1] = gVertexData[moveIndex+1]
                    highlightLineData[2] = gVertexData[moveIndex+2]
                    highlightLineData[3] = gVertexData[moveIndex+3]
                pretouch[0] = myTouchXcurrent
                pretouch[1] = myTouchYcurrent
            } else if myTouchPhase == UITouchPhase.moved {
                if highlightVertextData.count == 2{
                    gVertexData[moveIndex] = myTouchXcurrent
                    gVertexData[moveIndex+1] = myTouchYcurrent
                    highlightVertextData[0] = gVertexData[moveIndex]
                    highlightVertextData[1] = gVertexData[moveIndex+1]
                }
            } else {
                highlightVertextData.removeAll()
                highlightLineData.removeAll()
                moveIndex = -1
                MODE = E_MODE_PROXIMITY
                pretouch.removeAll()
            }
        }
        if MODE == E_MODE_PROXIMITY && myTouchPhase == UITouchPhase.began && highlightVertextData.count  == 0 && highlightLineData.count == 0{
            let x0 = myTouchXbegin
            let y0 = myTouchYbegin
            let p0 = GLKVector2Make(x0, y0)
            if gVertexData.count > 0 {
                moveIndex = -1
                for index in stride(from: 0, to: gVertexData.count, by: 2) {
                    let x1 = gVertexData[index]
                    let y1 = gVertexData[index+1]
                    let p1 = GLKVector2Make(x1, y1)
                    let pointDis = GLKVector2Distance(p0, p1)
                    if pointDis < 10 {
                        highlightVertextData.append(x1)
                        highlightVertextData.append(y1)
                        MODE = E_MODE_EDIT
                        moveIndex = index
                        break
                    }
                }
            }
            if highlightVertextData.count == 0 && gVertexData.count >= 4 {
                for index in stride(from: 0, to: gVertexData.count-2, by: 2) {
                    let x1 = gVertexData[index]
                    let y1 = gVertexData[index+1]
                    let p1 = GLKVector2Make(x1, y1)
                    let x2 = gVertexData[index+2]
                    let y2 = gVertexData[index+3]
                    var n = GLKVector2Make(-(y2-y1), (x2-x1))
                    n = GLKVector2Normalize(n)
                    let v_ori = GLKVector2Make(x2-x1, y2-y1)
                    let v = GLKVector2Normalize(v_ori)
                    let h = GLKVector2DotProduct(n, GLKVector2Subtract(p0, p1))
                    let l = GLKVector2DotProduct(v, GLKVector2Subtract(p0, p1))
                    if (l > 0 && l < GLKVector2Length(v_ori) && abs(h) < 10) {
                        highlightLineData.append(x1)
                        highlightLineData.append(y1)
                        highlightLineData.append(x2)
                        highlightLineData.append(y2)
//                        pretouch.removeAll()
//                        pretouch.append(x0)
//                        pretouch.append(y0)
                        MODE = E_MODE_EDIT
                        if moveIndex == -1 {
                            moveIndex = index
                        }
                        break
                    }
                }

            }
            if highlightVertextData.count != 0 || highlightLineData.count != 0 {
                MODE = E_MODE_EDIT
            }
            if MODE != E_MODE_EDIT {
                MODE = E_MODE_INSERT
            }
        }
        if (myTouchPhase == UITouchPhase.began || myTouchPhase == UITouchPhase.moved) && MODE == E_MODE_INSERT { // Insertion Mode
            if highlightLineData.count == 0 && highlightVertextData.count == 0 {
                gVertexData.append(myTouchXbegin)
                gVertexData.append(myTouchYbegin)
                MODE = E_MODE_PROXIMITY
            }
        }
        // here we could cause a periodic change in the data model
        //  e.g. 3D models to be animated, etc.
        if myTouchPhase == UITouchPhase.ended {
            pretouch.removeAll()
            highlightVertextData.removeAll()
            highlightLineData.removeAll()
        }
    } // end of update()

    // ------------------------------------------------------------------------
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glUseProgram(myGLESProgram)

        glClear( GLbitfield(GL_COLOR_BUFFER_BIT)  )

        // get viewport dimensions:
        self.myViewPortWidth = GLsizei(self.view.bounds.size.width)
        self.myViewPortHeight = GLsizei(self.view.bounds.size.height)

        // pass viewport dimensions to the vertex shader:
        glUniform1f(self.myWidthUniform, GLfloat(self.myViewPortWidth))
        glUniform1f(self.myHeightUniform, GLfloat(self.myViewPortHeight))


        glEnableVertexAttribArray(self.myPosAttrib)

        // public func glVertexAttribPointer(
        //        _ indx: GLuint,
        //        _ size: GLint,
        //        _ type: GLenum,
        //        _ normalized: GLboolean,
        //        _ stride: GLsizei,
        //        _ ptr: UnsafeRawPointer!)
        glVertexAttribPointer(self.myPosAttrib, 2, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &gVertexData)

        

        flag = 0;
        // only draw if you have at least 2 vertices
        let lNumberOfVertices = gVertexData.count/2
        if (lNumberOfVertices >= 2) {
            //Strip
            // what color to use for the line strip:
            glUniform4f(self.myColorUniform,
                        gColorData[0][0],
                        gColorData[0][1],
                        gColorData[0][2],
                        gColorData[0][3])
            // draw the line:
            // these are the parameters for glDrawArrays() :
            //   glDrawArrays(_ mode: GLenum,
            //                _ first: GLint,
            //                _ count: GLsizei )
            glUniform1i(self.myFlag, flag)
            glLineWidth(3.0)
            glDrawArrays(GLenum(GL_LINE_STRIP), 0, GLsizei(lNumberOfVertices))
        }
        //Point
        //Color of Point
        glUniform4f(self.myColorUniform,
                    gColorData[1][0],
                    gColorData[1][1],
                    gColorData[1][2],
                    gColorData[1][3])
        glUniform1f(self.pointSize, GLfloat(20))
        glUniform1i(self.myFlag, flag)
        glDrawArrays(GLenum(GL_POINTS), 0, GLsizei(lNumberOfVertices))
            
        //Highlight Line
        let highLineVertices = highlightLineData.count / 2
        if  highLineVertices >= 2 {
            //High light line
            glVertexAttribPointer(self.myPosAttrib, 2, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &highlightLineData)
            glUniform4f(self.myColorUniform,
                        gColorData[2][0],
                        gColorData[2][1],
                        gColorData[2][2],
                        gColorData[2][3])
            glLineWidth(6.0)
            glUniform1i(self.myFlag, flag)
            glDrawArrays( GLenum(GL_LINE_STRIP), 0, GLsizei(highLineVertices))
        }
        
        let highPointVertices = highlightVertextData.count / 2
        if  highPointVertices > 0 {
            //High light point
            glVertexAttribPointer(self.myPosAttrib, 2, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &highlightVertextData)
            glUniform4f(self.myColorUniform,
                        gColorData[3][0],
                        gColorData[3][1],
                        gColorData[3][2],
                        gColorData[3][3])
            glUniform1f(self.pointSize, GLfloat(30))
            glUniform1i(self.myFlag, flag)
            glDrawArrays(GLenum(GL_POINTS), 0, GLsizei(highPointVertices))
        }
        //Draw curve
        if lNumberOfVertices >= 4 {
            
            if curveFlag == BAZIER {
                flag = 1;
                step = 3;
            } else if curveFlag == CATMULLROM {
                flag = 2;
                step = 1;
            } else {
                flag = 3;
                step = 1;
            }
            for i in stride(from: 0, through: lNumberOfVertices*2 - 8, by: step * 2) {
                glUniform4f(self.myP1, gVertexData[i],   gVertexData[i+1], 0, 0)
                glUniform4f(self.myP2, gVertexData[i+2], gVertexData[i+3], 0, 0)
                glUniform4f(self.myP3, gVertexData[i+4], gVertexData[i+5], 0, 0)
                glUniform4f(self.myP4, gVertexData[i+6], gVertexData[i+7], 0, 0)
                
                glVertexAttribPointer(self.myPosAttrib, 1, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &t)
                
                glUniform1i(self.myFlag, flag)
                glUniform1f(self.pointSize, 5.0)
                glUniform4f(self.myColorUniform, 1, 1, 1, 1)
                glDrawArrays(GLenum(GL_POINTS), 0, GLsizei(t.count))
                
                //draw derivative
                if curveFlag == BAZIER {
                    firstDerivative_1[0] = gVertexData[i]
                    firstDerivative_1[1] = gVertexData[i+1]
                    firstDerivative_1[2] = gVertexData[i] + 1 / 3 * (gVertexData[i+2] - gVertexData[i])
                    firstDerivative_1[3] = gVertexData[i+1] + 1 / 3 * (gVertexData[i+3] - gVertexData[i+1])
                    
                    firstDerivative_2[0] = gVertexData[i+6]
                    firstDerivative_2[1] = gVertexData[i+7]
                    firstDerivative_2[2] = gVertexData[i+6] + 1 / 3 * (gVertexData[i+4] - gVertexData[i+6])
                    firstDerivative_2[3] = gVertexData[i+7] + 1 / 3 * (gVertexData[i+5] - gVertexData[i+7])
                    
                    secondDerivative_1[0] = gVertexData[i]
                    secondDerivative_1[1] = gVertexData[i+1]
                    secondDerivative_1[2] = gVertexData[i] + 1 / 3 * (gVertexData[i] - 2 * gVertexData[i+2] + gVertexData[i+4])
                    secondDerivative_1[3] = gVertexData[i+1] + 1 / 3 * (gVertexData[i+1] - 2 * gVertexData[i+3] + gVertexData[i+5])
                    
                    secondDerivative_2[0] = gVertexData[i+6]
                    secondDerivative_2[1] = gVertexData[i+7]
                    secondDerivative_2[2] = gVertexData[i+6] + 1 / 3 * (gVertexData[i+2] - 2 * gVertexData[i+4] + gVertexData[i+6])
                    secondDerivative_2[3] = gVertexData[i+7] + 1 / 3 * (gVertexData[i+3] - 2 * gVertexData[i+5] + gVertexData[i+7])
                    
                } else if curveFlag == CATMULLROM {
                    firstDerivative_1[0] = gVertexData[i+2]
                    firstDerivative_1[1] = gVertexData[i+3]
                    firstDerivative_1[2] = gVertexData[i+2] + 1 / 5 * (gVertexData[i+4] - gVertexData[i])
                    firstDerivative_1[3] = gVertexData[i+3] + 1 / 5 * (gVertexData[i+5] - gVertexData[i+1])
                    
                    firstDerivative_2[0] = gVertexData[i+4]
                    firstDerivative_2[1] = gVertexData[i+5]
                    firstDerivative_2[2] = gVertexData[i+4] - 1 / 5 * (gVertexData[i+6] - gVertexData[i+2])
                    firstDerivative_2[3] = gVertexData[i+5] - 1 / 5 * (gVertexData[i+7] - gVertexData[i+3])
                    
                    secondDerivative_1[0] = gVertexData[i+2]
                    secondDerivative_1[1] = gVertexData[i+3]
                    secondDerivative_1[2] = gVertexData[i+2] + 1 / 5 * (2 * gVertexData[i] - 5 * gVertexData[i+2] + 4 * gVertexData[i+4] - gVertexData[i+6])
                    secondDerivative_1[3] = gVertexData[i+3] + 1 / 5 * (2 * gVertexData[i+1] - 5 * gVertexData[i+3] + 4 * gVertexData[i+5] - gVertexData[i+7])
                    
                    secondDerivative_2[0] = gVertexData[i+4]
                    secondDerivative_2[1] = gVertexData[i+5]
                    secondDerivative_2[2] = gVertexData[i+4] + 1 / 5 * (-1 * gVertexData[i] + 4 * gVertexData[i+2] + -5 * gVertexData[i+4] + 2 * gVertexData[i+6])
                    secondDerivative_2[3] = gVertexData[i+5] + 1 / 5 * (-1 * gVertexData[i+1] + 4 * gVertexData[i+3] + -5 * gVertexData[i+5] + 2 * gVertexData[i+7])
                } else {
                    let x1 = 1.0 / 6.0 * (gVertexData[i] + 4 * gVertexData[i+2] + gVertexData[i+4])
                    let y1 = 1.0 / 6.0 * (gVertexData[i+1] + 4 * gVertexData[i+3] + gVertexData[i+5])
                    let x2 = 1.0 / 6.0 * (gVertexData[i+2] + 4 * gVertexData[i+4] + gVertexData[i+6])
                    let y2 = 1.0 / 6.0 * (gVertexData[i+3] + 4 * gVertexData[i+5] + gVertexData[i+7])
                    firstDerivative_1[0] = x1
                    firstDerivative_1[1] = y1
                    firstDerivative_1[2] = x1 + 1 / 5 * (gVertexData[i+4] - gVertexData[i])
                    firstDerivative_1[3] = y1 + 1 / 5 * (gVertexData[i+5] - gVertexData[i+1])
                    
                    firstDerivative_2[0] = x2
                    firstDerivative_2[1] = y2
                    firstDerivative_2[2] = x2 - 1 / 5 * (gVertexData[i+6] - gVertexData[i+2])
                    firstDerivative_2[3] = y2 - 1 / 5 * (gVertexData[i+7] - gVertexData[i+3])
                    
                    secondDerivative_1[0] = x1
                    secondDerivative_1[1] = y1
                    secondDerivative_1[2] = x1 + 1 / 3 * (gVertexData[i] - 2 * gVertexData[i+2] + gVertexData[i+4])
                    secondDerivative_1[3] = y1 + 1 / 3 * (gVertexData[i+1] - 2 * gVertexData[i+3] + gVertexData[i+5])
                    
                    secondDerivative_2[0] = x2
                    secondDerivative_2[1] = y2
                    secondDerivative_2[2] = x2 + 1 / 3 * (gVertexData[i+2] - 2 * gVertexData[i+4] + gVertexData[i+6])
                    secondDerivative_2[3] = y2 + 1 / 3 * (gVertexData[i+3] - 2 * gVertexData[i+5] + gVertexData[i+7])
                }
                glUniform1i(self.myFlag, 0)
                glLineWidth(5.0)
                
                if isdrawFisrt {
                    glUniform4f(self.myColorUniform, 1, 0, 0, 1)
                    glVertexAttribPointer(self.myPosAttrib, 2, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &firstDerivative_1)
                    glDrawArrays(GLenum(GL_LINE_STRIP), 0, GLsizei(2))
                    glVertexAttribPointer(self.myPosAttrib, 2, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &firstDerivative_2)
                    glDrawArrays(GLenum(GL_LINE_STRIP), 0, GLsizei(2))
                }
                
                if isdrawSecond {
                    glUniform4f(self.myColorUniform, 1, 1, 0, 1)
                    glVertexAttribPointer(self.myPosAttrib, 2, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &secondDerivative_1)
                    glDrawArrays(GLenum(GL_LINE_STRIP), 0, GLsizei(2))
                    
                    glVertexAttribPointer(self.myPosAttrib, 2, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &secondDerivative_2)
                    glDrawArrays(GLenum(GL_LINE_STRIP), 0, GLsizei(2))
                }

            }

        }


        // NOTE: don't change contents of the gVertexData array in the drawing function!


    } // end of glkView( ... drawInRect: )






    // ------------------------------------------------------------------------
    // MARK: - UIResponder delegate methods for touch events
    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        if let firstTouch = touches.first  {
            let firstTouchPoint = firstTouch.location(in: self.view)
            let lMessage = "Touch Began at \(firstTouchPoint.x), \(firstTouchPoint.y)"

            // the position where the finger begins touching the screen:
            self.myTouchXbegin = GLfloat(firstTouchPoint.x)
            self.myTouchYbegin = GLfloat(self.myViewPortHeight) - GLfloat(firstTouchPoint.y - 1)

            // we are in the "we've just began" phase of the touch event sequence:
            self.myTouchPhase = UITouchPhase.began

            // print out debugging info:
            NSLog(lMessage)
        }
    } // end of touchesBegan()


    // ------------------------------------------------------------------------
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first  {
            let firstTouchPoint = firstTouch.location(in: self.view)
            let lMessage = "Touch Moved to \(firstTouchPoint.x), \(firstTouchPoint.y)"
            
            self.myTouchXcurrent = GLfloat(firstTouchPoint.x)
            self.myTouchYcurrent = GLfloat(self.myViewPortHeight) - GLfloat(firstTouchPoint.y - 1)

            // we are in the "something has moved" phase of the touch event sequence:
            self.myTouchPhase = UITouchPhase.moved

            // print out debugging info:
            NSLog(lMessage)
        }
    } // end of touchesMoved()



    // ------------------------------------------------------------------------
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first  {
            let firstTouchPoint = firstTouch.location(in: self.view)
            let lMessage = "Touches Ended at \(firstTouchPoint.x), \(firstTouchPoint.y)"

            self.myTouchXcurrent = GLfloat(firstTouchPoint.x)
            self.myTouchYcurrent = GLfloat(self.myViewPortHeight) - GLfloat(firstTouchPoint.y - 1)

            // we are in the "completed" phase of the touch event sequence:
            self.myTouchPhase = UITouchPhase.ended

            NSLog(lMessage)
        }
    } // end of touchesEnded()



    // ------------------------------------------------------------------------
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        let lMessage = "Touches Cancelled"

        self.myTouchXbegin = -1.0
        self.myTouchYbegin = -1.0
        self.myTouchXcurrent = -1.0
        self.myTouchYcurrent = -1.0
        self.myTouchXold = -1.0
        self.myTouchYold = -1.0


        // we are in the "something just interrupted us, e.g. a phone call" phase
        //     of the touch event sequence:
        self.myTouchPhase = UITouchPhase.cancelled

        NSLog(lMessage)

    } // end of touchesMoved()




    // ------------------------------------------------------------------------
    // MARK: -  OpenGL ES 2 shader compilation, linking, binding
    // ------------------------------------------------------------------------






    // ------------------------------------------------------------------------
    // load GLSL shaders from separate source code files, then compile and link
    // ------------------------------------------------------------------------
    func loadShaders() -> Bool {
        var vertShader: GLuint = 0
        var fragShader: GLuint = 0
        var vertShaderPathname: String
        var fragShaderPathname: String

        // Create shader program.
        myGLESProgram = glCreateProgram()

        // Create and compile vertex shader:
        vertShaderPathname = Bundle.main.path(forResource: "Shader", ofType: "vsh")!

        if self.compileShader(&vertShader,
                              type: GLenum(GL_VERTEX_SHADER),
                              file: vertShaderPathname) == false {

            NSLog("Failed to compile vertex shader")
            return false
        }

        // Create and compile fragment shader.
        fragShaderPathname = Bundle.main.path(forResource: "Shader", ofType: "fsh")!

        if self.compileShader(&fragShader,
                              type: GLenum(GL_FRAGMENT_SHADER),
                              file: fragShaderPathname) == false {
            NSLog("Failed to compile fragment shader")
            return false
        }

        // Attach vertex shader object code to GPU program:
        glAttachShader(myGLESProgram, vertShader)

        // Attach fragment shader object code to GPU program:
        glAttachShader(myGLESProgram, fragShader)

        // Link GPU program:
        if !self.linkProgram(myGLESProgram) {
            NSLog("Failed to link program: \(myGLESProgram)")
            // if linking fails, dispose of anything we got so far:
            if vertShader != 0 {
                glDeleteShader(vertShader)
                vertShader = 0
            }
            if fragShader != 0 {
                glDeleteShader(fragShader)
                fragShader = 0
            }
            if myGLESProgram != 0 {
                glDeleteProgram(myGLESProgram)
                myGLESProgram = 0
            }
            return false
        }

        // Get location of attribute variable in the shader:
        self.myPosAttrib = GLuint(glGetAttribLocation(myGLESProgram, "a_Position"))

        // Get location of uniform variables in the shaders:
        self.myWidthUniform = glGetUniformLocation(myGLESProgram, "u_Width")
        self.myHeightUniform = glGetUniformLocation(myGLESProgram, "u_Height")
        self.myColorUniform = glGetUniformLocation(myGLESProgram, "u_Color")
        self.pointSize = glGetUniformLocation(myGLESProgram, "u_pointSize")
        //
        self.myP1 = glGetUniformLocation(myGLESProgram, "P1")
        self.myP2 = glGetUniformLocation(myGLESProgram, "P2")
        self.myP3 = glGetUniformLocation(myGLESProgram, "P3")
        self.myP4 = glGetUniformLocation(myGLESProgram, "P4")
        self.myFlag = glGetUniformLocation(myGLESProgram, "flag")
        

        // Release vertex and fragment shaders.
        if vertShader != 0 {
            glDetachShader(myGLESProgram, vertShader)
            glDeleteShader(vertShader)
        }
        if fragShader != 0 {
            glDetachShader(myGLESProgram, fragShader)
            glDeleteShader(fragShader)
        }

        return true
    } // end of loadShaders()


    // ------------------------------------------------------------------------
    // compile GLSL source code into linkable shader object code:
    // ------------------------------------------------------------------------
    func compileShader(_ shader: inout GLuint, type: GLenum, file: String) -> Bool {
        var status: GLint = 0
        var source: UnsafePointer<Int8>
        do {
            source = try NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue).utf8String!
        } catch {
            NSLog("Failed to load vertex shader \(file)")
            return false
        }
        var castSource: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(source)

        // create a shader object to hold GLSL source code,
        //   and obtain a non-zero value by which it can be referenced
        shader = glCreateShader(type)
        glShaderSource(shader, 1, &castSource, nil)
        glCompileShader(shader)

        var logLength: GLint = 0
        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            if let logRawPointer = malloc(Int(logLength)) {
                let logOpaquePointer = OpaquePointer(logRawPointer)
                let logContextPointer = UnsafeMutablePointer<GLchar>(logOpaquePointer)
                glGetShaderInfoLog(shader, logLength, &logLength, logContextPointer)
                NSLog("Shader compile log: \n%s", logContextPointer)
                free(logRawPointer)
            }
        }

        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        if status == GL_FALSE {
            glDeleteShader(shader)
            return false
        }
        return true
    } // end of compileShader()

    // ------------------------------------------------------------------------
    // link compiled GLSL shaders into a GLSL program for use by CPU GLES code
    // ------------------------------------------------------------------------
    func linkProgram(_ prog: GLuint) -> Bool {
        var status: GLint = 0

        glLinkProgram(prog)

        var logLength: GLint = 0
        glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            if let logRawPointer = malloc(Int(logLength)) {
                let logOpaquePointer = OpaquePointer(logRawPointer)
                let logContextPointer = UnsafeMutablePointer<GLchar>(logOpaquePointer)
                glGetProgramInfoLog(prog, logLength, &logLength, logContextPointer)
                NSLog("Shader link log: \n%s", logContextPointer)
                free(logRawPointer)
            }
        }

        glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
        if status == GL_FALSE {
            return false
        }

        return true
    }

    // ------------------------------------------------------------------------
    // you may call validateProgram()
    // ------------------------------------------------------------------------
    func validateProgram(_ prog: GLuint) -> Bool {
        var logLength: GLsizei = 0
        var status: GLint = 0

        glValidateProgram(prog)
        glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
            glGetProgramInfoLog(prog, logLength, &logLength, &log)
            NSLog("Program validate log: %@", String(validatingUTF8: log)!)
        }

        glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
        var returnVal = true
        if status == 0 {
            returnVal = false
        }
        return returnVal
    } // end of validateProgram()

} // end of class MyOpenGLESKitViewController

