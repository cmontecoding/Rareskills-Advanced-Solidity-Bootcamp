import { useEffect, useState } from "react";
import { useAccount, usePublicClient, useSignTypedData } from "wagmi";
import { Bytes32Input, IntegerInput } from "~~/components/scaffold-eth";
import { Contract, ContractName } from "~~/utils/scaffold-eth/contract";

const splitSig = (sig?: string) => {
  if (!sig) return null;
  // splits the signature to r, s, and v values.
  const pureSig = sig.replace("0x", "");

  const r = new Buffer(pureSig.substring(0, 64), "hex");
  const s = new Buffer(pureSig.substring(64, 128), "hex");
  const v = new Buffer(parseInt(pureSig.substring(128, 130), 16).toString());

  return {
    r,
    s,
    v,
  };
};

export const SignTypedMessage = ({ deployedContractData }: { deployedContractData: Contract<ContractName> }) => {
  const [owner, setOwner] = useState<string>("");
  const [spender, setSpender] = useState<string>("");
  const [value, setValue] = useState<bigint | string>("");
  const [nonce, setNonce] = useState<bigint | string>("");

  const [block, setBlock] = useState();
  const [deadline, setDeadline] = useState<bigint | string>(block?.timestamp);
  const publicClient = usePublicClient();

  useEffect(() => {
    publicClient
      .getBlock() // https://viem.sh/docs/actions/public/getBlock.html
      .then(x => setBlock(x))
      .catch(error => console.log(error));
  }, [publicClient]);

  const { signTypedData, data } = useSignTypedData();
  const account = useAccount();
  const permit = splitSig(data);

  return (
    <>
      <div className="flex flex-col gap-3 py-5 first:pt-0 last:pb-1">
        <p>You account: {account.address}</p>
        <p>Block Timestamp: {block?.timestamp.toString()}</p>
        <Bytes32Input value={owner} onChange={setOwner} name={"Owner"} placeholder={"Owner"} disabled={false} />
        <Bytes32Input value={spender} onChange={setSpender} name={"Spender"} placeholder={"Spender"} disabled={false} />
        <IntegerInput value={value} onChange={setValue} name={"Value"} placeholder={"Value"} disabled={false} />
        <IntegerInput value={nonce} onChange={setNonce} name={"Nonce"} placeholder={"Nonce"} disabled={false} />
        <IntegerInput
          value={deadline}
          onChange={setDeadline}
          name={"Deadline"}
          placeholder={"Deadline"}
          disabled={false}
        />
        {permit ? (
          <>
            <p>Owner: {owner}</p>
            <p>spender: {spender}</p>
            <p>v: {permit.v.toString()}</p>
            <p>r: {`0x${permit.r.toString("hex")}`}</p>
            <p>s: {`0x${permit.s.toString("hex")}`}</p>
          </>
        ) : null}
        <div className="flex justify-between gap-2 flex-wrap">
          <button
            className="btn btn-secondary btn-sm"
            onClick={async () => {
              console.log("clicked");
              signTypedData({
                domain: {
                  name: "MyToken",
                  chainId: 31337,
                  verifyingContract: deployedContractData.address,
                  version: "1",
                },
                types: {
                  Permit: [
                    { name: "owner", type: "address" },
                    { name: "spender", type: "address" },
                    { name: "value", type: "uint256" },
                    { name: "nonce", type: "uint256" },
                    { name: "deadline", type: "uint256" },
                  ],
                },
                primaryType: "Permit",
                message: {
                  owner,
                  spender,
                  value,
                  nonce,
                  deadline,
                },
              });
            }}
          >
            Sign ERC20 Permit
          </button>
        </div>
      </div>
    </>
  );
};