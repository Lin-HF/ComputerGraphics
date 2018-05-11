//
//  MyOpenGLESKitViewController.swift
//  lab12solution
//
//  Created by Mitja Hmeljak on 2018-04-07.
//  Copyright © 2018 IU CSCI B481/B581 Spring 2018. All rights reserved.
//


import GLKit
import OpenGLES
import AVFoundation

let sp = sphere()

// OpenGL ES requires the use of C-like pointers to "CPU memory",
// without the automated memory management provided by Swift:
func obtainUnsafePointer(_ i: Int) -> UnsafeRawPointer? {
    return UnsafeRawPointer(bitPattern: i)
}

// lab12 SAMPLE SOLUTION
var gAxesData: [GLfloat] = [
//  see how these are computed in code below ...
]

// length of "mark":
let gLenTicks: GLfloat = 0.5


// note: in lab12 SAMPLE SOLUTION we don't use gVertexData
//       because we provide no model to display
//       (we only display coordinate system axes)
//   BUT you'd use gVertexData to prepare a model to display!

var gColorData: [[GLfloat]] = [
    // color data in RGBA float format
    [1.0, 0.0, 0.0, 1.0],
    [0.0, 1.0, 0.0, 1.0],
    [0.0, 0.0, 1.0, 1.0]
]

var transFlag: GLint = 1
//1.Rot  2.Txy  3.Txz  4.Scale

var sph = sp.sphereVerts
var sphIndex = sp.sphereTexCoords
var spNormal = sp.sphereNormals

var modelMatrix = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                 0.0, 1.0, 0.0, 0.0,
                                 0.0, 0.0, 1.0, 0.0,
                                 0.0, 0.0, 0.0, 1.0)

var MoonmodelMatrix = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                     0.0, 1.0, 0.0, 0.0,
                                     0.0, 0.0, 1.0, 0.0,
                                     0.0, 0.0, 0.0, 1.0)

var viewMatrix = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                0.0, 1.0, 0.0, 0.0,
                                0.0, 0.0, 1.0, 0.0,
                                0.0, 0.0, -30.0, 1.0)

var earthLight = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                     0.0, 1.0, 0.0, 0.0,
                                     0.0, 0.0, 1.0, 0.0,
                                     0.0, 0.0, 0.0, 1.0)

var moonLight = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                0.0, 1.0, 0.0, 0.0,
                                0.0, 0.0, 1.0, 0.0,
                                0.0, 0.0, 0.0, 1.0)

var animationSpeed: GLfloat = 0.01
let touchSpeed: GLfloat = 0.03


class MyOpenGLESKitViewController: GLKViewController {

    var myGLESProgram: GLuint = 0

    var myVertexPositionAttribute: GLuint = 0
    
    var myNormalVectorAttribute: GLuint = 0

    var myModelViewProjectionMatrix:GLKMatrix4 = GLKMatrix4Identity

    var myViewPortWidth:GLsizei = -1
    var myViewPortHeight:GLsizei = -1

    // lab12 SAMPLE SOLUTION:
    var myFoVUniform: GLint = 0
    var myAspectUniform: GLint = 0
    var myNearUniform: GLint = 0
    var myFarUniform: GLint = 0
    //Obj-flag
    var myObj_Flag: GLint = 0
    //Obj-Matrix
    var myObjMatrix: GLint = 0
    var myViewMatrix: GLint = 0
    var myMoonMatrix: GLint = 0
    var myEarthLight: GLint = 0
    var myMoonLight: GLint = 0
    var myColorUniform: GLint = 0

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

    // lab12 SAMPLE SOLUTION:
    // store just X and Y coordinates for camera position
    //   since for lab 12 we only move the camera on the x-y plane:
    var myTx: GLfloat = 0.0
    var myTy: GLfloat = 0.0
    var myTz: GLfloat = 30.0
    var objTx: GLfloat = 0.0
    var objTy: GLfloat = 0.0
    var objTz: GLfloat = 0.0
    
    var CofMX: GLfloat = 0.0
    var CofMY: GLfloat = 0.0
    var CofMZ: GLfloat = 0.0
    
    var MoonX: GLfloat = 0.0
    var MoonY: GLfloat = 0.0
    var MoonZ: GLfloat = 0.0
    
    var CamX: GLfloat = 0.0
    var CamY: GLfloat = 0.0
    var CamZ: GLfloat = -30.0
    
