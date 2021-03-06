/* Copyright (c) 2018 PaddlePaddle Authors. All Rights Reserved.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */

import Foundation

class SplitParam<P: PrecisionType>: OpParam {
  typealias ParamPrecisionType = P
  required init(opDesc: OpDesc, inScope: Scope) throws {
    do {
      input = try SplitParam.inputX(inputs: opDesc.inputs, from: inScope)
      output = Texture<P>.init(device: input.metalTexture!.device, inDim: input.dim)
      axis = try SplitParam.getAttr(key: "axis", attrs: opDesc.attrs)
      sections = try SplitParam.getAttr(key: "sections", attrs: opDesc.attrs)
      if axis < 0 {
        axis = input.tensorDim.cout() + axis
      }
      guard let outlist = opDesc.outputs["Out"] else {
        fatalError()
      }
      for out in outlist {
        guard let variant = inScope[out], let v = variant as? Texture<P> else {
          fatalError()
        }
        outputList.append(v)
        sections.append(Int32(v.tensorDim.dims[axis]))
      }
    } catch let error {
      throw error
    }
  }
  
  var axis: Int
  let input: Texture<P>
  var output: Texture<P>
  var outputList: [Texture<P>] = []
  var sections: [Int32] = []
}

class SplitOp<P: PrecisionType>: Operator<SplitKernel<P>, SplitParam<P>>, Runable, Creator, InferShaperable{
  
  typealias OpType = SplitOp<P>

  func inferShape() {
    //        para.output.dim = para.input.dim
  }
  
  func runImpl(device: MTLDevice, buffer: MTLCommandBuffer) throws {
    do {
      try kernel.compute(commandBuffer: buffer, param: para)
    } catch let error {
      throw error
    }
  }
  
  func delogOutput() {
    print(" \(type) output: ")
    let device = para.input.metalTexture!.device
    for out in para.outputList {
      let arr: [Float32] = device.texture2tensor(texture: out.metalTexture, dim: out.tensorDim.dims, transpose: out.transpose)
      print(arr.strideArray())
    }
  }
  
}






