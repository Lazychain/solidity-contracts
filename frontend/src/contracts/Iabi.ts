export interface AbiItem {
  type: string;
  name?: string;
  inputs?: {
    name: string;
    type: string;
    internalType: string;
    indexed?: boolean;
  }[];
  outputs?: {
    name: string;
    type: string;
    internalType: string;
  }[];
  stateMutability?: string;
  anonymous?: boolean;
}