    var mySx: GLfloat = 1.0
    var mySy: GLfloat = 1.0
    var mySz: GLfloat = 1.0

    
    var RotationDx: GLfloat = 0.0
    var RotationDy: GLfloat = 0.0

    
    //A3
    var myTransFlag: GLint = 0
    var myObj: GLint = 0
    var obj_number = 4
    var myAxesFlag: GLint = 0
    
    //A4
    var myTexture: GLuint = 0
    var myVertexTextureAttribute: GLuint = 0
    var myTexUniform: GLint = 0
    var v4 = GLKVector4Make(0.0, 0.0, 0.0, 1.0)
    var half = GLKVector3Make(0.0, 0.0, 0.0)
    var light = GLKVector3Make(10.0, 10.0, 0.8)
    var audioPlayer: AVAudioPlayer!
    var isPlaying: Bool = true
    var isAxes: Bool = true
    var myHalfplane: GLint = 0
    var myLight: GLint = 0
    
    @IBOutlet weak var rot_button: UIButton!
    @IBOutlet weak var txy_button: UIButton!
    @IBOutlet weak var txz_button: UIButton!
    @IBOutlet weak var scale_button: UIButton!
    
    @IBAction func speed(_ sender: UISlider) {
        animationSpeed = 0.02 * sender.value
    }
    
    @IBOutlet weak var obj2_button: UIButton!
    @IBOutlet weak var obj1_button: UIButton!
    @IBOutlet weak var cam_button: UIButton!
    @IBOutlet weak var musicplay: UIButton!
    //assginment03
    //Translate selection
    @IBAction func rot(_ sender: UIButton) {
        transFlag = 1
        sender.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        txy_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        txz_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        scale_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        
    }
    @IBAction func Txy(_ sender: UIButton) {
        transFlag = 2
        sender.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        rot_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        txz_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        scale_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
    }
    @IBAction func Txz(_ sender: UIButton) {
        transFlag = 3
        sender.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        txy_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        rot_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        scale_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
    }
    @IBAction func scale(_ sender: UIButton) {
        transFlag = 4
        sender.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        txy_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        txz_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        rot_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
    }
    //Obj selection
    @IBAction func Obj1(_ sender: UIButton) {
        obj_number = 1;
        sender.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        cam_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        obj2_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
    }
    @IBAction func Obj2(_ sender: UIButton) {
        obj_number = 2;
        sender.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        cam_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        obj1_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
    }
    
    @IBAction func Cam(_ sender: UIButton) {
        obj_number = 4;
        sender.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        obj1_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        obj2_button.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
    }
    
    @IBAction func music_player(_ sender: UIButton) {
        if isPlaying {
            audioPlayer.pause()
            sender.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        } else {
            audioPlayer.play()
            sender.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        }
        isPlaying = !isPlaying
        
        
    }
    @IBAction func reset(_ sender: UIButton) {
        modelMatrix = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                         0.0, 1.0, 0.0, 0.0,
                                         0.0, 0.0, 1.0, 0.0,
                                         0.0, 0.0, 0.0, 1.0)
        
