/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IVerifierFactory,
  IVerifierFactoryInterface,
} from "../../../contracts/src/IVerifierFactory";

const _abi = [
  {
    inputs: [
      {
        internalType: "ICustomVerifier.Hash",
        name: "_modelContentId",
        type: "bytes32",
      },
      {
        internalType: "string",
        name: "_modelName",
        type: "string",
      },
      {
        internalType: "string",
        name: "_modelDescription",
        type: "string",
      },
    ],
    name: "createChildContract",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "ICustomVerifier.Hash",
        name: "_modelContentId",
        type: "bytes32",
      },
    ],
    name: "getClonedVerifierContract",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getMasterVerifierContract",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint32",
        name: "_offset",
        type: "uint32",
      },
      {
        internalType: "uint32",
        name: "_limit",
        type: "uint32",
      },
    ],
    name: "getModels",
    outputs: [
      {
        components: [
          {
            internalType: "ICustomVerifier.Hash",
            name: "contentId",
            type: "bytes32",
          },
          {
            internalType: "string",
            name: "name",
            type: "string",
          },
          {
            internalType: "address",
            name: "contractAddress",
            type: "address",
          },
        ],
        internalType: "struct IVerifierFactory.ModelArrayElement[]",
        name: "",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_ownerAddress",
        type: "address",
      },
      {
        internalType: "uint32",
        name: "_offset",
        type: "uint32",
      },
      {
        internalType: "uint32",
        name: "_limit",
        type: "uint32",
      },
    ],
    name: "getModelsByOwnerAddress",
    outputs: [
      {
        components: [
          {
            internalType: "ICustomVerifier.Hash",
            name: "contentId",
            type: "bytes32",
          },
          {
            internalType: "string",
            name: "name",
            type: "string",
          },
          {
            internalType: "address",
            name: "contractAddress",
            type: "address",
          },
        ],
        internalType: "struct IVerifierFactory.ModelArrayElement[]",
        name: "",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class IVerifierFactory__factory {
  static readonly abi = _abi;
  static createInterface(): IVerifierFactoryInterface {
    return new utils.Interface(_abi) as IVerifierFactoryInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IVerifierFactory {
    return new Contract(address, _abi, signerOrProvider) as IVerifierFactory;
  }
}
