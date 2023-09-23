import {vec3,vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially

  'Base shape - amplitude': 0.5,
  'Base shape - freq': 2.0,
  'FBM - amplitude': 0.2,
  'FBM - one over persistence': 8,
  'FBM - freq': 16,
  'FBM - octaves': 8,

  'Color offset': 0.0,

  'Bloom - threshold': 0.9,
  'Bloom - intensity': 1.0,

  'Reset': reset
  //color: [255, 0, 0, 255],
};

let core: Icosphere;
let fire: Icosphere;
let square: Square;
let prevTesselations: number = 5;
let time: number = 0;

function loadScene() {
  core = new Icosphere(vec3.fromValues(0, 0, 0), 1.0, controls.tesselations);
  core.create();
  fire = new Icosphere(vec3.fromValues(0, 0, 0), 1.2, controls.tesselations);
  fire.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
}

function reset() {
  controls['Base shape - amplitude'] = 0.5;
  controls['Base shape - freq'] = 2.0;
  controls['FBM - amplitude'] = 0.2;
  controls['FBM - one over persistence'] = 8;
  controls['FBM - freq'] = 16;
  controls['FBM - octaves'] = 8;

  controls['Color offset'] = 0;
  controls['Bloom - threshold'] = 0.9;
  controls['Bloom - intensity'] = 1.0;
}

function setCustomParam(prog: ShaderProgram) {
  prog.setShapeAmp(controls['Base shape - amplitude']);
  prog.setShapeFreq(controls['Base shape - freq']);
  prog.setFBMAmp(controls['FBM - amplitude']);
  prog.setFBMFreq(controls['FBM - freq']);
  prog.setFBMOneOverPersistence(controls['FBM - one over persistence']);
  prog.setFBMOctave(controls['FBM - octaves']);

  prog.setColorOffset(controls['Color offset']);
  prog.setBloomThreshold(controls['Bloom - threshold']);
  prog.setBloomIntensity(controls['Bloom - intensity']);
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // let audio = new Audio('./theme.mp3');
  // //audio.load();
  // audio.play();

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'Base shape - amplitude', 0.4, 0.6).step(0.02).listen();
  gui.add(controls, 'Base shape - freq', 1.0, 3.0).step(0.2).listen();
  gui.add(controls, 'FBM - amplitude', 0.1, 1.0).step(0.1).listen();
  gui.add(controls, 'FBM - one over persistence', 2, 16).step(2).listen(); 
  gui.add(controls, 'FBM - freq', 8, 24).step(2).listen();
  gui.add(controls, 'FBM - octaves', 1, 16).step(1).listen();

  gui.add(controls, 'Color offset', -1.0, 1.0).step(0.2).listen();

  gui.add(controls, 'Bloom - threshold', 0.6, 1.0).step(0.1).listen();
  gui.add(controls, 'Bloom - intensity', 0.5, 1.5).step(0.1).listen();

  gui.add(controls, "Reset");

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  const custom = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/core-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/core-frag.glsl')),
  ]);

  const fire_prog = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fire-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fire-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      core = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      core.create();

      fire = new Icosphere(vec3.fromValues(0, 0, 0), 1.2, prevTesselations);
      fire.create();
    }

    setCustomParam(flat);

    // background
    gl.disable(gl.DEPTH_TEST);
    renderer.render(camera, flat, [
      square,
    ], time);
    gl.enable(gl.DEPTH_TEST);

    setCustomParam(custom);
    gl.disable(gl.BLEND);
    renderer.render(camera, custom, [
      core,
    ], time);
    stats.end();

    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.enable(gl.BLEND);

    gl.cullFace(gl.BACK);
    gl.enable(gl.CULL_FACE);

    // renderer.render(camera, fire_prog, [
    //   fire,
    // ], controls.color, time);
    // stats.end();

    gl.disable(gl.CULL_FACE);

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
    ++time;
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