        MoonmodelMatrix = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                             0.0, 1.0, 0.0, 0.0,
                                             0.0, 0.0, 1.0, 0.0,
                                             0.0, 0.0, 0.0, 1.0)
        earthLight = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                         0.0, 1.0, 0.0, 0.0,
                                         0.0, 0.0, 1.0, 0.0,
                                         0.0, 0.0, 0.0, 1.0)
        moonLight = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                    0.0, 1.0, 0.0, 0.0,
                                    0.0, 0.0, 1.0, 0.0,
                                    0.0, 0.0, 0.0, 1.0)
        viewMatrix = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0,
                                        0.0, 1.0, 0.0, 0.0,
                                        0.0, 0.0, 1.0, 0.0,
                                        0.0, 0.0, -30.0, 1.0)
        
        
         CofMX = 0.0
         CofMY = 0.0
         CofMZ = 0.0
        
         MoonX = 0.0
         MoonY = 0.0
         MoonZ = 0.0
        
         CamX = 0.0
         CamY = 0.0
         CamZ = -30.0
        
         mySx = 1.0
         mySy = 1.0
         mySz = 1.0
        MoonmodelMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeScale(1.5, 1.5, 1.5), MoonmodelMatrix)
        moonLight =  GLKMatrix4Multiply(GLKMatrix4MakeScale(1.5, 1.5, 1.5), moonLight)
        MoonmodelMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeTranslation(15.0, 0.0, 0.0), MoonmodelMatrix)
        v4 = GLKMatrix4MultiplyVector4(GLKMatrix4MakeTranslation(15.0, 0.0, 0.0), GLKVector4Make(MoonX, MoonY, MoonZ, 1.0))
        MoonX = v4.x
        MoonY = v4.y
        MoonZ = v4.z

    }
    @IBAction func axes(_ sender: UIButton) {
        isAxes = !isAxes
    }
    
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

        MoonmodelMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeScale(1.5, 1.5, 1.5), MoonmodelMatrix)
        MoonmodelMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeTranslation(15.0, 0.0, 0.0), MoonmodelMatrix)
        moonLight =  GLKMatrix4Multiply(GLKMatrix4MakeScale(1.5, 1.5, 1.5), moonLight)

        v4 = GLKMatrix4MultiplyVector4(GLKMatrix4MakeTranslation(15.0, 0.0, 0.0), GLKVector4Make(MoonX, MoonY, MoonZ, 1.0))
        MoonX = v4.x
        MoonY = v4.y
        MoonZ = v4.z

        let url = Bundle.main.url(forResource: "Dream", withExtension: "mp3")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url!)
            audioPlayer.prepareToPlay()
            audioPlayer.currentTime = 0
        } catch let error as NSError {
            print("\(error.debugDescription)")
        }
        audioPlayer.play()
        musicplay.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        cam_button.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        rot_button.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
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
        //self.myGLKView!.drawableDepthFormat = GLKViewDrawableDepthFormat.formatNone
        // in 3D we'll often need the depth buffer, e.g.:
        self.myGLKView!.drawableDepthFormat = GLKViewDrawableDepthFormat.format24

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


    // lab12 SAMPLE SOLUTION:
    func buildAxes() {

        // build x-axis
        gAxesData.append(0.0)
        gAxesData.append(0.0)
        gAxesData.append(0.0)

        gAxesData.append(10.0)
        gAxesData.append(0.0)
        gAxesData.append(0.0)

        for i in 1...10 {
            gAxesData.append(0.0 + GLfloat(i))
            gAxesData.append(0.0)
            gAxesData.append(0.0)

            gAxesData.append(0.0 + GLfloat(i))
            gAxesData.append(0.0)
            gAxesData.append(gLenTicks)
        }
        for i in 1...10 {
            gAxesData.append(0.0 + GLfloat(i))
            gAxesData.append(0.0)
            gAxesData.append(0.0)
            
            gAxesData.append(0.0 + GLfloat(i))
            gAxesData.append(gLenTicks)
            gAxesData.append(0.0)
        }

        // build y-axis
        gAxesData.append(0.0)
        gAxesData.append(0.0)
        gAxesData.append(0.0)

        gAxesData.append(0.0)
        gAxesData.append(10.0)
        gAxesData.append(0.0)

        for i in 1...10 {
            gAxesData.append(0.0)
            gAxesData.append(0.0 + GLfloat(i))
            gAxesData.append(0.0)

            gAxesData.append(gLenTicks)
            gAxesData.append(0.0 + GLfloat(i))
            gAxesData.append(0.0)
        }
        for i in 1...10 {
            gAxesData.append(0.0)
            gAxesData.append(0.0 + GLfloat(i))
            gAxesData.append(0.0)
            
            gAxesData.append(0.0)
            gAxesData.append(0.0 + GLfloat(i))
            gAxesData.append(gLenTicks)
        }

        // build z-axis
        gAxesData.append(0.0)
        gAxesData.append(0.0)
        gAxesData.append(0.0)

        gAxesData.append(0.0)
        gAxesData.append(0.0)
        gAxesData.append(10.0)

        for i in 1...10 {
            gAxesData.append(0.0)
            gAxesData.append(0.0)
            gAxesData.append(0.0 + GLfloat(i))

            gAxesData.append(gLenTicks)
            gAxesData.append(0.0)
            gAxesData.append(0.0 + GLfloat(i))
        }
        for i in 1...10 {
            gAxesData.append(0.0)
            gAxesData.append(0.0)
            gAxesData.append(0.0 + GLfloat(i))
            
            gAxesData.append(0.0)
            gAxesData.append(gLenTicks)
            gAxesData.append(0.0 + GLfloat(i))
        }
    }
    
    func buildRotation(dx: GLfloat, dy: GLfloat) -> GLKMatrix4 {
        let dz:GLfloat = 0.0
        //let dz:GLfloat = myTz
        var n = GLKVector3Make(dy, -dx, dz)
        n = GLKVector3Normalize(n)
        let angle = sqrt(dx * dx + dy * dy) / 2.0
        let c = cos(angle)
        let s = sin(angle)
        let x00 = Float(n.x * n.x * (1 - c) + c)
        let x01 = Float(n.x * n.y * (1 - c) - n.z * s)
        let x02 = Float(n.x * n.z * (1 - c) + n.y * s)
        
        let x10 = Float(n.y * n.x * (1 - c) + n.z * s)
        let x11 = Float(n.y * n.y * (1 - c) + c)
        let x12 = Float(n.y * n.z * (1 - c) - n.x * s)
        
        let x20 = Float(n.x * n.z * (1 - c) - n.y * s)
        let x21 = Float(n.y * n.z * (1 - c) + n.x * s)
        let x22 = Float(n.z * n.z * (1 - c) + c)
        
        let mat = GLKMatrix4Make(x00, x01, x02, 0.0, x10, x11, x12, 0.0, x20, x21, x22, 0.0, 0.0, 0.0, 0.0, 1.0)
        //return glRotatef(angle, dx, dy, 0)
        return mat
    }
    
    func transMatrxiToArray(m: GLKMatrix4) -> [GLfloat] {
        let array: [GLfloat] = [m.m00, m.m01, m.m02, m.m03,
                                m.m10, m.m11, m.m12, m.m13,
                                m.m20, m.m21, m.m22, m.m23,
                                m.m30, m.m31, m.m32, m.m33]
        return array
    }

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


        // Get location of attribute variable in the shader:
        self.myVertexPositionAttribute = GLuint(glGetAttribLocation(self.myGLESProgram, "a_Position"))
        self.myNormalVectorAttribute = GLuint(glGetAttribLocation(self.myGLESProgram, "a_normal"))

        // Get location of uniform variables in the shaders:
        self.myFoVUniform = glGetUniformLocation(self.myGLESProgram, "u_FoV")
        self.myAspectUniform = glGetUniformLocation(self.myGLESProgram, "u_Aspect")
        self.myNearUniform = glGetUniformLocation(self.myGLESProgram, "u_Near")
        self.myFarUniform = glGetUniformLocation(self.myGLESProgram, "u_Far")
        //
        self.myColorUniform = glGetUniformLocation(self.myGLESProgram, "u_Color")
        //A3
        //self.myTransFlag = glGetUniformLocation(self.myGLESProgram, "u_TransFlag")
        self.myObj_Flag = glGetUniformLocation(self.myGLESProgram, "obj_flag")
        self.myObjMatrix = glGetUniformLocation(self.myGLESProgram, "modelMat")
        self.myViewMatrix = glGetUniformLocation(self.myGLESProgram, "viewMat")
        
        self.myMoonMatrix = glGetUniformLocation(self.myGLESProgram, "moonMat")
        self.myEarthLight = glGetUniformLocation(self.myGLESProgram, "earthlight")
        self.myMoonLight = glGetUniformLocation(self.myGLESProgram, "moonlight")
        //A4
        self.myVertexTextureAttribute = GLuint(glGetAttribLocation(myGLESProgram, "a_TextureCoordinates"))
        self.myTexUniform = glGetUniformLocation(myGLESProgram, "u_TextureSampler")
        self.myAxesFlag = glGetUniformLocation(myGLESProgram, "axesFlag")
        self.myHalfplane = glGetUniformLocation(myGLESProgram, "halfplane")
        self.myLight = glGetUniformLocation(myGLESProgram, "lightdirection")
        // in 3D, we need depth/Z-buffer:
        glEnable(GLenum(GL_DEPTH_TEST))

        // glViewport(x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei)
        self.myViewPortWidth = GLsizei(self.view.bounds.size.width)
        self.myViewPortHeight = GLsizei(self.view.bounds.size.height)

        glViewport ( 0, 0, self.myViewPortWidth, self.myViewPortHeight )

        // Set the background color
        //glClearColor ( 0.94, 0.94, 0.94, 1.0 )
        glClearColor ( 0.0, 0.0, 0.0, 1.0 )

        // lab12 SAMPLE SOLUTION:
        buildAxes()
        //A4
        glUniform1i(self.myAxesFlag, 0);

    } // end of setupGL()

    // ------------------------------------------------------------------------
    func tearDownGL() {
        EAGLContext.setCurrent(self.myGLESContext)

        if self.myGLESProgram != 0 {
            glDeleteProgram(self.myGLESProgram)
            self.myGLESProgram = 0
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

        //Begin Earth Animation
        modelMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-CofMX, -CofMY, -CofMZ), modelMatrix)
        modelMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeYRotation(5 * animationSpeed), modelMatrix)
        modelMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeTranslation(CofMX, CofMY, CofMZ), modelMatrix)
        
        //earthLight =  GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-CofMX, -CofMY, -CofMZ), earthLight)
        earthLight =  GLKMatrix4Multiply(GLKMatrix4MakeYRotation(5 * animationSpeed), earthLight)
        //earthLight =  GLKMatrix4Multiply(GLKMatrix4MakeTranslation(CofMX, CofMY, CofMZ), earthLight)
        //End Animation
        
        //Moon Animation
        MoonmodelMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeYRotation(animationSpeed), MoonmodelMatrix)
        //moonLight =  GLKMatrix4Multiply(GLKMatrix4MakeTranslation(MoonX, MoonY, MoonZ), moonLight)
        moonLight =  GLKMatrix4Multiply(GLKMatrix4MakeYRotation(animationSpeed), moonLight)
        //MoonmodelMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeYRotation(animationSpeed), MoonmodelMatrix)
        v4 = GLKMatrix4MultiplyVector4(MoonmodelMatrix, GLKVector4Make(0.0, 0.0, 0.0, 1.0))
        //print("The moon is at \(v4.x), \(v4.y), \(v4.z)")
        //print("Anmating....")
        // here we could cause a periodic change in the data model
        //  e.g. 3D models to be animated, etc.

    } // end of update()

    // BEGIN TEXTURE
    func loadTexture(filename: String) {
        let image: CGImage? = UIImage(named: filename)?.cgImage
        
        let width: Int = image!.width
        let height: Int = image!.height
        let imageData = calloc(Int(CGFloat(width) * CGFloat(height) * 4), Int(MemoryLayout<GLubyte>.size))
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let imageContext: CGContext = CGContext(data: imageData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: image!.colorSpace!, bitmapInfo: bitmapInfo.rawValue)!
        
        let rect = CGRect(x: 0, y: 0, width: CGFloat(width) , height: CGFloat(height))
        
        imageContext.draw(image!, in: rect, byTiling:false)
        
        // Generate textures
        //glGenTextures(1, &myTexture)
        // Bind it
        glBindTexture(GLenum(GL_TEXTURE_2D), myTexture)
        
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), UInt32(GL_UNSIGNED_BYTE), imageData)
        
        free(imageData)
    }
    // END TEXTURE


    // ------------------------------------------------------------------------
    // main drawing function
    // ------------------------------------------------------------------------
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glUseProgram(self.myGLESProgram)

        glClear( GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT) )

        // get viewport dimensions:
        self.myViewPortWidth = GLsizei(self.view.bounds.size.width)
        self.myViewPortHeight = GLsizei(self.view.bounds.size.height)

        // lab12 SAMPLE SOLUTION:
        glUniform1i(self.myObj_Flag, 4)
        // pass values to uniform variables in the vertex shader:

        //    --- configure the perspective projection:
        glUniform1f(self.myFoVUniform, 90)
        glUniform1f(self.myAspectUniform, GLfloat(self.myViewPortWidth)/GLfloat(self.myViewPortHeight))
        glUniform1f(self.myNearUniform, 10.0)
        glUniform1f(self.myFarUniform, 80.0)
        //    --- position the camera:

        half = GLKVector3Add(light, GLKVector3Make(CamX, CamY, CamZ))
        half = GLKVector3Normalize(half)
        light = GLKVector3Normalize(light)
        glUniform3f(myHalfplane, half.x, half.y, half.z)
        glUniform3f(myLight, light.x, light.y, light.z)
        // we don't need to update vertex positions in gAxesData,
        //  since the coordinate system axes always stay the same!
        //  (we move around the camera!)

        glEnableVertexAttribArray(self.myVertexPositionAttribute)
        glEnableVertexAttribArray(self.myVertexTextureAttribute)
        glEnableVertexAttribArray(self.myNormalVectorAttribute)

        
        // now call glVertexAttribPointer() to specify the location and data format
        //   of the array of generic vertex attributes at index,
        //   to be used at rendering time, when glDrawArrays() is going to be called.
        //
        // public func glVertexAttribPointer(indx: GLuint, _ size: GLint,
        //   _ type: GLenum, _ normalized: GLboolean,
        //   _ stride: GLsizei, _ ptr: UnsafePointer<Void>)
        // see https://www.khronos.org/opengles/sdk/docs/man/xhtml/glVertexAttribPointer.xml

        glUniform1i(self.myAxesFlag, 0);//texture
        // BEGIN TEXTURE
        glActiveTexture(GLenum(GL_TEXTURE0));
        glBindTexture(GLenum(GL_TEXTURE_2D), self.myTexture);
        glUniform1i(self.myTexUniform, 0);
        // END TEXTURE
        //Draw Earth
        glUniform1i(self.myObj_Flag, 3)//Set obj = obj1, Render obj1 seperatly
        loadTexture(filename: "Earth512x256.jpg")

        //Earth-model
        glUniformMatrix4fv(self.myObjMatrix, 1, GLboolean(GLenum(GL_FALSE)), transMatrxiToArray(m: modelMatrix))
        //Earth-view
        glUniformMatrix4fv(self.myViewMatrix, 1, GLboolean(GLenum(GL_FALSE)), transMatrxiToArray(m: viewMatrix))
        //Earth-vertex
        glVertexAttribPointer(self.myVertexPositionAttribute, 3, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &sph);
        //Earth-textture
        glVertexAttribPointer(self.myVertexTextureAttribute, 2, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &sphIndex)
        //
        glVertexAttribPointer(self.myNormalVectorAttribute, 3, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &spNormal);
        //Color
        glUniform4f(self.myColorUniform, 1.0, 1.0, 1.0, 1.0)
        //only texture
        glUniform1i(self.myAxesFlag, 1);
        //Draw earth
        //earthLight =  GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-CofMX, -CofMY, -CofMZ), earthLight)
        glUniformMatrix4fv(self.myEarthLight, 1, GLboolean(GLenum(GL_FALSE)), transMatrxiToArray(m: earthLight))
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(sp.sphereNumVerts));
        
        glUniform1i(self.myAxesFlag, 1); //Light in fsh
        //Earth light+++++++++++++++++++++++++++++++++++++++++++++++
        //       glUniform1i(self.myObj_Flag, 3);
