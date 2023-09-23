import {vec2, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifColor: WebGLUniformLocation;
  unifTime : WebGLUniformLocation;
  unifDimension : WebGLUniformLocation;

  unifShapeAmp : WebGLUniformLocation;
  unifShapeFreq : WebGLUniformLocation;
  unifFBMAmp : WebGLUniformLocation;
  unifFBMFreq : WebGLUniformLocation;
  unifFBMOneOverPersistence : WebGLUniformLocation;
  unifFBMOctaves : WebGLUniformLocation;
  unifColorOffset : WebGLUniformLocation;
  unifBloomThreshold : WebGLUniformLocation;
  unifBloomIntensity : WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifColor      = gl.getUniformLocation(this.prog, "u_Color");
    this.unifTime       = gl.getUniformLocation(this.prog, "u_Time");
    this.unifDimension  = gl.getUniformLocation(this.prog, "u_Dimensions");

    this.unifShapeAmp   = gl.getUniformLocation(this.prog, "u_ShapeAmp");
    this.unifShapeFreq  = gl.getUniformLocation(this.prog, "u_ShapeFreq");
    this.unifFBMAmp     = gl.getUniformLocation(this.prog, "u_FBMAmp");
    this.unifFBMFreq    = gl.getUniformLocation(this.prog, "u_FBMFreq");
    this.unifFBMOneOverPersistence = gl.getUniformLocation(this.prog, "u_FBMOneOverPersistence");
    this.unifFBMOctaves = gl.getUniformLocation(this.prog, "u_FBMOctaves");
    this.unifColorOffset     = gl.getUniformLocation(this.prog, "u_ColorOffset");
    this.unifBloomThreshold  = gl.getUniformLocation(this.prog, "u_BloomThres");
    this.unifBloomIntensity  = gl.getUniformLocation(this.prog, "u_BloomIntensity");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setGeometryColor(color: vec4) {
    this.use();
    if (this.unifColor !== -1) {
      gl.uniform4fv(this.unifColor, color);
    }
  }

  setTime(time: number) {
    this.use();
    if (this.unifTime !== -1) {
      gl.uniform1i(this.unifTime, time);
    }
  }

  setDimension(dimension : vec2) {
    this.use();
    if (this.unifDimension != -1) {
      gl.uniform2fv(this.unifDimension, dimension);
    }
  }

  setShapeAmp(shapeAmp : number) {
    this.use();
    if (this.unifShapeAmp != -1) {
      gl.uniform1f(this.unifShapeAmp, shapeAmp);
    }
  }

  setShapeFreq(shapeFreq : number) {
    this.use();
    if (this.unifShapeFreq != -1) {
      gl.uniform1f(this.unifShapeFreq, shapeFreq);
    }
  }

  setFBMAmp(fbmAmp : number) {
    this.use();
    if (this.unifFBMAmp != -1) {
      gl.uniform1f(this.unifFBMAmp, fbmAmp);
    }
  }

  setFBMFreq(fbmFreq : number) {
    this.use();
    if (this.unifFBMFreq != -1) {
      gl.uniform1f(this.unifFBMFreq, fbmFreq);
    }
  }

  setFBMOneOverPersistence(oneOverPersistence : number) {
    this.use();
    if (this.unifFBMOneOverPersistence != -1) {
      gl.uniform1i(this.unifFBMOneOverPersistence, oneOverPersistence);
    }
  }

  setFBMOctave(fbmOctaves : number) {
    this.use();
    if (this.unifFBMOctaves != -1) {
      gl.uniform1i(this.unifFBMOctaves, fbmOctaves);
    }
  }

  setColorOffset(colorOffset : number) {
    this.use();
    if (this.unifColorOffset != -1) {
      gl.uniform1f(this.unifColorOffset, colorOffset);
    }
  }

  setBloomThreshold(bloomThreshold : number) {
    this.use();
    if (this.unifBloomThreshold != -1) {
      gl.uniform1f(this.unifBloomThreshold, bloomThreshold);
    }
  }

  setBloomIntensity(bloomIntensity : number) {
    this.use();
    if (this.unifBloomIntensity != -1) {
      gl.uniform1f(this.unifBloomIntensity, bloomIntensity);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
  }
};

export default ShaderProgram;
