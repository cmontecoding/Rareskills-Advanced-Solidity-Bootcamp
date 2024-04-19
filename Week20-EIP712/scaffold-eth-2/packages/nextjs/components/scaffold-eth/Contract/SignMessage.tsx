import { useState } from "react";
import { ReadOnlyFunctionForm } from "./ReadOnlyFunctionForm";
import { Abi, AbiFunction } from "abitype";
import { useSignMessage } from "wagmi";
import { Bytes32Input } from "~~/components/scaffold-eth";
import { Contract, ContractName, GenericContract, InheritedFunctions } from "~~/utils/scaffold-eth/contract";

export const SignMessage = () => {
  const [message, setMessage] = useState<string>("");
  // const { data: signMessageData, error, isLoading, signMessage, variables } = useSignMessage();
  const { signMessage } = useSignMessage();

  return (
    <>
      <div className="flex flex-col gap-3 py-5 first:pt-0 last:pb-1">
        <Bytes32Input
          value={message}
          onChange={setMessage}
          name={"Message to sign"}
          placeholder={"Message to sign"}
          disabled={false}
        />

        <div className="flex justify-between gap-2 flex-wrap">
          <button
            className="btn btn-secondary btn-sm"
            onClick={async () => {
              console.log("clicked");
              signMessage({ message });
              // signMessage({ message: messageToSign });
              // const { data } = await refetch();
              // setResult(data);
            }}
            // disabled={isFetching}
          >
            {/* {isFetching && <span className="loading loading-spinner loading-xs"></span>} */}
            Sign Message
          </button>
        </div>
      </div>
    </>
  );
};