//        glVertexAttribPointer(self.myVertexPositionAttribute, 3, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &spNormal);
        
//        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(sp.sphereNormals.count/3));
        

        //Draw Moon
        glUniform1i(self.myObj_Flag, 2)//Set obj = obj2, Render obj1 seperatly
        glUniform1i(self.myAxesFlag, 1);
//        loadTexture(filename: "Moon256x128.jpg")
        loadTexture(filename: "newMoon.jpg")



       
        

        //End Animation
        
        glUniformMatrix4fv(self.myMoonMatrix, 1, GLboolean(GLenum(GL_FALSE)), transMatrxiToArray(m: MoonmodelMatrix))
        glUniformMatrix4fv(self.myViewMatrix, 1, GLboolean(GLenum(GL_FALSE)), transMatrxiToArray(m: viewMatrix))
        
        glVertexAttribPointer(self.myVertexPositionAttribute, 3, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &sph);
        glVertexAttribPointer(self.myNormalVectorAttribute, 3, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &spNormal);
        glUniform4f(self.myColorUniform, 1.0, 0.5, 0.5, 1.0)
        glUniform1i(self.myObj_Flag, 5);
        //moonLight = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-MoonX, -MoonY, -MoonZ), moonLight)
        glUniformMatrix4fv(self.myMoonLight, 1, GLboolean(GLenum(GL_FALSE)), transMatrxiToArray(m: moonLight))
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(sp.sphereNumVerts));

        //Moon light++++++++++++++++++++
        //glUniform1i(self.myAxesFlag, 1);
        
//        glUniform1i(self.myObj_Flag, 5);
//        glVertexAttribPointer(self.myVertexPositionAttribute, 3, GLenum(GL_FLOAT), GLboolean(GLenum(GL_FALSE)), 0, &spNormal);
//        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(sp.sphereNormals.count/3));
        
        update()
        ////////////////////////////////////
        if isAxes {
            glUniform1i(self.myAxesFlag, 4);
            glUniform1i(self.myObj_Flag, 4)
            
            glVertexAttribPointer(
                self.myVertexPositionAttribute,
                3,
                GLenum(GL_FLOAT),
                GLboolean(GLenum(GL_FALSE)),
                0,
                &gAxesData)
            
            
            
            glLineWidth(1.0)
            
            
            // lab12 SAMPLE SOLUTION:
            
            // draw coordinate system axes
            
            // what color to use for the line strip:
            glUniform4f(self.myColorUniform,
                        gColorData[0][0],
                        gColorData[0][1],
                        gColorData[0][2],
                        gColorData[0][3])
            glDrawArrays( GLenum(GL_LINES), 0, 42 )
            
            // what color to use for the line strip:
            glUniform4f(self.myColorUniform,
                        gColorData[1][0],
                        gColorData[1][1],
                        gColorData[1][2],
                        gColorData[1][3])
            glDrawArrays( GLenum(GL_LINES), 42, 42 )
            
            // what color to use for the line strip:
            glUniform4f(self.myColorUniform,
                        gColorData[2][0],
                        gColorData[2][1],
                        gColorData[2][2],
                        gColorData[2][3])
            glDrawArrays( GLenum(GL_LINES), 84, 42 )
        }
        

        ////////////////////////////////////////////////
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

            // the position where the finger currently touches the screen:
            self.myTouchXcurrent = self.myTouchXbegin
            self.myTouchYcurrent = self.myTouchYbegin

            // the last known position of the finger touching the screen,
            //   at redraw, or at new (first) touch event,
            //   it's the same as the current position:
            self.myTouchXold = self.myTouchXcurrent
            self.myTouchYold = self.myTouchYcurrent

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

            // store "current" to "old" touch coordinates
            self.myTouchXold = self.myTouchXcurrent
            self.myTouchYold = self.myTouchYcurrent

            // get new "current" touch coordinates
            self.myTouchXcurrent = GLfloat(firstTouchPoint.x)
            self.myTouchYcurrent = GLfloat(self.myViewPortHeight) - GLfloat(firstTouchPoint.y - 1)

            // we are in the "something has moved" phase of the touch event sequence:
            self.myTouchPhase = UITouchPhase.moved

            // lab12 SAMPLE SOLUTION - compute new position for camera:
            switch transFlag {
            //Rot
            case 1:
                if obj_number == 1 {
                    let dx = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                    let dy = (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
                    let rot = buildRotation(dx: GLfloat(dx), dy: GLfloat(dy))
                    modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-CofMX, -CofMY, -CofMZ), modelMatrix)
                    modelMatrix = GLKMatrix4Multiply(rot, modelMatrix)
                    modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(CofMX, CofMY, CofMZ), modelMatrix)
                    
                } else if obj_number == 2 {
                    let dx = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                    let dy = (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
                    let rot = buildRotation(dx: GLfloat(dx), dy: GLfloat(dy))
                    MoonmodelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-v4.x, -v4.y, -v4.z), MoonmodelMatrix)

                    MoonmodelMatrix = GLKMatrix4Multiply(rot, MoonmodelMatrix)

                    MoonmodelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(v4.x, v4.y, v4.z), MoonmodelMatrix)
                    
                } else {
                    RotationDx = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                    RotationDy = (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
                    viewMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-CamX, -CamY, -CamZ), viewMatrix)
                    viewMatrix = GLKMatrix4Multiply(buildRotation(dx: GLfloat(-RotationDx), dy: GLfloat(-RotationDy)), viewMatrix)
                    viewMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(CamX, CamY, CamZ), viewMatrix)
                    
                   
                }
            //T-xy
            case 2:
                if obj_number == 1 {
                    self.objTx = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                    self.objTy = (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
                    CofMX += objTx
                    CofMY += objTy
                    modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(objTx, objTy, 0.0), modelMatrix)
                    
                } else if obj_number == 2 {
                    self.objTx = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                    self.objTy = (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
                    MoonX += objTx
                    MoonY += objTy
                    MoonmodelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(objTx, objTy, 0.0), MoonmodelMatrix)
                    
                } else {
                    self.myTx = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                    self.myTy = (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
                    CamX += myTx
                    CamY += myTy
                    viewMatrix = GLKMatrix4Multiply(
                        GLKMatrix4MakeTranslation(myTx, myTy, 0.0), viewMatrix)

                }
            //T-xz
            case 3:
                if obj_number == 1 {
                    self.objTx = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                    self.objTz = (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
                    CofMX += objTx
                    CofMZ += objTz
                    modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(objTx, 0.0, objTz), modelMatrix)

                } else if obj_number == 2 {
                    self.objTx = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                    self.objTz = (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
                    MoonX += objTx
                    MoonZ += objTz
                    MoonmodelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(objTx, 0.0, objTz), MoonmodelMatrix)
                    
                } else {
                    self.myTx = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                    self.myTz = (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
                    CamX += myTx
                    CamZ += myTz
                    viewMatrix = GLKMatrix4Multiply(
                        GLKMatrix4MakeTranslation(myTx, 0.0, myTz), viewMatrix)
                    
                    
                }
                
            //Scale
            case 4:
                let scale = (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                if obj_number == 1 {
                    if scale != 0 {
                        modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-CofMX, -CofMY, -CofMZ), modelMatrix)
                        modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(1.0 + scale, 1.0 + scale, 1.0 + scale), modelMatrix)
                        modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(CofMX, CofMY, CofMZ), modelMatrix)
                    }
                } else if obj_number == 2 {
                    if scale != 0 {
//                        v4 = GLKMatrix4MultiplyVector4(MoonmodelMatrix, GLKVector4Make(0.0, 0.0, 0.0, 1.0))
//                        print("The moon is at \(v4.x), \(v4.y), \(v4.z)")
////                        MoonX = v4.x
////                        MoonY = v4.y
////                        MoonZ = v4.z
////                        print("The moon is at \(MoonX), \(MoonY), \(MoonZ)")
////                        MoonmodelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-MoonX, -MoonY, -MoonZ), MoonmodelMatrix)
                        MoonmodelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-v4.x, -v4.y, -v4.z), MoonmodelMatrix)
                        MoonmodelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(1.0 + scale, 1.0 + scale, 1.0 + scale), MoonmodelMatrix)
                        MoonmodelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(v4.x, v4.y, v4.z), MoonmodelMatrix)

//                        MoonmodelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(MoonX, MoonY, MoonZ), MoonmodelMatrix)
                    }
                } else {
                    self.mySx += scale
                    self.mySy += scale
                    self.mySz += scale
                    if scale != 0 {
                        viewMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-CamX, -CamY, -CamZ), viewMatrix)
                        viewMatrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(1.0 + scale, 1.0 + scale, 1.0 + scale), viewMatrix)
                        viewMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(CamX, CamY, CamZ), viewMatrix)
                    }
                   
                }
                
            default:
                self.myTx += (self.myTouchXcurrent - self.myTouchXold) * touchSpeed
                self.myTy += (self.myTouchYcurrent - self.myTouchYold) * touchSpeed
            }

            NSLog(lMessage)
        }
    } // end of touchesMoved()



    // ------------------------------------------------------------------------
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first  {
            let firstTouchPoint = firstTouch.location(in: self.view)
            let lMessage = "Touches Ended at \(firstTouchPoint.x), \(firstTouchPoint.y)"

            // detected end of touch event sequence (finger lifted from surface)
            // NOTE: depending on the desired behavior for user interaction,
            //    here you may need to instead set both current and old points
            //    to the last detected coordinates:
            self.myTouchXold = self.myTouchXcurrent
            self.myTouchYold = self.myTouchYcurrent

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
        self.myGLESProgram = glCreateProgram()

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
        glAttachShader(self.myGLESProgram, vertShader)

        // Attach fragment shader object code to GPU program:
        glAttachShader(self.myGLESProgram, fragShader)

        // Link GPU program:
        if !self.linkProgram(self.myGLESProgram) {
            NSLog("Failed to link program: \(self.myGLESProgram)")
            // if linking fails, dispose of anything we got so far:
            if vertShader != 0 {
                glDeleteShader(vertShader)
                vertShader = 0
            }
            if fragShader != 0 {
                glDeleteShader(fragShader)
                fragShader = 0
            }
            if self.myGLESProgram != 0 {
                glDeleteProgram(self.myGLESProgram)
                self.myGLESProgram = 0
            }
            return false
        }

        // Release vertex and fragment shaders.
        if vertShader != 0 {
            glDetachShader(self.myGLESProgram, vertShader)
            glDeleteShader(vertShader)
        }
        if fragShader != 0 {
            glDetachShader(self.myGLESProgram, fragShader)
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

